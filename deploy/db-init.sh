#!/bin/sh
# 数据库初始化：按仓库 README 约定的顺序执行全部 SQL
#
# 为什么不用 postgres 镜像的 /docker-entrypoint-initdb.d：
#   1) 它**不递归子目录**，而我们的脚本分在 postgresql/ 与 local/ 两个目录
#   2) 它**只在数据卷为空时执行一次**，之后改脚本不会重跑（出问题很难排查）
# 改用一次性容器显式执行：可重跑（脚本本身幂等），日志也看得见。
set -e

PSQL="psql -v ON_ERROR_STOP=1 -h $PGHOST -U $PGUSER -d $PGDATABASE"

echo "[db-init] 等待数据库就绪…"
until pg_isready -h "$PGHOST" -U "$PGUSER" -d "$PGDATABASE" >/dev/null 2>&1; do sleep 2; done

echo "[db-init] ① 基线（juling-baseline）"
$PSQL -f /sql/postgresql/juling-baseline.sql

echo "[db-init] ② 模块表（module-schema）"
$PSQL -f /sql/postgresql/module-schema.sql

echo "[db-init] ③ 定时任务表（quartz）"
$PSQL -f /sql/postgresql/quartz.sql

echo "[db-init] ④ sql/local 下的增量脚本（按文件名排序；脚本本身幂等）"
for f in $(ls /sql/local/*.sql | sort); do
  echo "[db-init]    - $(basename "$f")"
  $PSQL -f "$f"
done

echo "[db-init] 完成。"
