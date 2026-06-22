# 第二大脑（Second Brain）

> 版本: v2.0 | 2026-06-17 初版 / 2026-06-22 重构目录

打通 **手机(iOS QQ) ↔ 虚拟机 OpenClaw(耗子助手) ↔ 自己的电脑** 三端，
让 AI 替我**记录灵感、收集工具/网站/美食/名言**，新电脑一句"给我装机清单"就恢复。

---

## 仓库信息

| 项 | 值 |
| --- | --- |
| **GitHub 用户名** | `WWH3602` |
| **仓库名** | `second-brain` |
| **仓库 URL** | `https://github.com/WWH3602/second-brain` |
| **可见性** | 私有（Private） |
| **默认分支** | `main` |

---

## 目录结构

```
03_第二大脑/
├── README.md                        ← 本文件（总入口）
├── .gitignore
├── .git/
│
├── docs/                            ← 文档（快速上手/凭据/配置/运维）
│   ├── 00_快速上手.md               ← 5 分钟启动指南
│   ├── 02_凭据与安全.md              ← ⚠️ .gitignore，不上传
│   ├── 02_OpenClaw初始化.md         ← VM 端初始化步骤（合并版）
│   ├── 02_OpenClaw初始化.sh         ← VM 端一键脚本
│   ├── 03_QQ通道配置.md             ← QQ 4 动作配置（历史参考）
│   └── 04_运维指南.md               ← 服务管理/故障排查快速查阅
│
├── scripts/                         ← 运维脚本（MCP server + 管理工具）
│   ├── add_mcp.py                  ← 注册 MCP server 到 OpenClaw
│   ├── monitor_openclaw.sh         ← 监控 OpenClaw 进程
│   ├── restart_openclaw.py         ← 重启脚本
│   ├── restart_openclaw.sh         ← 重启脚本（shell 版）
│   ├── second_brain_mcp_server.py  ← 核心：笔记保存 MCP 工具
│   ├── pull_second_brain.cmd       ← Windows pull 脚本
│   └── pull_second_brain.ps1       ← Windows pull 脚本（PowerShell）
│
├── 01_初始化本地仓库.bat             ← Windows 本地一键初始化
│
├── 00-Inbox/                        ← 收件箱（手机 QQ 消息只写这里）
├── 01-软件工具/
├── 90-归档/
└── workspace/                      ← 本地工作目录（git tracked）
```

---

## 三端数据流

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

**手机**：只发 QQ 消息（iOS 无需装 Git App）
**OpenClaw（VM）**：pull → 写文件 → commit → push，仓库路径 `/home/wwh/second-brain`
**电脑（本地）**：直接 VSCode 编辑，定时 git pull 同步

---

## 使用方式

| 用户输入 | AI 动作 |
| --- | --- |
| 「记：发现 Raycast 很好用 https://raycast.com」 | 自动分类 → commit → push → 回执（含 commit hash） |
| 「小龙虾，整理一下收件箱」 | 读 `00-Inbox/` → AI 分类整理 |
| 「小龙虾，我新买了电脑，装机清单」 | 读 `01-软件工具/10.1-电脑必备软件/` → 输出清单 |

---

## 当前主力写入链路

```
QQ 消息 → OpenClaw qqbot → AI 识别"记：xxx"
  → 调 save_to_second_brain() MCP 工具
  → scripts/second_brain_mcp_server.py（stdio 子进程，懒加载）
  → git pull/add/commit/push
  → 响应（含 commit hash，如"（commit 7c8022c）"）
```

**注意**：QQ bot **不走** shell hook，走的是 MCP server。修改 MCP 源码后不需要重启 OpenClaw。

---

## 落地状态

| 步骤 | 状态 | 时间 |
| --- | --- | --- |
| GitHub 私有仓库创建 | ✅ 完成 | 2026-06-17 |
| PAT 生成 + 凭据文档 | ✅ 完成 | 2026-06-17 |
| OpenClaw VM 初始化 | ✅ 完成 | 2026-06-17 |
| MCP Server 部署（替代 hook） | ✅ 完成 | 2026-06-22 |
| 端到端验证（commit hash 回执） | ✅ 完成 | 2026-06-22 |
| 目录结构重构 | ✅ 完成 | 2026-06-22 |

---

## 文档索引

| 文档 | 内容 |
| --- | --- |
| `docs/00_快速上手.md` | 5 分钟启动指南 |
| `docs/04_运维指南.md` | 服务管理/故障排查/SSH 隧道 |
| `docs/02_OpenClaw初始化.md` | VM 端初始化步骤 |
| `docs/02_凭据与安全.md` | Token 存放与安全（.gitignore） |

---

**最后更新**: 2026-06-22（v2.0：目录重构，文档/脚本/分类分离）
