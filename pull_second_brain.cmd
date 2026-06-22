@echo off
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0pull_second_brain.ps1"
echo.
echo 按任意键退出...
pause >nul