-- ============================================================================
-- 71 价目表菜单 component 归口到新路径
--
-- 背景：后端早已归口到通用的 controller/admin/pricelist、service/pricelist，
--   但前端还挂在 erp/purchase/price 下 —— **而配送价目表也挂在 purchase 下**（purchase/delivery-price），
--   「采购下的配送」读起来就是错的。价目表现在是**公共资料**（采购 + 配送共用），
--   前端同步归口到 erp/price-list。
--
--   新布局：
--     erp/price-list/List.vue            实现（同一个组件，按 priceType 渲染）
--     erp/price-list/purchase/index.vue  采购价目表入口
--     erp/price-list/delivery/index.vue  配送价目表入口
--
-- 幂等：可重复执行。
-- ============================================================================

BEGIN;

UPDATE system_menu SET component = 'erp/price-list/purchase/index', updater = 'script71', update_time = now()
 WHERE deleted = 0 AND id = 12200 AND component = 'erp/purchase/price/index';
UPDATE system_menu SET component = 'erp/price-list/delivery/index', updater = 'script71', update_time = now()
 WHERE deleted = 0 AND id = 12210 AND component = 'erp/purchase/delivery-price/index';

SELECT '价目表菜单现状' AS item,
       COALESCE((SELECT string_agg(id || ':' || name || ' → ' || COALESCE(component, '(无)'), ' | ' ORDER BY id)
                   FROM system_menu WHERE deleted = 0 AND id IN (12200, 12210)), '无') AS value
UNION ALL SELECT '旧路径残留（应为 0）',
       (SELECT count(*)::text FROM system_menu WHERE deleted = 0 AND component LIKE 'erp/purchase/%price%');

COMMIT;
