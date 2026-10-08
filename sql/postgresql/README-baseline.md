# 数据库基线说明

## 全新环境用这个

| 文件 | 内容 | 来源 |
| --- | --- | --- |
| `baseline-schema.sql` | **结构全量**（public schema，236 张表 / 515 个序列） | `pg_dump --schema-only -n public` |
| `baseline-seed.sql` | **框架种子数据**：菜单 720 / 字典 411 项 / 角色 / 用户 6 / 编码规则 9 | `pg_dump --data-only` 指定表 |

执行顺序：先 schema 再 seed。

**已验证**：在全新的 PostgreSQL 18.6 上应用后，表数、菜单数、字典项数、用户数、序列数
与当前开发库**逐项一致**（236 / 720 / 411 / 6 / 515）。

## 为什么不再按 sql/local 顺序重放

`sql/local/` 下的脚本是**两年的演进历史**，不是部署产物。实测在全新库上按顺序重跑，
78 个里会挂 9 个：

| 失败脚本 | 根因 | 类别 |
| --- | --- | --- |
| 52_organization_architecture | system_role_menu_seq 落后于 max(id) → 主键冲突 | 序列漂移 |
| 55_master_data_menu | 同上 | 序列漂移 |
| 38_store_receipt_and_receivables | 同上（已修复） | 序列漂移 |
| 58_clean_all_test_data | `dept_type` 不存在 ← **52 失败的级联** | 级联 |
| 72_org_store_under_brand | 同上 | 级联 |
| 49_clean_test_order_data | `act_hi_procinst` 不存在（Flowable 建的表，全新库还没建） | 时序假设 |
| 50_clean_test_erp_and_bpm_data | 同上 | 时序假设 |
| 21_trade_amount_defaults | `refund_point` 列从没被任何脚本建过 | 旧基线残留 |
| 29_seed_demo_data | `member_user.point` 同上 | 旧基线残留 |

**其中 52 的失败最致命**：它建 `system_dept.dept_type` 与 `business_status`，
失败后组织架构（含「建门店」）在全新环境上**根本立不起来**。

序列漂移的机制：`28_fix_all_sequences.sql` 会把序列对齐到那一刻的 max(id)，
但 **29~51 号脚本又用显式 id 往 `system_role_menu` 插了一批行**（yudao 菜单 id 在 12000+ 区间），
序列再次落后。代码库自己的注释也承认了这个现象。

## 旧的三个文件

`juling-baseline.sql` / `module-schema.sql` / `quartz.sql` 是**上一代基线**，
保留作历史参考，**新环境不要执行**（它们是 yudao 原始基线 + 模块表的拼装，
不含本项目 2025 年以来的结构变更）。

## 重新生成基线

开发库结构有重大变更后，重新导出：

    docker run --rm -e PGPASSWORD=<密码> -v "$PWD/sql/postgresql:/out" postgres:15-alpine \
      pg_dump -h host.docker.internal -U root -d yate \
      --schema-only --no-owner --no-privileges -n public -f /out/baseline-schema.sql

    docker run --rm -e PGPASSWORD=<密码> -v "$PWD/sql/postgresql:/out" postgres:15-alpine \
      pg_dump -h host.docker.internal -U root -d yate \
      --data-only --no-owner --column-inserts -n public \
      -t system_menu -t system_role_menu -t system_role -t system_users \
      -t system_dict_type -t system_dict_data -t system_tenant \
      -t system_code_rule -t system_config -t system_notify_template \
      -f /out/baseline-seed.sql

**导出后必须手工删掉 `CREATE SCHEMA public;` 与 `COMMENT ON SCHEMA public ...` 两行** ——
新库的 public 已存在，带着它们会以 `ERROR: schema "public" already exists` 中止，
后面全崩（这个坑我踩过一次）。

导出后务必在全新的库上验一遍，并核对表数/菜单数等关键数字。
