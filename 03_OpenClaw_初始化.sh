#!/bin/bash
# 第二大脑 - OpenClaw 端初始化脚本
# 在 VM 上跑：ssh wwh@yidao.picp.net -p 10022，然后 bash ~/second-brain-init.sh

set -e

REPO_DIR="$HOME/second-brain"
REPO_URL_HTTPS="https://github.com/WWH3602/second-brain.git"

echo "============================================================"
echo "  第二大脑 - OpenClaw 端初始化"
echo "  仓库: $REPO_DIR"
echo "============================================================"
echo

# 1. 检查 git
if ! command -v git >/dev/null 2>&1; then
    echo "[错误] git 未安装"
    exit 1
fi

# 2. 读取 Token（从 02_凭据与安全.md，scp 先传过来）
#    或者手动 export GITHUB_TOKEN=...
if [ -z "$GITHUB_TOKEN" ]; then
    TOKEN_FILE="$HOME/02_凭据与安全.md"
    if [ -f "$TOKEN_FILE" ]; then
        export GITHUB_TOKEN=$(grep -oP 'GITHUB_TOKEN=\K[^\s]+' "$TOKEN_FILE" | head -1)
        echo "[1/7] 从 $TOKEN_FILE 读取 Token（前 10 位：${GITHUB_TOKEN:0:10}）"
    else
        echo "[错误] 未设置 GITHUB_TOKEN 环境变量"
        echo "        方法1: export GITHUB_TOKEN=github_pat_11APKHNJI0xxxx"
        echo "        方法2: 把本地 02_凭据与安全.md scp 到 ~/02_凭据与安全.md"
        exit 1
    fi
else
    echo "[1/7] 使用已设置的 GITHUB_TOKEN 环境变量（前 10 位：${GITHUB_TOKEN:0:10}）"
fi

# 3. clone 仓库
echo
echo "[2/7] git clone ..."
if [ -d "$REPO_DIR" ]; then
    echo "  [跳过] $REPO_DIR 已存在"
    cd "$REPO_DIR"
    git remote set-url origin "https://oauth2:${GITHUB_TOKEN}@github.com/WWH3602/second-brain.git"
else
    git clone "https://oauth2:${GITHUB_TOKEN}@github.com/WWH3602/second-brain.git" "$REPO_DIR"
    cd "$REPO_DIR"
fi

# 4. 配置用户
echo
echo "[3/7] 配置 git 用户信息 ..."
git config user.name "耗子助手"
git config user.email "openclaw@wwh.local"

# 5. 测试 pull
echo
echo "[4/7] 测试 git pull ..."
git pull origin main

# 6. 创建收件箱 + hook 脚本目录
echo
echo "[5/7] 创建工作目录 ..."
mkdir -p "$REPO_DIR/00-Inbox"
mkdir -p "$HOME/.openclaw/hooks/second-brain"

# 7. 写 QQ hook 脚本：记笔记
cat > "$HOME/.openclaw/hooks/second-brain/01_save_note.sh" << 'EOF'
#!/bin/bash
# 收到 QQ 私聊消息 → 写入 00-Inbox
# 参数: $1 = 消息内容
NOTE="$1"
TIMESTAMP=$(date +%Y%m%d-%H%M)
SAFE_NAME=$(echo "$NOTE" | head -c 20 | tr -dc 'a-zA-Z0-9_-')
FILE="$HOME/second-brain/00-Inbox/${TIMESTAMP}-${SAFE_NAME}.md"

cat > "$FILE" << NOTEEOF
# $(date '+%Y-%m-%d %H:%M')

> 来源: QQ 私聊 @ $(date '+%Y-%m-%d %H:%M:%S')

$NOTE

---
*由耗子助手自动记录，待 AI 整理*
NOTEEOF

