#!/bin/bash
# 第二大脑 - OpenClaw 端初始化脚本 v2
# 在 VM 上跑：ssh wwh@yidao.picp.net -p 10022，然后 bash ~/03_OpenClaw_初始化.sh
# v2: 改用 SSH+Deploy Key（VM 上 GnuTLS 不稳），增加 LANG=i18n 共享库

# 关键：让所有子脚本都能处理中文
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export GIT_TERMINAL_PROMPT=0

set -euo pipefail

REPO_DIR="$HOME/second-brain"
REPO_URL="git@github.com:WWH3602/second-brain.git"

echo "============================================================"
echo "  第二大脑 - OpenClaw 端初始化 v2"
echo "  仓库: $REPO_DIR"
echo "============================================================"
echo

# 1. 检查 git
if ! command -v git >/dev/null 2>&1; then
  echo "[错误] git 未安装"
  exit 1
fi

# 2. 检查 SSH key
if [ ! -f "$HOME/.ssh/github_deploy_key" ]; then
  echo "[错误] 没找到 ~/.ssh/github_deploy_key"
  echo "       请先跑：ssh-keygen -t ed25519 -N '' -f ~/.ssh/github_deploy_key -C ai-agent-vm-second-brain"
  echo "       然后把 ~/.ssh/github_deploy_key.pub 加到 GitHub 仓库的 Deploy Keys（勾 Allow write access）"
  exit 1
fi

# 3. 配 ~/.ssh/config 让 git 走 deploy key
mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"
cat > "$HOME/.ssh/config" << 'SSHCFG'
Host github.com
  IdentityFile ~/.ssh/github_deploy_key
  IdentitiesOnly yes
  User git
SSHCFG
chmod 600 "$HOME/.ssh/config"
echo "[1/7] SSH config 已配（强制走 deploy key）"

# 4. 配 git 全局 i18n encoding
git config --global i18n.commitEncoding utf-8
git config --global i18n.logOutputEncoding utf-8
git config --global core.quotepath false
echo "  [OK] i18n.commitEncoding=utf-8 (中文 commit message 正常)"

# 5. clone 仓库
echo
echo "[2/7] git clone ..."
if [ -d "$REPO_DIR" ]; then
  echo "  [跳过] $REPO_DIR 已存在"
  cd "$REPO_DIR"
  git remote set-url origin "$REPO_URL"
else
  git clone "$REPO_URL" "$REPO_DIR"
  cd "$REPO_DIR"
fi

# 6. 配置 git 用户
git config user.name "耗子助手"
git config user.email "openclaw@wwh.local"
echo "[3/7] git 用户：耗子助手 <openclaw@wwh.local>"

# 7. 测试 pull
echo
echo "[4/7] 测试 git pull ..."
git pull origin main

# 8. 创建工作目录
echo
echo "[5/7] 创建工作目录 ..."
mkdir -p "$REPO_DIR/00-Inbox"
mkdir -p "$HOME/.openclaw/hooks/second-brain"

# 9. 写共享库：00_lib.sh（所有 hook 共享：LANG+i18n）
cat > "$HOME/.openclaw/hooks/second-brain/00_lib.sh" << 'EOF'
# 第二大脑 hook 共享库：所有 hook 都 source 这一个
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export GIT_TERMINAL_PROMPT=0
export REPO_DIR="${REPO_DIR:-$HOME/second-brain}"
export HOOKS_DIR="${HOOKS_DIR:-$HOME/.openclaw/hooks/second-brain}"

# git add/commit/push 封装：失败时报错退出
sb_git_commit_push() {
  local file_path="$1"
  local commit_msg="$2"
  cd "$REPO_DIR" || { echo "[错误] 切不到 $REPO_DIR"; exit 1; }
  git add "$file_path" || { echo "[错误] git add 失败: $file_path"; exit 1; }
  # 注意：commit message 用 --cleanup=verbatim 保留中文不被处理
  if ! git commit --cleanup=verbatim -m "$commit_msg"; then
    echo "[警告] git commit 没东西可提交或失败（可能无变化）"
  fi
  if ! git push origin main; then
    echo "[错误] git push 失败（文件已在 $file_path，本地 commit 成功）"
    exit 1
  fi
}
EOF
chmod +x "$HOME/.openclaw/hooks/second-brain/00_lib.sh"
echo "  [OK] 00_lib.sh (共享库：LANG+i18n+git封装)"

# 10. 写 QQ hook 脚本：记笔记
cat > "$HOME/.openclaw/hooks/second-brain/01_save_note.sh" << 'EOF'
#!/bin/bash
# 收到 QQ 私聊消息 → 写入 00-Inbox
# 参数: $1 = 消息内容
source "$(dirname "$0")/00_lib.sh"
set -euo pipefail

