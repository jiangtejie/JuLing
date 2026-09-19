# script/backup —— 数据库备份

## 备份

```powershell
# 默认：postgres 容器 / juling 库 / D:\A_ERP\backups\postgres / 保留 14 天
powershell -NoProfile -ExecutionPolicy Bypass -File script\backup\backup-postgres.ps1

# 自定义
powershell -NoProfile -ExecutionPolicy Bypass -File script\backup\backup-postgres.ps1 `
    -BackupDir 'E:\db-backup' -RetentionDays 30
```

脚本做的事：

1. 容器内 `pg_dump -Fc`（custom format，自带压缩，可用 `pg_restore` 选择性恢复）；
2. `docker cp` 到宿主机 `D:\A_ERP\backups\postgres\juling-<时间戳>.dump`；
3. 校验：文件头必须是 `PGDMP`，并用 `pg_restore -l` 确认归档可列举（防止半截文件被当成有效备份）；
4. 按 `-RetentionDays` 删除过期备份。

## 定时任务

已注册 Windows 计划任务，每天 02:30 执行：

```powershell
Get-ScheduledTask   -TaskName 'JuLing-Postgres-Backup'            # 查看
Start-ScheduledTask -TaskName 'JuLing-Postgres-Backup'            # 立即跑一次
Get-ScheduledTaskInfo -TaskName 'JuLing-Postgres-Backup'          # 看上次结果(0 = 成功)
Unregister-ScheduledTask -TaskName 'JuLing-Postgres-Backup'       # 取消
```

任务以「当前登录用户 + 交互式令牌」运行，因为 Docker Desktop 只在用户登录时可用；
机器长期不登录时请改用其他备份载体（如云数据库自带的备份）。

## 恢复

```powershell
# 1) 把备份拷进容器
docker cp D:\A_ERP\backups\postgres\juling-20260913-134738.dump postgres:/tmp/restore.dump

# 2) 恢复(覆盖同名对象；建议先确认目标库/先做一次现网备份)
docker exec postgres pg_restore -U root -d juling --clean --if-exists -j 4 /tmp/restore.dump

# 3) 清理
docker exec postgres rm -f /tmp/restore.dump
```

若恢复到新库（更安全，可对照验证）：

```powershell
docker exec postgres psql -U root -d postgres -c "CREATE DATABASE juling_restore;"
docker cp <dump> postgres:/tmp/restore.dump
docker exec postgres pg_restore -U root -d juling_restore /tmp/restore.dump
# 验证后改 application-local.yaml 的库名即可切换
```

## 注意

- 备份文件不在仓库内（`D:\A_ERP\backups`），避免仓库体积膨胀；如需纳入版本/异地保存，请自行同步到对象存储。
- 备份只覆盖 PostgreSQL；Redis（缓存/会话）与 `run/uploads`（本地文件存储）按需另备。

## Git 历史备份（T3 压缩前）

仓库历史在 T3 已压缩为单提交，压缩前的完整历史（10957 个提交 + release 标签）备份在仓库外：

```powershell
# 备份位置（174.6 MB，git bundle verify = complete history）
D:\A_ERP\java17\JuLing-git-history-before-squash.bundle

# 查看 / 校验
git bundle verify D:\A_ERP\java17\JuLing-git-history-before-squash.bundle

# 需要旧历史时：克隆出一个临时仓库查看（不影响当前仓库）
git clone D:\A_ERP\java17\JuLing-git-history-before-squash.bundle D:\A_ERP\java17\JuLing-old-history

# 确认不再需要后可直接删除该 bundle（删掉即无法找回旧历史）
```

> 说明：远端 `origin` 上的旧提交在 `--force` 推送后成为悬空对象，由 GitHub 自行 GC；
> 旧的 release 标签（`v1.0.0`…`v2026.08*`）已在本地与远端一并删除。