cd "$HOME/second-brain" || exit 1
git add "00-Inbox/${TIMESTAMP}-${SAFE_NAME}.md"
git commit -m "记录: ${SAFE_NAME}" >/dev/null 2>&1
git push origin main >/dev/null 2>&1

echo "已记录到 $FILE 并推送到 GitHub"
EOF
chmod +x "$HOME/.openclaw/hooks/second-brain/01_save_note.sh"
echo "  [OK] 01_save_note.sh"

# 8. 写 QQ hook 脚本：整理收件箱
cat > "$HOME/.openclaw/hooks/second-brain/02_organize_inbox.sh" << 'EOF'
#!/bin/bash
# 整理 00-Inbox → 移动到对应分类
# 触发: 用户发"小龙虾，整理一下这周的收件箱"
cd "$HOME/second-brain" || exit 1
git pull origin main

# 列出 00-Inbox 里的文件
echo "当前收件箱内容："
ls -la 00-Inbox/

# AI 会读取这些文件内容，然后用 AI 分类移动
# 此脚本提供基础结构，AI 调用时会传入具体分类决策
echo "请用 AI 工具（如 Cursor / VSCode）配合'00-Inbox'目录内容进行手动整理"
echo "整理完后："
echo "  cd ~/second-brain && git add -A && git commit -m '整理: 收件箱' && git push"
EOF
chmod +x "$HOME/.openclaw/hooks/second-brain/02_organize_inbox.sh"
echo "  [OK] 02_organize_inbox.sh"

# 9. 写 QQ hook 脚本：装机清单
cat > "$HOME/.openclaw/hooks/second-brain/03_setup_list.sh" << 'EOF'
#!/bin/bash
# 输出装机清单（读 10-工具/10.1-电脑必备软件/README.md）
FILE="$HOME/second-brain/10-工具/10.1-电脑必备软件/README.md"
if [ -f "$FILE" ]; then
    cat "$FILE"
else
    git -C "$HOME/second-brain" pull origin main
    cat "$FILE"
fi
EOF
chmod +x "$HOME/.openclaw/hooks/second-brain/03_setup_list.sh"
echo "  [OK] 03_setup_list.sh"

# 10. 写定时 pull 任务
echo
echo "[6/7] 写定时 pull 任务（每 30 分钟同步本地编辑）..."
cat > "$HOME/.openclaw/hooks/second-brain/04_auto_pull.sh" << 'EOF'
#!/bin/bash
# 每 30 分钟自动 git pull（让 VM 端同步电脑编辑）
cd "$HOME/second-brain" || exit 1
git pull origin main --rebase --autostash 2>&1 | tail -5
EOF
chmod +x "$HOME/.openclaw/hooks/second-brain/04_auto_pull.sh"

# 加 cron
CRON_LINE="*/30 * * * * /home/wwh/.openclaw/hooks/second-brain/04_auto_pull.sh >> /home/wwh/second-brain-pull.log 2>&1"
(crontab -l 2>/dev/null | grep -v "second-brain/04_auto_pull.sh" || true; echo "$CRON_LINE") | crontab -
echo "  [OK] 04_auto_pull.sh + cron 已配置"

# 11. 清空环境变量
unset GITHUB_TOKEN

echo
echo "[7/7] 完成！"
echo
echo "============================================================"
echo "  初始化成功"
echo "============================================================"
echo
echo "已部署："
echo "  ✓ 仓库: $REPO_DIR"
echo "  ✓ Hook 脚本: ~/.openclaw/hooks/second-brain/"
echo "  ✓ 定时任务: 每 30 分钟自动 pull（cron）"
echo
echo "下一步："
echo "  1. 在 OpenClaw Web UI (http://127.0.0.1:18789) 配置 QQ 机器人 hook 触发规则"
echo "  2. 测试: 在 QQ 私聊耗子助手发一条消息，看是否写到 00-Inbox"
echo
echo "详细说明见: $REPO_DIR/04_OpenClaw_QQ_Hook_配置.md"
