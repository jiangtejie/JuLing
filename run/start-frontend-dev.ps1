# 启动矩灵前端开发服务器(Vite,端口 5666)
# 说明：供开发调试使用；生产环境访问的是 nginx 发布的 /jl(构建产物 dist)，不依赖本脚本。
#      由计划任务 JuLing-Frontend-Dev 调用，也可手动执行。

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$web  = Join-Path $root 'juling-ui\juling-ui-admin-vben'
$log  = Join-Path $root 'run\frontend-dev.log'

# pnpm 版本对齐(本机 pnpm 垫片目录)
$env:PATH = "$env:USERPROFILE\.dsh\pnpm116-shim;$env:PATH"

Set-Location $web
Write-Host "[矩灵] 启动前端开发服务器：$web (端口 5666)" -ForegroundColor Cyan
pnpm dev:antd *>&1 | Tee-Object -FilePath $log -Append
