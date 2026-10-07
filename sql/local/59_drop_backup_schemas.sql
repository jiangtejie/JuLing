-- ============================================================================
-- 59 删除历史备份 schema
--
-- 背景：前几轮清理（44/45/43/40/49/50 等）按惯例把要删的数据整表备份到 bak_* schema，
--   共 10 个、398 张表。它们装的是**已经删过的**历史数据（下线模块 MES/PMS/CRM/HRM/IM/IoT、
--   支付归档表、营销与评价表、会员中心表、测试订单与测试 ERP 数据），实测数据量极小。
--
-- ⚠️ 本脚本**不可回退** —— 这些 schema 是那些历史数据唯一的副本。
--   保留 bak_testdata_20261007（58 号脚本产生），它是本次全库清理的回退路径。
--
-- 幂等：可重复执行。
-- ============================================================================

BEGIN;

DROP SCHEMA IF EXISTS bak_cleanup_20260929 CASCADE;
DROP SCHEMA IF EXISTS bak_erp_ctr2_20260922 CASCADE;
DROP SCHEMA IF EXISTS bak_erp_ctr_20260922 CASCADE;
DROP SCHEMA IF EXISTS bak_member_center_20260929 CASCADE;
DROP SCHEMA IF EXISTS bak_pay_archive_20260929 CASCADE;
DROP SCHEMA IF EXISTS bak_promotion_20260929 CASCADE;
DROP SCHEMA IF EXISTS bak_tenant123_20260928 CASCADE;
DROP SCHEMA IF EXISTS bak_test_erp_20260929 CASCADE;
DROP SCHEMA IF EXISTS bak_test_orders_20260929 CASCADE;
DROP SCHEMA IF EXISTS bak_unused_modules_20260929 CASCADE;

-- 自检：剩余非系统 schema 应只剩 public + bak_testdata_20261007
SELECT '剩余 schema' AS item, string_agg(schema_name, ', ' ORDER BY schema_name) AS value
  FROM information_schema.schemata
 WHERE schema_name NOT LIKE 'pg\_%' AND schema_name <> 'information_schema';

COMMIT;