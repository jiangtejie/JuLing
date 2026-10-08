-- ============================================================================
-- 55 基础资料菜单归口：把散落的主数据收进一个入口
--
-- 背景（见 docs/master-data-unified-design.md §3.2）：主数据今天散在四个一级菜单下 ——
--   组织架构在「系统管理」、客户在「ERP → 销售管理」、供应商在「ERP → 采购管理」、
--   仓库在「ERP → 库存管理」、结算账户在「ERP → 财务管理」、订货账号在「商城系统」。
--   维护人得记住「客户在销售的菜单里、供应商在采购的菜单里」。
--
-- 金蝶的做法是「一个基础资料平台集中维护，子系统只引用」（该文 §1）。本脚本只做**菜单归口**：
--   **不动任何表结构、不动任何 API 路径**（前端页面按 component 挂载，与菜单 path 无关）。
--
--   · 新建一级目录「基础资料」+ 二级「主数据」「公共资料」
--   · 迁入 ERP 侧主数据与组织架构、订货账号
--   · 商城「商品中心」与 WMS「基础数据」**暂不迁** —— 它们与 ERP 产品/仓库是两套重复目录，
--     等物料合并（该文 §5 二期）时一并归口，现在只搬一半反而更乱
--
-- 幂等：可重复执行。
-- ============================================================================

BEGIN;

-- ---------------------------------------------------------------------------
-- 1) 新建目录
-- ---------------------------------------------------------------------------
INSERT INTO system_menu (id, name, permission, type, sort, parent_id, path, icon, component, component_name,
                         status, visible, keep_alive, always_show, creator, create_time, updater, update_time, deleted)
VALUES (12180, '基础资料', '', 1, 55, 0, '/master-data', 'lucide:database', NULL, NULL,
        0, true, true, true, 'script55', now(), 'script55', now(), 0),
       (12181, '主数据',   '', 1, 1, 12180, 'md',     'lucide:table-2', NULL, NULL,
        0, true, true, true, 'script55', now(), 'script55', now(), 0),
       (12182, '公共资料', '', 1, 2, 12180, 'common', 'lucide:library', NULL, NULL,
        0, true, true, true, 'script55', now(), 'script55', now(), 0)
ON CONFLICT (id) DO NOTHING;

-- ---------------------------------------------------------------------------
-- 2) 迁移既有菜单的父节点
-- ---------------------------------------------------------------------------
-- 主数据：组织架构 / 客户 / 供应商 / 产品 / 订货账号
UPDATE system_menu SET parent_id = 12181, sort = 1, updater = 'script55', update_time = now() WHERE id = 103  AND deleted = 0 AND parent_id <> 12181; -- 组织架构管理
UPDATE system_menu SET parent_id = 12181, sort = 2, updater = 'script55', update_time = now() WHERE id = 2618 AND deleted = 0 AND parent_id <> 12181; -- 客户信息
UPDATE system_menu SET parent_id = 12181, sort = 3, updater = 'script55', update_time = now() WHERE id = 2603 AND deleted = 0 AND parent_id <> 12181; -- 供应商信息
UPDATE system_menu SET parent_id = 12181, sort = 4, updater = 'script55', update_time = now() WHERE id = 2565 AND deleted = 0 AND parent_id <> 12181; -- 产品信息
UPDATE system_menu SET parent_id = 12181, sort = 5, updater = 'script55', update_time = now() WHERE id = 2317 AND deleted = 0 AND parent_id <> 12181; -- 订货账号列表

-- 公共资料：产品分类 / 产品单位 / 仓库信息 / 结算账户
UPDATE system_menu SET parent_id = 12182, sort = 1, updater = 'script55', update_time = now() WHERE id = 2571 AND deleted = 0 AND parent_id <> 12182; -- 产品分类
UPDATE system_menu SET parent_id = 12182, sort = 2, updater = 'script55', update_time = now() WHERE id = 2577 AND deleted = 0 AND parent_id <> 12182; -- 产品单位
UPDATE system_menu SET parent_id = 12182, sort = 3, updater = 'script55', update_time = now() WHERE id = 2584 AND deleted = 0 AND parent_id <> 12182; -- 仓库信息
UPDATE system_menu SET parent_id = 12182, sort = 4, updater = 'script55', update_time = now() WHERE id = 2646 AND deleted = 0 AND parent_id <> 12182; -- 结算账户

