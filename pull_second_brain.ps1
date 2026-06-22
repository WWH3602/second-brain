#!/usr/bin/env pwsh
# second-brain 本地一键同步脚本
# - git fetch 检查是否落后 GitHub
# - 落后则自动 fast-forward pull
# - 显示当前 HEAD + 落后多少 commit
# - 用法：双击 pull_second_brain.cmd，或 PowerShell 直接跑此脚本

$ErrorActionPreference = 'Stop'
$repoDir = Join-Path $PSScriptRoot ''
Set-Location -LiteralPath $repoDir

function Write-Box($msg) {
    $line = '=' * 60
    Write-Host ''
    Write-Host $line -ForegroundColor Cyan
    Write-Host $msg -ForegroundColor Cyan
    Write-Host $line -ForegroundColor Cyan
}

Write-Box 'second-brain 本地同步检查'

# 1. 状态
$dirty = git status --porcelain
if ($dirty) {
    Write-Host '[警告] 工作区有未提交改动：' -ForegroundColor Yellow
    Write-Host $dirty -ForegroundColor Yellow
    Write-Host '请先 commit 或 stash 后再拉取。' -ForegroundColor Yellow
    exit 1
}

# 2. fetch
Write-Host 'fetch origin/main ...'
git fetch origin main

# 3. 比较
$local  = (git rev-parse HEAD).Trim()
$remote = (git rev-parse origin/main).Trim()

if ($local -eq $remote) {
    Write-Host ''
    Write-Host '[OK] 本地已是最新' -ForegroundColor Green
    Write-Host "HEAD: $local"
    git log --oneline -3
    exit 0
}

# 4. 落后几个 commit
$behind = git rev-list --count HEAD..origin/main
Write-Host ''
Write-Host "[信息] 本地落后 GitHub $behind 个 commit" -ForegroundColor Yellow

# 5. 尝试 fast-forward pull
Write-Host ''
Write-Host '执行 git pull --ff-only ...'
git pull --ff-only origin main
if ($LASTEXITCODE -ne 0) {
    Write-Host ''
    Write-Host '[失败] fast-forward 失败，可能有冲突' -ForegroundColor Red
    Write-Host '请手动处理冲突后再跑此脚本。' -ForegroundColor Red
    exit 2
}

# 6. 完成
Write-Box '同步完成'
Write-Host "新 HEAD: $((git rev-parse HEAD).Trim())" -ForegroundColor Green
git log --oneline -5