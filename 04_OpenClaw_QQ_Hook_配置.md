# OpenClaw QQ Hook 配置（耗子助手 4 动作）

> 版本: v1.0 | 2026-06-17
> 目标：让手机 QQ 私聊耗子助手 → 自动写入第二大脑
> 部署位置：VM `/home/wwh/.openclaw/hooks/second-brain/`

---

## 1. 4 个动作概览

| 动作 | 触发词 | 用户输入示例 | 耗子助手行为 |
|------|--------|------------|------------|
| **记笔记** | 默认（任意消息） | "记一下：发现 Raycast，https://raycast.com" | 写到 `00-Inbox/`，push 到 GitHub |
| **查笔记** | `查` / `搜索` | "查 Raycast" | 搜 10-工具/20-灵感/30-网站，返回前 3 条 |
| **整理收件箱** | `整理` / `收件箱` | "小龙虾，整理一下" | 读 00-Inbox 内容，让 AI 分类移动到对应目录 |
| **装机清单** | `装机` / `装机清单` | "小龙虾，我新买了电脑" | 读 `10-工具/10.1-电脑必备软件/README.md` 输出 |

---

## 2. OpenClaw Web UI 配置步骤

### 2.1 进入 Hooks 配置
1. 打开 OpenClaw Web UI：http://127.0.0.1:18789/#token=b959248134d0ebbd145a2b0123716a87e42498440198dd82
2. 左侧菜单 → **Plugins** → **Hooks**
3. 点击 **"+ Add Hook"**

### 2.2 添加"记笔记" Hook
- **Name**: `second-brain-save-note`
- **Trigger**: `qqbot.message.private`
- **Type**: `script`
- **Command**: `/home/wwh/.openclaw/hooks/second-brain/01_save_note.sh`
- **Args**: `{{message.content}}`

### 2.3 添加"查笔记" Hook
- **Name**: `second-brain-search`
- **Trigger**: `qqbot.message.private.match:^(查|搜索)\s+`
- **Type**: `script`
- **Command**: `bash -c 'cd ~/second-brain && git pull >/dev/null 2>&1 && grep -ril "{{message.content#^查\\s+|搜索\\s+}}" 10-工具/ 20-灵感/ 30-网站/ 2>/dev/null | head -3 | xargs -I {} sh -c "echo --- {} ---; head -20 {}"'`

### 2.4 添加"整理收件箱" Hook
- **Name**: `second-brain-organize`
- **Trigger**: `qqbot.message.private.match:^(整理|小龙虾.*整理)`
- **Type**: `script`
- **Command**: `/home/wwh/.openclaw/hooks/second-brain/02_organize_inbox.sh`

### 2.5 添加"装机清单" Hook
- **Name**: `second-brain-setup-list`
- **Trigger**: `qqbot.message.private.match:^(装机|装机清单|给我装机)`
- **Type**: `script`
- **Command**: `/home/wwh/.openclaw/hooks/second-brain/03_setup_list.sh`

### 2.6 保存 + 重启 Gateway
```bash
systemctl --user restart openclaw-gateway.service
```

---

## 3. 配置文件（更可靠的方式：直接编辑 JSON）

在 VM 上编辑：
```bash
nano ~/.openclaw/openclaw.json
```

在 `hooks` 段添加：

```json
{
  "hooks": {
    "second-brain-save-note": {
      "trigger": "qqbot.message.private",
      "type": "script",
      "command": "/home/wwh/.openclaw/hooks/second-brain/01_save_note.sh",
      "args": ["{{message.content}}"]
    },
    "second-brain-search": {
      "trigger": "qqbot.message.private.match",
      "pattern": "^(查|搜索)\\s+",
      "type": "script",
      "command": "bash",
      "args": ["-c", "cd ~/second-brain && git pull >/dev/null 2>&1 && grep -ril '{{match.group.1}}' 10-工具/ 20-灵感/ 30-网站/ 2>/dev/null | head -3"]
    },
    "second-brain-organize": {
      "trigger": "qqbot.message.private.match",
      "pattern": "^(整理|小龙虾.*整理)",
      "type": "script",
      "command": "/home/wwh/.openclaw/hooks/second-brain/02_organize_inbox.sh"
    },
    "second-brain-setup-list": {
      "trigger": "qqbot.message.private.match",
      "pattern": "^(装机|装机清单|给我装机)",
      "type": "script",
      "command": "/home/wwh/.openclaw/hooks/second-brain/03_setup_list.sh"
    }
  }
}
```

保存后重启：
```bash
systemctl --user restart openclaw-gateway.service
journalctl --user -u openclaw-gateway.service -f
```

---

## 4. 测试方法

### 4.1 测"记笔记"
1. 手机 QQ → 私聊"耗子助手"
2. 发送："记一下：今天发现 Raycast 很好用"
3. 等 5 秒
4. 访问 https://github.com/WWH3602/second-brain
5. 应看到 `00-Inbox/20260617-xxxx-今天发现Raycast很好用.md`

### 4.2 测"查笔记"
1. 发："查 Raycast"
2. 耗子助手回复：前 3 条包含 Raycast 的笔记标题

### 4.3 测"整理收件箱"
1. 先发几条消息到收件箱
2. 发："整理"
3. 耗子助手回复：列出 00-Inbox 内容，提示"请手动整理或用 AI 工具"

### 4.4 测"装机清单"
1. 发："装机"
2. 耗子助手回复：`10-工具/10.1-电脑必备软件/README.md` 全部内容

---

## 5. 故障排查

### Q1: 发消息后没反应
```bash
# 1. 看 gateway 状态
systemctl --user status openclaw-gateway.service

# 2. 看 QQ 频道状态
openclaw channels status

# 3. 看最近日志
journalctl --user -u openclaw-gateway.service --no-pager -n 50 --since '5 min ago'
```

### Q2: hook 触发了但脚本没跑
```bash
# 给脚本加可执行权限
chmod +x ~/.openclaw/hooks/second-brain/*.sh

# 手动跑一遍测试
echo "test" | bash ~/.openclaw/hooks/second-brain/01_save_note.sh
```

### Q3: push 失败（认证错误）
```bash
# 检查 Token 是否还有效
cd ~/second-brain
export GITHUB_TOKEN=$(grep -oP 'GITHUB_TOKEN=\K[^\s]+' ~/02_凭据与安全.md | head -1)
git remote set-url origin "https://oauth2:${GITHUB_TOKEN}@github.com/WWH3602/second-brain.git"
git pull origin main  # 验证
```

---

## 6. 后续优化方向

- [ ] 整理收件箱用 AI 自动分类（接 DeepSeek API）
- [ ] 加"待办"动作：`#待办 xxx` → 写到 `20-灵感/待办.md`
- [ ] 加"提醒"动作：`#提醒 明天 9 点 xxx` → cron 触发
- [ ] 加"读名言"动作：`#名言` → 随机返回 50-名言/ 里一条
- [ ] 备份：每周日自动 git tag 一版

---

**最后更新**: 2026-06-17
