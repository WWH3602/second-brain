@echo off
chcp 65001 >nul
echo ============================================
echo  第二大脑 VM 更新 + MCP 注册脚本
echo  1. git pull 最新代码
echo  2. 复制 MCP server 到 OpenClaw 目录
echo  3. 注册 MCP server 到 openclaw.json
echo  4. 重启 OpenClaw 服务
echo ============================================
echo.

ssh -o ConnectTimeout=15 wwh@yidao.picp.net -p 10022 ^
  "cd /home/wwh/second-brain && ^
   git pull origin main && ^
   cp 11-运维脚本/second_brain_mcp_server.py /home/wwh/.openclaw/ && ^
   cd /home/wwh/.openclaw && ^
   source mcp-env/bin/activate && ^
   python3 /home/wwh/second-brain/11-运维脚本/add_mcp.py && ^
   echo '✅ MCP 注册完成' && ^
   systemctl --user restart openclaw-gateway.service && ^
   echo '✅ OpenClaw 已重启'"
   
echo.
echo ============================================
echo  完成！现在去 QQ 上给耗子助手发：
echo  "小龙虾，我新买了电脑，帮我列出必装的软件清单"
echo ============================================
pause