-- ---------------------------------------------------------------------------
-- 3) 授权：把新祖先链补给它已有的角色
--    （yudao 会剔除父菜单未授权的节点，不补祖先角色就看不到迁入的菜单）
-- ---------------------------------------------------------------------------
-- 序列对齐：system_role_menu.id 无默认值，而 system_role_menu_seq 会**落后于 max(id)** ——
-- 前面的脚本（29~51 等）用显式 id 往 system_role_menu 插过行，菜单 id 在 12000+ 区间，
-- 序列却停在 6000 出头（28_fix_all_sequences.sql 只修到那一刻为止）。不对齐就会撞主键。
-- 位置要求：必须放在**整条 WITH ... INSERT 语句之前**，插在 INSERT 前面会把 CTE 拆散。
SELECT setval('system_role_menu_seq', (SELECT COALESCE(MAX(id), 1) FROM system_role_menu), true);
WITH moved(menu_id, new_parent_id) AS (VALUES
        (103, 12181), (2618, 12181), (2603, 12181), (2565, 12181), (2317, 12181),
        (2571, 12182), (2577, 12182), (2584, 12182), (2646, 12182)),
     target AS (SELECT DISTINCT rm.role_id, rm.tenant_id, m.new_parent_id
                  FROM system_role_menu rm JOIN moved m ON m.menu_id = rm.menu_id
                 WHERE rm.deleted = 0),
     want AS (SELECT role_id, tenant_id, new_parent_id AS id FROM target
              UNION SELECT role_id, tenant_id, 12180 FROM target)
-- 序列对齐：system_role_menu.id 无默认值，而 system_role_menu_seq 会**落后于 max(id)** ——
-- 前面的脚本（29~51 等）用显式 id 往 system_role_menu 插过行，菜单 id 在 12000+ 区间，
-- 序列却停在 6000 出头（28_fix_all_sequences.sql 只修到那一刻为止）。不对齐就会撞主键。
SELECT setval('system_role_menu_seq', (SELECT COALESCE(MAX(id), 1) FROM system_role_menu), true);
INSERT INTO system_role_menu (id, role_id, menu_id, creator, create_time, updater, update_time, deleted, tenant_id)
SELECT nextval('system_role_menu_seq'), w.role_id, w.id, 'script55', now(), 'script55', now(), 0, w.tenant_id
FROM want w
WHERE NOT EXISTS (SELECT 1 FROM system_role_menu x
                   WHERE x.deleted = 0 AND x.role_id = w.role_id AND x.menu_id = w.id);

-- ---------------------------------------------------------------------------
-- 4) 序列与自检
-- ---------------------------------------------------------------------------
SELECT setval('system_menu_seq', (SELECT COALESCE(MAX(id), 1) FROM system_menu), true);

SELECT '基础资料下的菜单' AS item,
       COALESCE((SELECT string_agg(m.name || '(' || m.id || ')', ' | ' ORDER BY p.sort, m.sort)
                   FROM system_menu m JOIN system_menu p ON p.id = m.parent_id
                  WHERE m.deleted = 0 AND p.deleted = 0 AND m.parent_id IN (12181, 12182)), '无') AS value
UNION ALL SELECT '新目录已授权角色数',
       (SELECT count(DISTINCT role_id)::text FROM system_role_menu WHERE deleted = 0 AND menu_id = 12180)
UNION ALL SELECT '仍留在原处的两套重复目录（待物料合并）',
       COALESCE((SELECT string_agg(name || '(' || id || ')', ' | ' ORDER BY id)
                   FROM system_menu WHERE deleted = 0 AND id IN (2000, 6210)), '无')
UNION ALL SELECT '菜单序列下一个值（须 > max(id)）',
       (SELECT CASE WHEN (SELECT last_value FROM system_menu_seq) >= (SELECT MAX(id) FROM system_menu) THEN 'OK' ELSE '异常' END);

COMMIT;
