# OpenClaw 初始化

> 版本: v2 | 2026-06-17 初版 / 2026-06-22 重构

在 VM 上跑（通过 SSH）：
```bash
ssh wwh@yidao.picp.net -p 10022
bash ~/second-brain/docs/02_OpenClaw初始化.sh
```

---

## 核心配置逻辑

### 环境变量（所有脚本共享）

```bash
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export GIT_TERMINAL_PROMPT=0
```

### SSH + Deploy Key（git 读写认证）

```bash
# 1. 生成 deploy key
ssh-keygen -t ed25519 -N '' -f ~/.ssh/github_deploy_key -C ai-agent-vm-second-brain

# 2. 把 ~/.ssh/github_deploy_key.pub 加到 GitHub 仓库 Settings → Deploy Keys（勾 Allow write access）

# 3. 配 ~/.ssh/config 让 git 强制走 deploy key
cat >> ~/.ssh/config << 'EOF'
Host github.com
  IdentityFile ~/.ssh/github_deploy_key
  IdentitiesOnly yes
  User git
EOF
chmod 600 ~/.ssh/config
```

### git 全局配置

```bash
git config --global i18n.commitEncoding utf-8
git config --global i18n.logOutputEncoding utf-8
git config --global core.quotepath false
```

### git 用户（耗子助手身份提交）

```bash
git config user.name "耗子助手"
git config user.email "openclaw@wwh.local"
```

---

## 一键初始化完整脚本

在 VM 上运行以下命令，或下载 `02_OpenClaw初始化.sh` 到 VM 后 `bash` 执行：

```bash
#!/bin/bash
# 第二大脑 - OpenClaw 端初始化脚本 v2
# VM 上运行：bash ~/second-brain/docs/02_OpenClaw初始化.sh

export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export GIT_TERMINAL_PROMPT=0
set -euo pipefail

REPO_DIR="$HOME/second-brain"
REPO_URL="git@github.com:WWH3602/second-brain.git"

echo "=========================================="
echo "  第二大脑 - OpenClaw 端初始化 v2"
echo "  仓库: $REPO_DIR"
echo "=========================================="

# 1. 检查 git / SSH key
command -v git >/dev/null 2>&1 || { echo "[错误] git 未安装"; exit 1; }
[ ! -f "$HOME/.ssh/github_deploy_key" ] && { echo "[错误] 没找到 ~/.ssh/github_deploy_key，请先生成"; exit 1; }

# 2. SSH config
mkdir -p "$HOME/.ssh"; chmod 700 "$HOME/.ssh"
cat > "$HOME/.ssh/config" << 'SSHCFG'
Host github.com
  IdentityFile ~/.ssh/github_deploy_key
  IdentitiesOnly yes
  User git
SSHCFG
chmod 600 "$HOME/.ssh/config"

# 3. git i18n + 用户
git config --global i18n.commitEncoding utf-8
git config --global i18n.logOutputEncoding utf-8
git config --global core.quotepath false

# 4. clone / 更新仓库
if [ -d "$REPO_DIR" ]; then
  cd "$REPO_DIR"
  git remote set-url origin "$REPO_URL"
else
  git clone "$REPO_URL" "$REPO_DIR"
  cd "$REPO_DIR"
fi
git pull origin main

# 5. git 用户
git config user.name "耗子助手"
git config user.email "openclaw@wwh.local"

# 6. 创建目录
mkdir -p "$REPO_DIR/00-Inbox"
mkdir -p "$HOME/.openclaw/hooks/second-brain"

# 7. hook 共享库（所有 hook source 这个）
cat > "$HOME/.openclaw/hooks/second-brain/00_lib.sh" << 'EOF'
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export GIT_TERMINAL_PROMPT=0
export REPO_DIR="${REPO_DIR:-$HOME/second-brain}"
sb_git_commit_push() {
  local file_path="$1"; local commit_msg="$2"
  cd "$REPO_DIR" || exit 1
  git add "$file_path" || exit 1
  git commit --cleanup=verbatim -m "$commit_msg" || true
  git push origin main || { echo "[错误] push 失败"; exit 1; }
}
EOF
chmod +x "$HOME/.openclaw/hooks/second-brain/00_lib.sh"

# 8. 四个 hook 脚本
# 01_save_note.sh - 写收件箱（已废弃，改用 MCP server）
# 02_organize_inbox.sh - 整理收件箱（已废弃）
# 03_setup_list.sh - 装机清单（已废弃）
# 04_auto_pull.sh - 定时 pull（保留）
cat > "$HOME/.openclaw/hooks/second-brain/04_auto_pull.sh" << 'EOF'
#!/bin/bash
source "$(dirname "$0")/00_lib.sh"
cd "$REPO_DIR" || exit 1
git pull origin main --rebase --autostash 2>&1 | tail -3
EOF
chmod +x "$HOME/.openclaw/hooks/second-brain/04_auto_pull.sh"

# 9. cron 定时 pull（每 30 分钟）
CRON_LINE="*/30 * * * * /home/wwh/.openclaw/hooks/second-brain/04_auto_pull.sh >> /home/wwh/second-brain-pull.log 2>&1"
(crontab -l 2>/dev/null | grep -v "04_auto_pull.sh" || true; echo "$CRON_LINE") | crontab -

echo "✅ 初始化完成"
echo "  仓库: $REPO_DIR"
echo "  定时 pull: 每 30 分钟"
```

---

## MCP Server 部署（替代 shell hook，当前主力方案）

### 启动方式

```bash
# 手动启动（调试用）
cd /home/wwh/.openclaw
source ~/.openclaw/mcp-env/bin/activate
python3 second_brain_mcp_server.py &

# 推荐：后台启动
nohup python3 -m mcp_venv/bin/python second_brain_mcp_server.py > /home/wwh/mcp_server.log 2>&1 & disown
```

### MCP Server 源码位置

```
/home/wwh/.openclaw/second_brain_mcp_server.py
```

### 调用链路（重要）

```
QQ 消息 → OpenClaw qqbot → AI 识别"记：xxx"
  → 调 save_to_second_brain() MCP 工具
  → second_brain_mcp_server.py 内部执行 git pull/add/commit/push
  → 响应用户（包含 commit hash）
```

**注意**：QQ bot **不走** shell hook（`~/.openclaw/hooks/second-brain/` 下的 `.sh` 脚本），走的是 MCP server（stdio 子进程）。

---

## 三端通讯链路

```
┌─────────┐   QQ聊天    ┌──────────┐   Git SSH    ┌──────────┐
│ 手机iOS  │ ────────→  │ OpenClaw │ ──────────→ │ GitHub   │
└─────────┘            │ (耗子助手)│              │ 私有仓库  │
                       └──────────┘ ←───────────  └──────────┘
                                              ↑ git clone/pull
                                              │
                                        ┌──────────┐
                                        │  你的电脑  │
                                        └──────────┘
```

| 路径 | 方式 | 状态 |
|------|------|------|
| 手机 → VM | iOS QQ 消息 → qqbot → MCP | ✅ 主力 |
| 电脑 → VM | `http://127.0.0.1:18789/`（SSH 隧道 10022）| ✅ |
| AI 写 VM 文件 | write 工具 → workspace 软链 | ✅ |
| VM → 电脑 | 定时 git pull | ✅ |
