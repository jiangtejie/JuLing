-- ============================================================================
-- 66 隐患收尾：编码前缀冲突 / 菜单术语不一致 / 组织节点名不副实
--
-- 三处都是前几轮改造留下的尾巴，不影响功能但会让「看着对不上」：
--
-- 1) **编码前缀冲突**：product_spu（商城商品）与 erp_product（ERP 物料）都用 WL 前缀，
--    规则名还写着「物料（商品）编码」—— 两套目录合并后两边的码长得一模一样，肉眼无法区分。
--    商城侧改为 SP（商品）。**两张表当前都是 0 行、current_value 都是 0**，改动零成本。
--    背景见 master-data-unified-design §4.1（两套重复目录待合并）。
--
-- 2) **WMS 基础数据下术语不一致**：6270 物料品牌 / 6340 物料分类 已经叫「物料」，
--    中间的 6390 却叫「商品管理」。改「物料管理」（与 64 号脚本把 ERP 侧统一为物料的同一次收尾）。
--
-- 3) **组织节点名不副实**：120「直营门店」下面曾经挂着 6 家 store_type=FRANCHISE 的加盟店
--    （实测过），而店型的权威早已移到 erp_customer.store_type（organization-architecture-design §7 决策①）。
--    这个节点不存店型却用名字宣称了一个错误的店型，等于一个不准确的第二权威。
--    现在它下面 0 个子节点（测试数据已清），改名「门店」去掉错误暗示。
--    注：门店该不该挂品牌、这个容器要不要留，属待定的组织改造，本次只改名字。
--
-- 幂等：可重复执行（都用 旧值 → 新值 的条件写法，重复执行不再命中）。
-- ============================================================================

BEGIN;

-- 0) 备份要改的行
CREATE SCHEMA IF NOT EXISTS bak_cleanup_loose_ends_20261007;
CREATE TABLE IF NOT EXISTS bak_cleanup_loose_ends_20261007.system_code_rule
    AS SELECT * FROM system_code_rule WHERE rule_key = 'product_spu';
CREATE TABLE IF NOT EXISTS bak_cleanup_loose_ends_20261007.system_menu
    AS SELECT * FROM system_menu WHERE id IN (6390, 12200);
CREATE TABLE IF NOT EXISTS bak_cleanup_loose_ends_20261007.system_dept
    AS SELECT * FROM system_dept WHERE id = 120;

-- 1) 商城商品编码前缀 WL → SP
UPDATE system_code_rule
   SET prefix = 'SP', name = '商品编码', remark = '商城商品（product_spu）；与 ERP 物料（WL）区分开',
       updater = 'script66', update_time = now()
 WHERE deleted = 0 AND rule_key = 'product_spu' AND prefix = 'WL';

-- 2) WMS 6390 商品管理 → 物料管理
UPDATE system_menu SET name = '物料管理', updater = 'script66', update_time = now()
 WHERE deleted = 0 AND id = 6390 AND name = '商品管理';

-- 3) 组织节点 120 直营门店 → 门店
UPDATE system_dept SET name = '门店', updater = 'script66', update_time = now()
 WHERE deleted = 0 AND id = 120 AND name = '直营门店';

-- 自检
SELECT '编码规则' AS item, string_agg(rule_key || '=' || prefix, ' | ' ORDER BY id) AS value
  FROM system_code_rule WHERE deleted = 0
UNION ALL SELECT 'WMS 基础数据下的菜单',
       COALESCE((SELECT string_agg(id || ':' || name, ' | ' ORDER BY id) FROM system_menu
                  WHERE deleted = 0 AND parent_id = 6210), '无')
UNION ALL SELECT '组织节点 120',
       COALESCE((SELECT name || '（子节点 ' || (SELECT count(*) FROM system_dept c WHERE c.parent_id = 120 AND c.deleted = 0) || ' 个）'
                   FROM system_dept WHERE id = 120 AND deleted = 0), '无')
UNION ALL SELECT '仍含「直营门店」的节点（应为 0）',
       (SELECT count(*)::text FROM system_dept WHERE deleted = 0 AND name LIKE '%直营门店%')
UNION ALL SELECT '仍含「商品管理」的 WMS 菜单（应为 0）',
       (SELECT count(*)::text FROM system_menu WHERE deleted = 0 AND parent_id = 6210 AND name = '商品管理');

COMMIT;