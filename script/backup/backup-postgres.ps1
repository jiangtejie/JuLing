<#
  矩灵 PostgreSQL 备份脚本

  作用：把 WSL/Docker 中的 PostgreSQL 库导出为 custom-format 归档(.dump)，校验归档完整性，
        并按保留天数清理旧备份。

  用法：
    powershell -NoProfile -ExecutionPolicy Bypass -File script\backup\backup-postgres.ps1
    powershell ... -File script\backup\backup-postgres.ps1 -BackupDir D:\bak -RetentionDays 30

  恢复见同目录 README.md。
#>
param(
    [string]$Container     = 'postgres',
    [string]$Database      = 'juling',
    [string]$DbUser        = 'root',
    [string]$BackupDir     = 'D:\A_ERP\backups\postgres',
    [int]   $RetentionDays = 14
)

$ErrorActionPreference = 'Stop'
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$name  = "$Database-$stamp.dump"
$inner = "/tmp/$name"
$dest  = Join-Path $BackupDir $name

New-Item -ItemType Directory -Force -Path $BackupDir | Out-Null

# 1) 容器内导出（-Fc：custom format，自带压缩，支持 pg_restore 选择性恢复）
$dump = docker exec $Container pg_dump -U $DbUser -d $Database -Fc -f $inner 2>&1
if ($LASTEXITCODE -ne 0) { throw "pg_dump 失败：$dump" }

# 2) 从容器拷到宿主机
docker cp "${Container}:${inner}" $dest | Out-Null
if ($LASTEXITCODE -ne 0) { throw "docker cp 失败：$dest" }
docker exec $Container rm -f $inner | Out-Null

# 3) 校验：文件头 PGDMP + 归档可列举
$bytes = [System.IO.File]::ReadAllBytes($dest)
$magic = [System.Text.Encoding]::ASCII.GetString($bytes[0..4])
if ($magic -ne 'PGDMP') { throw "归档头异常（期望 PGDMP，实际 $magic）：$dest" }

$verifyInner = '/tmp/_verify.dump'
docker cp $dest "${Container}:${verifyInner}" | Out-Null
$objCount = (docker exec $Container pg_restore -l $verifyInner 2>&1 | Where-Object { $_ -and $_ -notmatch '^;' }).Count
docker exec $Container rm -f $verifyInner | Out-Null
if ($objCount -lt 1) { throw "归档不可读或为空：$dest" }

$sizeMb = [Math]::Round((Get-Item $dest).Length / 1MB, 2)

# 4) 保留策略：删除超出保留期的备份
$cutoff  = (Get-Date).AddDays(-$RetentionDays)
$removed = @(Get-ChildItem $BackupDir -Filter "$Database-*.dump" -File |
             Where-Object { $_.LastWriteTime -lt $cutoff })
foreach ($f in $removed) { Remove-Item $f.FullName -Force }

Write-Output ("[备份完成] {0}  {1} MB  归档对象 {2} 个  保留 {3} 天" -f $dest, $sizeMb, $objCount, $RetentionDays)
if ($removed.Count -gt 0) { Write-Output ("[已清理] " + (($removed | ForEach-Object { $_.Name }) -join ', ')) }
$all = Get-ChildItem $BackupDir -Filter "$Database-*.dump" -File | Sort-Object LastWriteTime -Descending
Write-Output ("[现有备份] {0} 份，最新 {1}" -f $all.Count, $all[0].Name)
