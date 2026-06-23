"""
Second Brain MCP Server - 耗子助手核心工具
将笔记保存到 second-brain 仓库，自动分类到对应目录，并 git push。
"""
import re
import subprocess
from datetime import datetime
from pathlib import Path
from fastmcp import FastMCP

mcp = FastMCP("second-brain-tools")
SB_DIR = Path("/home/wwh/second-brain")


def classify(content: str, title: str) -> str:
    """根据内容关键字自动分类，返回分类目录名。"""
    text = f"{content} {title}"

    # 优先级1: 人物关系（人名 + 社交/关系动词）
    people_keywords = ['请客', '吃饭', '聚会', '朋友', '同事', '领导', '老师', '同学',
                       '介绍', '认识', '约会', '请我', '请他', '请她', '找他', '找她',
                       '关系', '友谊', '相识', '聊天']
    person_pattern = re.compile(r'[A-Za-z\u4e00-\u9fa5]{2,4}(?:老师|总|经理|主任|工|哥|姐|弟|妹|叔|姨|爷|奶|同学|朋友)')
    if person_pattern.search(text) and any(kw in text for kw in people_keywords):
        return "02-人物"

    # 优先级2: 软件工具（开源/安装/下载地址/工具/软件）—— 在URL前，避免"开源工具+下载链接"被错判为网络资源
    tool_keywords = ['开源', '免费', '软件', '工具', '安装', '下载', 'App', '应用',
                     '插件', '扩展', 'IDE', '编辑器', '浏览器', '版本', '更新', '合集']
    if any(kw in text for kw in tool_keywords):
        return "01-软件工具"

    # 优先级3: 网络资源（URL 或 爬虫关键词，且不属于工具）
    url_pattern = re.compile(r'https?://[^\s\)\]\}，。；！？]+')
    web_keywords = ['爬取', '爬下来', '文章', '公众号', '网页', '博客', '视频', '网站', '帖子', '新闻', '链接']
    if url_pattern.search(text) or any(kw in text for kw in web_keywords):
        return "03-网络资源"

    # 默认：Inbox
    return "00-Inbox"


@mcp.tool()
def save_to_second_brain(content: str, title: str = "") -> str:
    """
    将笔记保存到 second-brain 仓库，自动分类到对应目录，并自动 git push。
    当用户说"记：xxx"、"帮我记"、"请记"、"记录"时，调用此工具。
    （不是 save_to_inbox，不要和 KnowledgeRepository 的 inbox 混淆）

    分类规则：
    - 包含URL/链接/爬取/文章 → 03-网络资源/
    - 包含人名+社交动词（请客/吃饭/朋友等） → 02-人物/
    - 包含开源/软件/下载/安装等 → 01-软件工具/
    - 其他 → 00-Inbox/

    参数 content: 笔记正文内容
    参数 title:  可选标题
    """
    try:
        # 1. git pull
        subprocess.run(
            ["git", "-C", str(SB_DIR), "pull", "origin", "main"],
            capture_output=True, text=True, timeout=30
        )

        # 2. 自动分类
        category = classify(content, title or "")
        category_dir = SB_DIR / category
        category_dir.mkdir(parents=True, exist_ok=True)

        # 3. 生成文件名
        now = datetime.now()
        if title:
            safe = "".join(c for c in title if c.isalnum() or c in ' -_').strip()[:40]
            filename = f"{now.strftime('%Y%m%d-%H%M')}_{safe}.md"
        else:
            filename = f"{now.strftime('%Y%m%d-%H%M%S')}_note.md"

        file_path = category_dir / filename

        # 4. 写文件
        header = f"""---
title: {title or '未命名笔记'}
date: {now.strftime('%Y-%m-%d %H:%M:%S')}
category: {category}
source: QQ/耗子助手
---

"""
        file_path.write_text(header + content, encoding="utf-8")

        # 5. git add + commit + push
        subprocess.run(
            ["git", "-C", str(SB_DIR), "add", "."],
            check=True, capture_output=True, text=True
        )
        commit_msg = f"note: {now.strftime('%m%d-%H%M')} [{category}] {title or '未命名笔记'}"
        subprocess.run(
            ["git", "-C", str(SB_DIR), "commit", "-m", commit_msg],
            check=True, capture_output=True, text=True
        )
        subprocess.run(
            ["git", "-C", str(SB_DIR), "push", "origin", "main"],
            check=True, capture_output=True, text=True, timeout=30
        )

        return (f"✅ 已记录到 second-brain\n"
                f"📂 分类：{category}\n"
                f"📁 文件：{category}/{filename}\n"
                f"📝 内容预览：{content[:80]}{'...' if len(content) > 80 else ''}\n"
                f"🔗 GitHub：https://github.com/WWH3602/second-brain/tree/main/{category}")

    except subprocess.TimeoutExpired:
        return "❌ 操作超时（git push 可能网络慢）"
    except subprocess.CalledProcessError as e:
        return f"❌ Git 操作失败：{e.stderr}"
    except Exception as e:
        return f"❌ 系统错误：{e}"


if __name__ == "__main__":
    mcp.run()
