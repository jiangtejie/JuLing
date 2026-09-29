-- ============================================================================
-- 47 清理「指向不存在页面」的死菜单 + 消除菜单重名
--
-- 一、死菜单：系统菜单里有 1 条页面菜单的 component 指向已删除的页面文件——
--   2525 基础设施 → WebSocket（component = infra/webSocket/index），该演示页已随
--   「websocket 演示」一起从仓库移除，点进去必然打不开（前端只会报
--   route component is invalid）。它的角色授权为 0 条，直接删除即可。
--   （已用「菜单 component ↔ 前端 views 文件」全量核对：145 条页面菜单里只有这 1 条不存在。）
--
-- 二、重名菜单：前端 generate-menus.ts 在 name 重复时会自动给路由名追加 id，并打
--   console.error: menu name duplicate。全库有 3 组重名，其中 2 组是 WMS 基础数据照抄了
--   商城/ERP 的名字，另 1 组是 WMS 的库存目录与 ERP 的库存管理同名。这里把 WMS 侧改名，
--   与其实页面（wms/md/item/*、wms/inventory/*）对齐：
--     6510 WMS 系统 → 库存管理      → 库存台账（子页：库存统计、库存流水）
--     6340 WMS 系统/基础数据 → 商品分类 → 物料分类（wms/md/item/category）
--     6270 WMS 系统/基础数据 → 商品品牌 → 物料品牌（wms/md/item/brand）
--   商城/ERP 侧的名字保持不动。
--
-- 幂等：可重复执行。
-- ============================================================================

BEGIN;

-- 1) 删除死菜单（含角色授权，当前为 0 条）
DELETE FROM system_role_menu WHERE menu_id = 2525;
DELETE FROM system_menu WHERE id = 2525;

-- 2) WMS 侧重命名，消除重名
UPDATE system_menu SET name = '库存台账', updater = 'script47', update_time = now()
WHERE id = 6510 AND deleted = 0 AND name = '库存管理';
UPDATE system_menu SET name = '物料分类', updater = 'script47', update_time = now()
WHERE id = 6340 AND deleted = 0 AND name = '商品分类';
UPDATE system_menu SET name = '物料品牌', updater = 'script47', update_time = now()
WHERE id = 6270 AND deleted = 0 AND name = '商品品牌';

-- 3) 自检
SELECT '死菜单 2525 是否还在' AS item,
       COALESCE((SELECT 'yes' FROM system_menu WHERE id = 2525), 'no') AS value
UNION ALL
SELECT '菜单重名组数（应为 0）',
       (SELECT count(*)::text FROM (SELECT name FROM system_menu WHERE deleted = 0 AND type IN (1, 2)
                                    GROUP BY name HAVING count(*) > 1) t)
UNION ALL
SELECT 'WMS 库存目录新名',
       COALESCE((SELECT name || '（子页 ' || (SELECT count(*) FROM system_menu c WHERE c.deleted = 0 AND c.parent_id = 6510) || ' 个）'
                 FROM system_menu WHERE id = 6510), '缺失')
UNION ALL
SELECT 'WMS 基础数据新名',
       COALESCE((SELECT string_agg(name, ' / ' ORDER BY sort) FROM system_menu WHERE deleted = 0 AND id IN (6340, 6270)), '缺失');

COMMIT;
