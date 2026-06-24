"""
Second Brain MCP Server - 耗子助手核心工具
提供：笔记保存（自动分类）+ 知识库查询（读取）
"""
import re
import subprocess
from datetime import datetime
from pathlib import Path
from fastmcp import FastMCP

mcp = FastMCP("second-brain-tools")
SB_DIR = Path("/home/wwh/second-brain")

# ============================================================
# 分类规则（与 00-收件箱/分类规则.md 保持一致）
# ============================================================
CATEGORY_MAP = {
    "06-社交人脉": "社交活动/人脉记录",
    "01-软件工具": "软件/工具推荐",
    "02-网页收藏": "好网站/URL收藏",
    "03-美食探店": "餐厅/美食记录",
    "04-灵感哲思": "想法/灵感/名言",
    "05-技术备忘": "技术相关",
    "00-收件箱": "临时待分类",
}


def classify(content: str, title: str) -> str:
    """根据内容关键字自动分类，返回分类目录名（与 分类规则.md 一致）。"""
    text = f"{content} {title}"

    # P0: 社交人脉（人名 + 社交动词）
    people_keywords = ['请客', '吃饭', '聚会', '朋友', '同事', '领导', '老师', '同学',
                       '介绍', '认识', '约会', '请我', '请他', '请她', '找他', '找她',
                       '关系', '友谊', '相识', '聊天', '聚餐']
    person_pattern = re.compile(
        r'[A-Za-z\u4e00-\u9fa5]{2,4}(?:老师|总|经理|主任|工|哥|姐|弟|妹|叔|姨|爷|奶|同学|朋友)'
    )
    if person_pattern.search(text) and any(kw in text for kw in people_keywords):
        return "06-社交人脉"

    # P1: 软件工具
    tool_keywords = ['开源', '免费', '软件', '工具', '安装', '下载', 'App', '应用',
                     '插件', '扩展', 'IDE', '编辑器', '浏览器', '版本', '更新', '合集',
                     '清单', '推荐']
    if any(kw in text for kw in tool_keywords):
        return "01-软件工具"

    # P2: 网页收藏（URL 或 爬虫关键词）
    url_pattern = re.compile(r'https?://[^\s\)\]\}，。；！？]+')
    web_keywords = ['爬取', '爬下来', '文章', '公众号', '网页', '博客', '视频', '网站',
                    '帖子', '新闻', '链接']
    if url_pattern.search(text) or any(kw in text for kw in web_keywords):
        return "02-网页收藏"

    # P3: 美食探店
    food_keywords = ['餐厅', '美食', '好吃', '探店', '饭店', '菜', '味道', '推荐菜',
                     '地址', '营业', '菜单']
    if any(kw in text for kw in food_keywords):
        return "03-美食探店"

    # P4: 灵感哲思
    idea_keywords = ['想法', '灵感', '创意', '名言', '语录', '感悟', '反思', '心得',
                     '计划', '目标']
    if any(kw in text for kw in idea_keywords):
        return "04-灵感哲思"

    # P5: 技术备忘
    tech_keywords = ['MCP', 'mcp', 'OpenClaw', '配置', '部署', '测试', '验证', 'API',
                     '接口', '开发', '代码', 'bug', '修复', '待办', 'TODO']
    if any(kw in text for kw in tech_keywords):
        return "05-技术备忘"

    # 默认：收件箱
    return "00-收件箱"


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


@mcp.tool()
def query_second_brain(query: str = "", category: str = "") -> str:
    """
    查询 second-brain 知识库。根据关键词读取相关笔记内容，返回给用户。
    当用户问"清单"、"推荐"、"有什么"、"给我看看"、"查询"、"最近有什么"、
    "装机清单"、"必装软件"、"美食推荐"、问某个城市/省份的美食时，调用此工具。

    参数 query: 用户的查询关键词或意图（如"必装软件"、"福州美食"、"名言"）
    参数 category: 可选，限定搜索目录（如"01-软件工具/PC软件"、"03-美食探店"）
    """
    try:
        # 1. 先拉取最新
        subprocess.run(
            ["git", "-C", str(SB_DIR), "pull", "origin", "main"],
            capture_output=True, text=True, timeout=30
        )

        results = []
        search_text = query.lower()

        if category:
            # 指定目录搜索
            target_dir = SB_DIR / category
            if target_dir.exists():
                for f in sorted(target_dir.rglob("*.md")):
                    if ".git" in str(f):
                        continue
                    rel_path = f.relative_to(SB_DIR)
                    content = f.read_text(encoding="utf-8")
                    if not search_text or search_text in content.lower():
                        # 截取匹配段落
                        preview = content[:800]
                        results.append(f"📄 **{rel_path}**\n{preview}")
        else:
            # 全局搜索
            for f in sorted(SB_DIR.rglob("*.md")):
                if ".git" in str(f):
                    continue
                rel_path = f.relative_to(SB_DIR)
                content = f.read_text(encoding="utf-8")
                if not search_text or search_text in content.lower():
                    preview = content[:500]
                    results.append(f"📄 **{rel_path}**\n{preview}")

            # 如果没有关键词匹配，也返回一些目录结构供 AI 参考
            if not results and not search_text:
                for cat in CATEGORY_MAP:
                    cat_dir = SB_DIR / cat
                    if cat_dir.exists():
                        files = list(cat_dir.rglob("*.md"))
                        file_list = "\n".join(
                            f"  - {f.relative_to(SB_DIR)}" for f in sorted(files)
                            if ".git" not in str(f)
                        )
                        results.append(f"📁 **{cat}** — {CATEGORY_MAP[cat]}\n{file_list if file_list else '  （空）'}")

        if not results:
            return f"📭 第二大脑中未找到与「{query}」相关的内容。"

        output = "\n---\n".join(results[:8])  # 最多8条
        return f"📚 **第二大脑查询结果**（关键词：{query or '全部'}）\n\n{output}"

    except Exception as e:
        return f"❌ 查询失败：{e}"


if __name__ == "__main__":
    mcp.run()
