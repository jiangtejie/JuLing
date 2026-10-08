-- ============================================================================
-- 75 修复「空目录」菜单：点进去是空白页
--
-- 【现象】商城系统 → 订货账号，点开后什么都不渲染。
--
-- 【根因】system_menu.type=1（目录）+ component 为空 + **没有任何子节点**。
--   前端对「目录」的处理是：自己渲染 Layout，页面内容由子路由提供；
--   而它一个子节点都没有，所以是空白。
--
-- 【成因】菜单归口重构（把菜单收拢到「主数据」「基础资料」等分组）时，
--   旧位置的菜单没被清理，留在原处变成了空壳。
--   实测：订货账号在「主数据 → 订货账号列表」(id=2317) 已经存在且可用。
--
-- 【本脚本做什么】**不删除**，而是把空壳补成可用的页面（非破坏性、可回退）：
--   · 订货账号     → 指向 member/user/index（与 2317 同一个页面）
--   · 物料管理     → 指向 erp/product/product/index
--   并把 type 从 1（目录）改成 2（菜单），与正常页面一致。
--
-- 【遗留】这两条因此与现有菜单**功能重复**。要不要删掉由业务决定 ——
--   确认后单独出脚本软删（deleted=1），不要顺手删。
--
-- 幂等：可重复执行。
-- ============================================================================

BEGIN;

-- ① 订货账号：补 component + 改成页面类型
UPDATE system_menu
   SET component = 'member/user/index', type = 2, update_time = now()
 WHERE id = 12140 AND deleted = 0
   AND (component IS NULL OR component = '');

-- ② 物料管理：同样处理（还没人报，但现象完全一样）
UPDATE system_menu
   SET component = 'erp/product/product/index', type = 2, update_time = now()
 WHERE id = 2564 AND deleted = 0
   AND (component IS NULL OR component = '');

-- ③ 自检：列出仍然「目录 + 无 component + 无子节点」的菜单（应为 0 行）
SELECT '剩余空目录菜单' AS item, count(*)::text AS value
  FROM system_menu m
 WHERE m.deleted = 0 AND m.type = 1 AND m.status = 0
   AND (m.component IS NULL OR m.component = '')
   AND (SELECT count(*) FROM system_menu c WHERE c.parent_id = m.id AND c.deleted = 0) = 0
UNION ALL
SELECT '已修的 12140', component FROM system_menu WHERE id = 12140
UNION ALL
SELECT '已修的 2564',  component FROM system_menu WHERE id = 2564;

COMMIT;
