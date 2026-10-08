#!/bin/sh
# 数据库初始化：应用【当前结构基线】
#
# 【为什么不再按 sql/local 顺序重放全部脚本】
#   那是两年的演进历史，不是部署产物。实测在全新库上按顺序重跑会失败（78 个里 9 个挂掉），
#   根因是脚本之间有隐式依赖（如 system_role_menu_seq 被显式 id 插入甩在后面、
#   49/50 假设 Flowable 已建表、21/29 引用早已不存在的列），
#   而 52 号失败会让 dept_type / business_status 两个列根本建不出来 ——
#   **组织架构功能在全新环境上立不起来**。
#
#   改为：从开发库导出的结构基线（baseline-schema.sql）+ 框架种子数据（baseline-seed.sql）。
#   已验证：全新 PG 18 上应用后，表数/菜单/字典/用户/序列与开发库**逐项一致**。
#
#   sql/local/ 保留为历史记录，**新环境不需要执行**。
set -e

PSQL="psql -v ON_ERROR_STOP=1 -h $PGHOST -U $PGUSER -d $PGDATABASE"

echo "[db-init] 等待数据库就绪…"
until pg_isready -h "$PGHOST" -U "$PGUSER" -d "$PGDATABASE" >/dev/null 2>&1; do sleep 2; done

echo "[db-init] ① 结构基线（baseline-schema.sql）"
$PSQL -f /sql/postgresql/baseline-schema.sql

echo "[db-init] ② 框架种子数据（baseline-seed.sql：菜单/字典/角色/用户/编码规则）"
$PSQL -f /sql/postgresql/baseline-seed.sql

echo "[db-init] 完成。可用以下语句核对："
echo "  psql -c \"select count(*) from information_schema.tables where table_schema='public'\"  -- 应为 236"
