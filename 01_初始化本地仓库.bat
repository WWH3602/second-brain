@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

echo.
echo ============================================================
echo   第二大脑 - 本地仓库初始化脚本
echo   路径: D:\AI赋能中心\03_知识资产仓\个人生活\03_第二大脑\
echo ============================================================
echo.

REM 切换到工作目录
set "REPO_DIR=D:\AI赋能中心\03_知识资产仓\个人生活\03_第二大脑"
cd /d "%REPO_DIR%"

REM 检查是否已是 git 仓库
if exist ".git" (
    echo [跳过] 已是 git 仓库（.git 已存在）
) else (
    echo [1/8] git init ...
    git init -b main
    if errorlevel 1 (
        echo [错误] git init 失败
        pause
        exit /b 1
    )
)

REM 配置 git 用户信息（仅本仓库）
echo.
echo [2/8] 配置 git 用户信息 ...
git config user.name "WWH3602"
git config user.email "wwh@example.com"

REM 写 .gitignore
echo.
echo [3/8] 写入 .gitignore ...
(
    echo # 凭据与安全（绝不上传）
    echo 02_凭据与安全.md
    echo # 系统文件
    echo .DS_Store
    echo Thumbs.db
    echo desktop.ini
    echo # 编辑器临时文件
    echo *.swp
    echo *~
    echo *.tmp
    echo # 临时脚本（AI 生成的一次性脚本）
    echo _*.bat
    echo _*.ps1
    echo # 大文件（避免仓库膨胀）
    echo *.zip
    echo *.rar
    echo *.7z
    echo *.mp4
    echo *.mov
) > .gitignore

REM 验证 .gitignore 生效
echo   验证 02_凭据与安全.md 是否被忽略 ...
git check-ignore 02_凭据与安全.md >nul 2>&1
if errorlevel 1 (
    echo [警告] 02_凭据与安全.md 没被 .gitignore 排除，请检查
) else (
    echo   [OK] 02_凭据与安全.md 已被 .gitignore 排除
)

REM 创建分类骨架
echo.
echo [4/8] 创建分类骨架 ...
if not exist "00-Inbox"           mkdir 00-Inbox
if not exist "10-工具\10.1-电脑必备软件" mkdir "10-工具\10.1-电脑必备软件"
if not exist "10-工具\10.2-开发工具"     mkdir "10-工具\10.2-开发工具"
if not exist "10-工具\10.3-提效工具"     mkdir "10-工具\10.3-提效工具"
if not exist "20-灵感"             mkdir 20-灵感
if not exist "30-网站"             mkdir 30-网站
if not exist "40-美食"             mkdir 40-美食
if not exist "50-名言"             mkdir 50-名言
if not exist "90-归档"             mkdir 90-归档

REM 写 00-Inbox/README.md
(
    echo # 收件箱
    echo.
    echo ^>^> 用途：手机 QQ 发到耗子助手的所有消息**只先写这里**
    echo ^>^> 处理：AI 定期把这里的笔记整理到对应分类目录
    echo.
    echo ## 命名规则
    echo.
    echo 每条消息一个文件，文件名格式：`YYYYMMDD-HHMM-主题.md`
    echo.
    echo 示例：`20260617-0945-Raycast工具.md`
    echo.
    echo ## 状态
    echo.
    echo - [ ] 待 AI 整理（耗子助手会定期处理）
) > 00-Inbox\README.md

