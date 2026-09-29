-- ============================================================================
-- 51 订货账号列表：补「删除」「停用/启用」两个按钮权限
--
-- 背景：订货账号（member_user）列表此前只有「开账号 / 重置密码 / 更新」，缺删除与停用。
--   后端已补 DELETE /member/user/delete 与 PUT /member/user/update-status
--   （停用后无法登录，历史订单与台账仍可追溯；已绑定门店/部门的账号拒绝删除，引导改用停用）。
--
-- 做法：在「订货账号列表」(2317) 下补两个按钮权限，并授给已经拥有该列表的角色（含祖先链）。
-- 幂等：可重复执行。
-- ============================================================================

BEGIN;

INSERT INTO system_menu (id, name, permission, type, sort, parent_id, path, icon, component, component_name,
                         status, visible, keep_alive, always_show, creator, create_time, updater, update_time, deleted)
SELECT v.id, v.name, v.perm, 3, v.sort, 2317, '', '', NULL, NULL,
       0, true, true, true, 'script51', now(), 'script51', now(), 0
FROM (VALUES (12160, '删除订货账号', 'member:user:delete', 5),
             (12161, '停用/启用订货账号', 'member:user:update-status', 6)) AS v(id, name, perm, sort)
WHERE EXISTS (SELECT 1 FROM system_menu WHERE id = 2317 AND deleted = 0)
  AND NOT EXISTS (SELECT 1 FROM system_menu WHERE id = v.id);

-- 授给已有「订货账号列表」的角色，并补祖先链（yudao 会剔除父菜单未授权的节点）
WITH RECURSIVE need AS (
    SELECT id, parent_id FROM system_menu WHERE id = 2317 AND deleted = 0
    UNION ALL
    SELECT m.id, m.parent_id FROM system_menu m JOIN need n ON m.id = n.parent_id WHERE m.deleted = 0
), target_role AS (
    SELECT DISTINCT rm.role_id, rm.tenant_id FROM system_role_menu rm
    WHERE rm.deleted = 0 AND rm.menu_id = 2317
), want AS (
    SELECT id FROM need UNION ALL SELECT 12160 UNION ALL SELECT 12161
)
INSERT INTO system_role_menu (id, role_id, menu_id, creator, create_time, updater, update_time, deleted, tenant_id)
SELECT nextval('system_role_menu_seq'), t.role_id, w.id, 'script51', now(), 'script51', now(), 0, t.tenant_id
FROM target_role t CROSS JOIN want w
WHERE NOT EXISTS (SELECT 1 FROM system_role_menu x
                   WHERE x.deleted = 0 AND x.role_id = t.role_id AND x.menu_id = w.id);

-- 推进菜单序列（补丁用显式 id 插入会让序列滞后）
SELECT setval('system_menu_seq', (SELECT COALESCE(MAX(id), 1) FROM system_menu), true);

-- 自检
SELECT '新增按钮权限' AS item,
       (SELECT string_agg(id || ':' || permission, ', ' ORDER BY id) FROM system_menu WHERE id IN (12160, 12161)) AS value
UNION ALL
SELECT '已授角色',
       COALESCE((SELECT string_agg(DISTINCT r.name || '(' || r.id || ')', ', ')
                 FROM system_role_menu rm JOIN system_role r ON r.id = rm.role_id
                 WHERE rm.deleted = 0 AND rm.menu_id IN (12160, 12161)), '无')
UNION ALL
SELECT '菜单序列下一个值（须 > max(id)）',
       (SELECT CASE WHEN (SELECT last_value FROM system_menu_seq) >= (SELECT MAX(id) FROM system_menu) THEN 'OK' ELSE '异常' END);

COMMIT;
