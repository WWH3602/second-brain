@echo off
chcp 65001 >nul
echo ============================================
echo  配置 SSH 免密登录（仅需一次密码）
echo  本机公钥 → VM 的 authorized_keys
echo  之后 SSH 再也不需要密码！
echo ============================================
echo.

type C:\Users\Administrator\.ssh\id_rsa.pub | ssh wwh@yidao.picp.net -p 10022 "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"

if %errorlevel% equ 0 (
    echo.
    echo ✅ SSH 免密配置成功！之后所有操作不再需要密码。
    echo.
    echo 按任意键继续部署 MCP server...
    pause >nul
    ssh -o ConnectTimeout=15 wwh@yidao.picp.net -p 10022 ^
      "cd /home/wwh/second-brain && ^
       git pull origin main && ^
       cp 11-运维脚本/second_brain_mcp_server.py /home/wwh/.openclaw/ && ^
       cd /home/wwh/.openclaw && ^
       source mcp-env/bin/activate && ^
       python3 /home/wwh/second-brain/11-运维脚本/add_mcp.py && ^
       echo '✅ MCP 注册完成' && ^
       systemctl --user restart openclaw-gateway.service && ^
       echo '✅ OpenClaw 已重启，现在去 QQ 测试！'"
    pause
) else (
    echo.
    echo ❌ 配置失败，请检查密码是否正确
    pause
)
