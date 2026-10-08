-- ============================================================================
-- 77 物理清除测试数据（用户明确确认「全部删除」）
--
-- 【执行前务必知道】
--   · 物理删除**不可回退**。本脚本第 ① 步先把受影响的表整体备份到 bak_cleanup schema，
--     需要时可以从那里恢复。
--   · system_dept 里不全是测试数据 —— 含真实组织（100 重庆亚特餐饮发展有限公司、
--     金蝶导入的各公司/部门）。用户已确认这些也要删，故一并删除。
--   · **用户与仓库保留**：只把它们的 dept_id 置空，不删账号/仓库
--     （用户是登录账号，删了会锁死；用户也没要求删它们）。
--
-- 【删什么】
--   ① 备份：system_dept / system_users / erp_warehouse / erp_customer
--   ② 解除引用：system_users.dept_id、erp_warehouse.dept_id 置空
--      （erp_customer / erp_customer_account / trade_order / trade_order_receipt 实测 0 行引用）
--   ③ system_dept 全表物理删除（含 deleted=1 的历史行）
--   ④ 调试用测试数据：erp_product / erp_customer / erp_price_list 及其明细与范围
--      中 id >= 900000 的行（TEST-WHR / TEST-STORE / TEST-PSJM）
--
-- 幂等：可重复执行（第二次执行删除 0 行）。
-- ============================================================================

BEGIN;

-- ① 备份（schema 不存在则建；表用日期后缀，多次执行不冲突）
CREATE SCHEMA IF NOT EXISTS bak_cleanup;

CREATE TABLE IF NOT EXISTS bak_cleanup.system_dept_20261008 AS SELECT * FROM system_dept;
CREATE TABLE IF NOT EXISTS bak_cleanup.system_users_20261008 AS SELECT * FROM system_users;
CREATE TABLE IF NOT EXISTS bak_cleanup.erp_warehouse_20261008 AS SELECT * FROM erp_warehouse;
CREATE TABLE IF NOT EXISTS bak_cleanup.erp_customer_20261008 AS SELECT * FROM erp_customer;
CREATE TABLE IF NOT EXISTS bak_cleanup.erp_product_20261008 AS SELECT * FROM erp_product;
CREATE TABLE IF NOT EXISTS bak_cleanup.erp_price_list_20261008 AS SELECT * FROM erp_price_list;

-- ② 解除部门引用（置空而不是删行）
UPDATE system_users  SET dept_id = NULL, update_time = now() WHERE dept_id IS NOT NULL;
UPDATE erp_warehouse SET dept_id = NULL, update_time = now() WHERE dept_id IS NOT NULL;

-- ③ 部门全表物理删除
DELETE FROM system_dept;

-- ④ 调试用测试数据
DELETE FROM erp_price_list_item  WHERE price_id >= 900000;
DELETE FROM erp_price_list_scope WHERE price_id >= 900000;
DELETE FROM erp_price_list       WHERE id >= 900000;
DELETE FROM erp_product          WHERE id >= 900000;
DELETE FROM erp_customer         WHERE id >= 900000;

-- ⑤ 自检
SELECT '剩余部门（应为 0）' AS 项, count(*)::text AS 值 FROM system_dept
UNION ALL SELECT '剩余测试物料（应为 0）', count(*)::text FROM erp_product WHERE id >= 900000
UNION ALL SELECT '剩余测试门店（应为 0）', count(*)::text FROM erp_customer WHERE id >= 900000
UNION ALL SELECT '剩余测试价目表（应为 0）', count(*)::text FROM erp_price_list WHERE id >= 900000
UNION ALL SELECT '保留的用户数（应为 6）', count(*)::text FROM system_users
UNION ALL SELECT '保留的仓库数（应为 2）', count(*)::text FROM erp_warehouse
UNION ALL SELECT '备份的部门行数', count(*)::text FROM bak_cleanup.system_dept_20261008;

COMMIT;