REM 写 10-工具/10.1-电脑必备软件/README.md
(
    echo # 电脑必备软件（装机清单）
    echo.
    echo ^>^> 新电脑"小龙虾，给我装机清单" → 读这个目录
    echo.
    echo ## 软件清单
    echo.
    echo - [Visual Studio Code](https://code.visualstudio.com/) - 代码编辑器
    echo - [Google Chrome](https://www.google.com/chrome/) - 浏览器
    echo - [7-Zip](https://www.7-zip.org/) - 解压缩
    echo - [PotPlayer](https://potplayer.daum.net/) - 视频播放器
    echo - [Raycast](https://www.raycast.com/) - 启动器（macOS）/ PowerToys（Windows 替代）
    echo.
    echo ## 待补充
    echo.
    echo - 公司常用软件（VPN / 内网工具）
) > "10-工具\10.1-电脑必备软件\README.md"

REM 写 20-灵感/README.md
(
    echo # 灵感笔记
    echo.
    echo ^>^> 随时想到的点子、idea、反思
    echo.
    echo ## 命名规则
    echo.
    echo `YYYYMM-主题.md`（按月归档）
    echo.
    echo 示例：`202606-PersonalOKR.md`
) > 20-灵感\README.md

REM 写 30-网站/README.md
(
    echo # 网站收藏
    echo.
    echo ^>^> 看到的好网站、AI 工具、效率工具 URL
    echo.
    echo ## 命名规则
    echo.
    echo - 按类别分文件：`工具网站.md` / `学习网站.md` / `娱乐网站.md`
    echo - 格式：`- [名称](URL) - 一句话说明`
) > 30-网站\README.md

REM 写 40-美食/README.md
(
    echo # 美食地图
    echo.
    echo ^>^> 吃过的餐厅 / 想去的店 / 菜谱
    echo.
    echo ## 命名规则
    echo.
    echo - `餐厅-店名-城市.md`（吃过的店）
    echo - `菜谱-菜名.md`（学做的菜）
) > 40-美食\README.md

REM 写 50-名言/README.md
(
    echo # 名言警句
    echo.
    echo ^>^> 看到的有道理的话
    echo.
    echo ## 格式
    echo.
    echo ^>^> "名言内容"
    echo ^>^> — 作者
    echo.
    echo ^>^> 我的解读 / 适用场景
) > 50-名言\README.md

REM 写 90-归档/README.md
(
    echo # 归档
    echo.
    echo ^>^> 已整理过的过期笔记
    echo.
    echo ## 规则
    echo.
    echo - 超过 6 个月未访问的笔记移到这里
    echo - 保持按月归档：`202512/` `202601/` ...
) > 90-归档\README.md

REM 首次 commit
echo.
echo [5/8] git add ...
git add .

echo.
echo [6/8] git status 预览 ...
git status --short

echo.
echo [7/8] git commit ...
git commit -m "初始化第二大脑仓库：分类骨架 + README"
if errorlevel 1 (
    echo [错误] commit 失败
    pause
    exit /b 1
)

REM 配 remote + push
echo.
echo [8/8] 配 remote + push 到 GitHub ...
echo.
echo 重要：以下命令会从 02_凭据与安全.md 读取明文 Token
echo       (此文件已在 .gitignore 排除，绝不会被 push)
echo.

REM 用 PowerShell 读取 Token 并设置环境变量
for /f "usebackq tokens=*" %%i in (`powershell -NoProfile -Command "Get-Content '02_凭据与安全.md' | Select-String -Pattern '^GITHUB_TOKEN=(.+)$' | ForEach-Object { $_.Matches[0].Groups[1].Value }"`) do set "GITHUB_TOKEN=%%i"

if "%GITHUB_TOKEN%"=="" (
    echo [错误] 没读到 Token，请检查 02_凭据与安全.md
    pause
    exit /b 1
)

echo   Token 读取成功（前 10 位：%GITHUB_TOKEN:~0,10%）

REM 配 remote URL
git remote remove origin 2>nul
git remote add origin "https://oauth2:%GITHUB_TOKEN%@github.com/WWH3602/second-brain.git"

REM push
git push -u origin main
if errorlevel 1 (
    echo.
    echo [警告] push 失败，可能是 GitHub 端还没创建仓库
    echo         请先去 https://github.com/new 创建一个名为 second-brain 的私有仓库
    echo         然后再手动执行：git push -u origin main
    echo.
    pause
    exit /b 1
) else (
    echo.
    echo [成功] 推送完成
    REM 安全：清空 remote URL 里的 Token（明文出现在 URL 很危险）
    git remote set-url origin "https://github.com/WWH3602/second-brain.git"
    echo [安全] remote URL 已清空 Token
)

REM 清空环境变量
set "GITHUB_TOKEN="

echo.
echo ============================================================
echo   初始化完成！
echo ============================================================
echo.
echo 下一步：
echo   1. 去 VM (ssh wwh@yidao.picp.net -p 10022)
echo   2. 跑 03_OpenClaw_初始化.sh
echo.
pause
