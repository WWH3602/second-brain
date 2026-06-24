@echo off
chcp 65001 >nul
echo ============================================
echo  第二大脑 VM 更新脚本
echo  1. SSH 到虚拟机 git pull
echo  2. 复制 MCP server 到 OpenClaw 目录
echo ============================================
echo.

ssh -o ConnectTimeout=15 wwh@yidao.picp.net -p 10022 "cd /home/wwh/second-brain && git pull origin main && cp 11-运维脚本/second_brain_mcp_server.py /home/wwh/.openclaw/ && echo '✅ VM 更新完成'"

echo.
echo ---- 完成 ----
echo 现在可以去 QQ 上测试了，给耗子助手发：
echo "小龙虾，我新买了电脑，帮我列出必装的软件清单"
pause
