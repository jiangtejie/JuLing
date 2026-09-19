# 启动矩灵后端(juling-server)
# 用法：在 PowerShell 中执行   .\run\start-backend.ps1
# 说明：优先使用 juling-server/target 下的构建产物；target 被清理时回退到本地 Maven 仓库中的快照 jar。

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$target = Join-Path $root 'juling-server\target\juling-server.jar'
$m2 = Join-Path $env:USERPROFILE '.m2\repository\com\lxjl\boot\juling-server\2026.08-SNAPSHOT\juling-server-2026.08-SNAPSHOT.jar'

$jar = if (Test-Path $target) { $target } else { $m2 }
if (-not (Test-Path $jar)) {
    Write-Error "未找到可运行的 jar。请先构建：cd $root; mvn -T 1C install -DskipTests -B -ntp"
}

Write-Host "[矩灵] 启动后端：$jar" -ForegroundColor Cyan
Write-Host "[矩灵] 端口 48080，API 前缀 /admin-api" -ForegroundColor DarkGray
Set-Location $root
java -jar $jar
