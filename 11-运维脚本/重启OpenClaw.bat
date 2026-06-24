@echo off
ssh -o ConnectTimeout=15 wwh@yidao.picp.net -p 10022 "systemctl --user restart openclaw-gateway.service"
echo OpenClaw 已重启
pause
