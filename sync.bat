@echo off
chcp 65001 >nul
echo [1/3] Git Push...
cd /d D:\AI赋能中心\03_知识资产仓\个人生活\03_第二大脑
git push origin main
echo [2/3] SSH Tunnel...
start /min "" ssh -L 18789:127.0.0.1:18789 wwh@yidao.picp.net -p 10022 -N
timeout /t 3 /nobreak >nul
echo [3/3] VM Git Pull...
ssh -o ConnectTimeout=10 wwh@yidao.picp.net -p 10022 "cd /home/wwh/second-brain && git pull origin main"
echo.
echo ===== 全部完成 =====
pause