NOTE="$1"
TIMESTAMP=$(date +%Y%m%d-%H%M)
# 中文文件名：用 python3 按字符截取（不是字节），保证 UTF-8 完整
SAFE_NAME=$(printf '%s' "$NOTE" | python3 -c "
import sys, re
s = sys.stdin.read()
s = re.sub(r'\s+', '_', s)
s = re.sub(r'[/\?*:|\"<>\\\\]', '', s)
s = s[:12]
print(s)
")
[ -z "$SAFE_NAME" ] && SAFE_NAME="note-${RANDOM}"
FILE="$REPO_DIR/00-Inbox/${TIMESTAMP}-${SAFE_NAME}.md"

cat > "$FILE" << NOTEEOF
# $(date '+%Y-%m-%d %H:%M')

> 来源: QQ 私聊 @ $(date '+%Y-%m-%d %H:%M:%S')

$NOTE

---
*由耗子助手自动记录，待 AI 整理*
NOTEEOF

# 注意：commit message 里用 ASCII 短描述（中文会变乱码是因为 SSH git 协议传输时 LANG 上下文丢失，文件内容本身是 UTF-8 OK）
COMMIT_MSG="note: ${TIMESTAMP}-${SAFE_NAME}"
sb_git_commit_push "00-Inbox/${TIMESTAMP}-${SAFE_NAME}.md" "$COMMIT_MSG"

echo "已记录到 $FILE 并推送到 GitHub"
EOF
chmod +x "$HOME/.openclaw/hooks/second-brain/01_save_note.sh"
echo "  [OK] 01_save_note.sh"

# 11. 写 QQ hook 脚本：整理收件箱
cat > "$HOME/.openclaw/hooks/second-brain/02_organize_inbox.sh" << 'EOF'
#!/bin/bash
# 整理 00-Inbox → 移动到对应分类
source "$(dirname "$0")/00_lib.sh"
set -euo pipefail

cd "$REPO_DIR"
git pull origin main
echo "当前收件箱内容："
ls -la 00-Inbox/
echo
echo "请用 AI 工具（Cursor/VSCode）配合'00-Inbox'目录内容手动整理"
echo "整理完后："
echo "  cd ~/second-brain && git add -A && git commit -m 'organize: inbox' && git push"
EOF
chmod +x "$HOME/.openclaw/hooks/second-brain/02_organize_inbox.sh"
echo "  [OK] 02_organize_inbox.sh"

# 12. 写 QQ hook 脚本：装机清单
cat > "$HOME/.openclaw/hooks/second-brain/03_setup_list.sh" << 'EOF'
#!/bin/bash
# 输出装机清单
source "$(dirname "$0")/00_lib.sh"
set -euo pipefail

FILE="$REPO_DIR/10-工具/10.1-电脑必备软件/README.md"
[ -f "$FILE" ] || git -C "$REPO_DIR" pull origin main
cat "$FILE"
EOF
chmod +x "$HOME/.openclaw/hooks/second-brain/03_setup_list.sh"
echo "  [OK] 03_setup_list.sh"

# 13. 写定时 pull 任务
echo
echo "[6/7] 写定时 pull 任务（每 30 分钟同步本地编辑）..."
cat > "$HOME/.openclaw/hooks/second-brain/04_auto_pull.sh" << 'EOF'
#!/bin/bash
source "$(dirname "$0")/00_lib.sh"
cd "$REPO_DIR" || exit 1
git pull origin main --rebase --autostash 2>&1 | tail -5
EOF
chmod +x "$HOME/.openclaw/hooks/second-brain/04_auto_pull.sh"

# 加 cron
CRON_LINE="*/30 * * * * /home/wwh/.openclaw/hooks/second-brain/04_auto_pull.sh >> /home/wwh/second-brain-pull.log 2>&1"
(crontab -l 2>/dev/null | grep -v "second-brain/04_auto_pull.sh" || true; echo "$CRON_LINE") | crontab -
echo "  [OK] 04_auto_pull.sh + cron 已配置"

# 14. 完成
echo
echo "[7/7] 完成！"
echo
echo "============================================================"
echo "  初始化成功 v2"
echo "============================================================"
echo
echo "已部署："
echo "  ✓ 仓库: $REPO_DIR (SSH+Deploy Key)"
echo "  ✓ Hook 共享库: ~/.openclaw/hooks/second-brain/00_lib.sh"
echo "  ✓ Hook 脚本: 01_save_note / 02_organize_inbox / 03_setup_list"
echo "  ✓ 定时任务: 每 30 分钟自动 pull (cron)"
echo
echo "下一步（要在 OpenClaw Web UI 里点）："
echo "  http://127.0.0.1:18789"
echo "  → Channels → QQ 机器人 → 添加 Hook"
echo "  → Trigger: 收到私聊消息时"
echo "  → Action: shell command: bash ~/.openclaw/hooks/second-brain/01_save_note.sh \"{message}\""
echo
echo "测试：bash ~/.openclaw/hooks/second-brain/01_save_note.sh '我的第一条笔记'"
echo
