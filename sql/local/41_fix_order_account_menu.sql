-- ============================================================================
-- 41 修复「订货账号」菜单的挂载点
--
-- 问题（40 脚本引入）：40 删掉了「会员中心」(2262) 顶层菜单，但保留了它的子菜单
-- 「会员管理」(2317) 子树 —— 2317 的 parent_id 仍指向已删除的 2262，于是变成孤儿节点，
-- 菜单树构建时够不到它，**后台侧边栏里根本看不到「订货账号」**。
--
-- 修法：补一个顶层目录「订货账号」(12140) 作为它的家，把 2317 挂进去并改名「订货账号列表」，
-- 与原「会员中心」保持同样的顶层可见度（挨着「商城系统」），并把目录授给已有 2317 的角色。
--
-- 幂等：可重复执行。
-- ============================================================================

BEGIN;

-- 1. 顶层目录「订货账号」
INSERT INTO system_menu (id, name, permission, type, sort, parent_id, path, icon, component, component_name,
                         status, visible, keep_alive, always_show, creator, create_time, updater, update_time, deleted)
SELECT 12140, '订货账号', '', 1, 60, 0, '/order-account', 'lucide:key-round', NULL, NULL,
       0, true, true, true, 'script41', now(), 'script41', now(), 0
WHERE NOT EXISTS (SELECT 1 FROM system_menu WHERE id = 12140);

-- 2. 把 2317 挂到新目录下（并明确它是一张列表页）
UPDATE system_menu
SET parent_id = 12140, name = '订货账号列表', icon = 'lucide:users',
    updater = 'script41', update_time = now()
WHERE id = 2317 AND deleted = 0;

-- 2.1 顺带清掉 2317 下面的两个残留按钮权限（指向已删除的等级/积分能力）
DELETE FROM system_role_menu WHERE menu_id IN (2335, 2363);
DELETE FROM system_menu WHERE id IN (2335, 2363);

-- 3. 授权：凡是已有 2317 的角色，一并授予新目录
INSERT INTO system_role_menu (id, role_id, menu_id, creator, create_time, updater, update_time, deleted, tenant_id)
SELECT nextval('system_role_menu_seq'), rm.role_id, 12140, 'script41', now(), 'script41', now(), 0, rm.tenant_id
FROM (SELECT DISTINCT role_id, tenant_id FROM system_role_menu WHERE deleted = 0 AND menu_id = 2317) rm
WHERE NOT EXISTS (SELECT 1 FROM system_role_menu x
                   WHERE x.deleted = 0 AND x.role_id = rm.role_id AND x.menu_id = 12140);

-- 4. 补齐祖先链（yudao 会剔除「父菜单未授权」的节点）
WITH RECURSIVE need AS (
    SELECT id, parent_id FROM system_menu WHERE id IN (12140, 2317) AND deleted = 0
    UNION ALL
    SELECT m.id, m.parent_id FROM system_menu m JOIN need n ON m.id = n.parent_id WHERE m.deleted = 0
)
INSERT INTO system_role_menu (id, role_id, menu_id, creator, create_time, updater, update_time, deleted, tenant_id)
SELECT nextval('system_role_menu_seq'), rm.role_id, n.id, 'script41', now(), 'script41', now(), 0, rm.tenant_id
FROM (SELECT DISTINCT role_id, tenant_id FROM system_role_menu WHERE deleted = 0 AND menu_id IN (12140, 2317)) rm
CROSS JOIN need n
WHERE NOT EXISTS (SELECT 1 FROM system_role_menu x
                   WHERE x.deleted = 0 AND x.role_id = rm.role_id AND x.menu_id = n.id);

-- 5. 自检
SELECT '订货账号菜单树' AS item,
       string_agg(id || ':' || name || '(parent=' || parent_id || ')', '  →  ' ORDER BY id) AS value
FROM system_menu WHERE deleted = 0 AND id IN (12140, 2317, 2318, 2319, 12130, 12131)
UNION ALL
SELECT '孤儿菜单数（应为 0，1150 是历史遗留）',
       COALESCE(string_agg(c.id || ':' || c.name, ', '), '0')
FROM system_menu c LEFT JOIN system_menu p ON p.id = c.parent_id AND p.deleted = 0
WHERE c.deleted = 0 AND c.parent_id <> 0 AND p.id IS NULL;

COMMIT;
