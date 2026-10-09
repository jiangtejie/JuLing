-- =============================================================================
-- 批次库存与效期预警（S2 库存中心 · 切片二）：菜单与权限
--
-- 背景：批次库存接口（ErpStockBatchController，前缀 /erp/stock-batch）已在切片一落地，
--       但没有建菜单——权限码 erp:stock:update 无菜单，只有超管能调；
--       批次库存也没有前端入口。本脚本只**加菜单/权限**，不删改任何既有数据。
--
-- 内容：
--   1) 菜单「批次库存」挂到既有「库存管理」(2583) 下，path=batch、
--      component=erp/stock/batch/index、component_name=ErpStockBatch
--      （必须与前端 apps/web-antd/src/views/erp/stock/batch/index.vue 真实路径一致，
--        否则动态路由 import.meta.glob('../views/**/*.vue') 找不到组件会 404）；
--   2) 按钮权限：
--        erp:stock:batch:query  —— 列表查询（前端 /erp/stock-batch/page 页面级权限，与后端
--                                  实际校验的 erp:stock:query 同时生效）；
--        erp:stock:batch:update —— 页面「状态登记」按钮的前端鉴权码；
--        erp:stock:update       —— **后端 update-state 真正校验的码**（ErpStockBatchController:130）。
--                                  该码此前没有菜单行，导致任何角色都无法通过「角色-菜单」映射拿到它
--                                  （yudao 的权限集合来自 system_menu.permission），
--                                  所以这里必须补一条按钮菜单，否则非超管点「状态登记」必定 403。
--                                  全仓库只有该接口用这个码，补菜单的影响面被限制在批次状态登记。
--   3) 把上述 4 个菜单**连同全部祖先菜单**授予「供应链(157)」「财务(156)」。
--      递归授权是必须的：yudao 的 MenuServiceImpl.isMenuDisabled 会把"父菜单不在授权集合里"
--      的节点整棵剔除，只授深层权限会导致权限与菜单都下不到前端（见 sql/local/34_role_menu_ancestors.sql）。
--
-- 幂等：INSERT ... ON CONFLICT (id) DO NOTHING + 授权前 NOT EXISTS 判重，可重复执行。
-- 执行：docker exec -i postgres psql -U root -d yate -f - < sql/local/37_stock_batch_menu.sql
--       （或 psql -U root -d yate -f sql/local/37_stock_batch_menu.sql）
-- =============================================================================

-- ---------- 1) 菜单：批次库存（挂在 2583「库存管理」下，排在既有 7 个菜单之后） ----------
INSERT INTO system_menu (id, name, permission, type, sort, parent_id, path, icon, component, component_name, status, visible, keep_alive, always_show, creator, create_time, updater, update_time, deleted)
VALUES (11570, '批次库存', '', 2, 7, 2583, 'batch', 'ep:alarm-clock', 'erp/stock/batch/index', 'ErpStockBatch', 0, TRUE, TRUE, TRUE, '1', now(), '1', now(), 0)
ON CONFLICT (id) DO NOTHING;

-- ---------- 2) 按钮权限 ----------
INSERT INTO system_menu (id, name, permission, type, sort, parent_id, path, icon, component, component_name, status, visible, keep_alive, always_show, creator, create_time, updater, update_time, deleted)
VALUES
    (11571, '批次库存查询',   'erp:stock:batch:query',  3, 1, 11570, '', '', '', '', 0, TRUE, TRUE, FALSE, '1', now(), '1', now(), 0),
    (11572, '批次状态登记',   'erp:stock:batch:update', 3, 2, 11570, '', '', '', '', 0, TRUE, TRUE, FALSE, '1', now(), '1', now(), 0),
    (11573, '批次状态登记接口', 'erp:stock:update',       3, 3, 11570, '', '', '', '', 0, TRUE, TRUE, FALSE, '1', now(), '1', now(), 0)
ON CONFLICT (id) DO NOTHING;

-- ---------- 3) 授权：新增的 4 个菜单 + 递归补全祖先菜单 → 角色 157 供应链 / 156 财务 ----------
-- system_role_menu.id 无默认值，且序列常落后于 max(id)（见 28_fix_all_sequences.sql），
-- 因此用 max(id) + row_number() 取号，避免撞主键。
WITH RECURSIVE seed AS (
    SELECT m.id, m.parent_id
      FROM system_menu m
     WHERE m.id IN (11570, 11571, 11572, 11573)
       AND m.deleted = 0
), tree AS (
    SELECT id, parent_id FROM seed
    UNION
    SELECT p.id, p.parent_id
      FROM tree t
      JOIN system_menu p ON p.id = t.parent_id AND p.deleted = 0
), target AS (
    SELECT DISTINCT id FROM tree WHERE id IS NOT NULL AND id <> 0
), missing AS (
    SELECT r.role_id, t.id AS menu_id
      FROM (VALUES (157), (156)) AS r(role_id)
      CROSS JOIN target t
     WHERE NOT EXISTS (SELECT 1 FROM system_role_menu x
                        WHERE x.role_id = r.role_id AND x.menu_id = t.id AND x.deleted = 0)
)
INSERT INTO system_role_menu (id, role_id, menu_id, creator, create_time, updater, update_time, deleted, tenant_id)
SELECT (SELECT COALESCE(MAX(id), 0) FROM system_role_menu) + row_number() OVER (), role_id, menu_id, '1', now(), '1', now(), 0, 1
  FROM missing;

-- ---------- 4) 核对查询（执行后人工看一眼） ----------
-- 菜单（应看到 1 个 type=2 的「批次库存」+ 3 个 type=3 的按钮）：
-- select id, parent_id, name, permission, type, sort, path, component, component_name
--   from system_menu where id in (11570, 11571, 11572, 11573) order by id;
-- 授权（两个角色各应看到 11570/11571/11572/11573 + 祖先 2583/2563）：
-- select rm.role_id, m.id, m.name, m.permission
--   from system_role_menu rm join system_menu m on m.id = rm.menu_id
--  where rm.role_id in (156, 157) and rm.deleted = 0 and m.id in (11570, 11571, 11572, 11573, 2583, 2563)
--  order by rm.role_id, m.id;
