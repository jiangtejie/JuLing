-- ============================================================================
-- 64 术语统一：ERP 主数据「产品」→「物料」
--
-- 背景（docs/master-data-unified-design.md）：金蝶把这类主数据叫**物料**，本系统 ERP 侧叫「产品」；
--   而**下游订货链与库存页面早已在用「物料」**（`ERP 物料编号` / `请选择物料` / `物料数`），
--   只有主数据页还叫「产品」—— 术语是分裂的。本脚本把菜单文案统一为「物料」。
--
-- 顺带的好处：ERP 侧叫「物料」、商城侧叫「商品」，两套目录在中文里不再混淆
--   （它们本就是两套重复目录，见 master-data-unified-design §4.1 的待合并项）。
--
-- **只改菜单显示名**，不动 permission 标识（`erp:product:*`）—— 改了会让存量角色授权全部失效。
--   代码侧同步改了 149 个文件 729 处文案（类名/表名/路由/权限标识都是 ASCII，未受影响）。
--
-- 幂等：可重复执行。
-- ============================================================================

BEGIN;

-- 1) 备份
CREATE SCHEMA IF NOT EXISTS bak_rename_product_to_material_20261007;
CREATE TABLE IF NOT EXISTS bak_rename_product_to_material_20261007.system_menu
    AS SELECT * FROM system_menu WHERE name LIKE '%产品%';

-- 2) 改名（含按钮权限名；只改包含「产品」的）
UPDATE system_menu
   SET name = replace(name, '产品', '物料'), updater = 'script64', update_time = now()
 WHERE deleted = 0 AND name LIKE '%产品%';

-- 3) 自检
SELECT '改后仍含「产品」的菜单（应为 0）' AS item, count(*)::text AS value
  FROM system_menu WHERE deleted = 0 AND name LIKE '%产品%'
UNION ALL SELECT 'ERP 物料相关菜单现状',
       COALESCE((SELECT string_agg(name, ' | ' ORDER BY id) FROM system_menu
                  WHERE deleted = 0 AND id IN (2564, 2565, 2566, 2567, 2568, 2569, 2570, 2571, 2577, 2590)), '无')
UNION ALL SELECT '商城侧仍是「商品」（不应被改）',
       COALESCE((SELECT string_agg(name, ' | ' ORDER BY id) FROM system_menu
                  WHERE deleted = 0 AND id IN (2000, 2002, 2008, 2014, 2019)), '无')
UNION ALL SELECT 'WMS 侧物料/商品菜单（本次未动）',
       COALESCE((SELECT string_agg(id || ':' || name, ' | ' ORDER BY id) FROM system_menu
                  WHERE deleted = 0 AND id IN (6270, 6340, 6390)), '无');

COMMIT;