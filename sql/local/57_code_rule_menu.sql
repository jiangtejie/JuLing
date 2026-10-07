-- ============================================================================
-- 57 编码规则菜单：把「基础资料 → 编码规则」补进后台
--
-- 背景：56 号脚本建了 system_code_rule（编码规则表）并给 6 个主数据发了 code，
--   但规则本身没有维护入口 —— 管理员看不到前缀/流水，也没法为新主数据加规则。
--   本脚本补菜单与权限（对齐金蝶「基础资料 → 编码规则」的位置）。
--
-- 幂等：可重复执行。
-- ============================================================================

BEGIN;

-- ---------------------------------------------------------------------------
-- 1) 菜单：挂在一级目录「基础资料」(12180) 下
-- ---------------------------------------------------------------------------
INSERT INTO system_menu (id, name, permission, type, sort, parent_id, path, icon, component, component_name,
                         status, visible, keep_alive, always_show, creator, create_time, updater, update_time, deleted)
SELECT 12190, '编码规则', '', 2, 3, 12180, 'code-rule', 'lucide:hash', 'system/code-rule/index', 'SystemCodeRule',
       0, true, true, true, 'script57', now(), 'script57', now(), 0
WHERE EXISTS (SELECT 1 FROM system_menu WHERE id = 12180 AND deleted = 0)
  AND NOT EXISTS (SELECT 1 FROM system_menu WHERE id = 12190);

-- ---------------------------------------------------------------------------
-- 2) 按钮权限
-- ---------------------------------------------------------------------------
INSERT INTO system_menu (id, name, permission, type, sort, parent_id, path, icon, component, component_name,
                         status, visible, keep_alive, always_show, creator, create_time, updater, update_time, deleted)
SELECT v.id, v.name, v.perm, 3, v.sort, 12190, '', '', NULL, NULL,
       0, true, true, true, 'script57', now(), 'script57', now(), 0
FROM (VALUES (12191, '编码规则查询', 'system:code-rule:query',  1),
             (12192, '编码规则新增', 'system:code-rule:create', 2),
             (12193, '编码规则修改', 'system:code-rule:update', 3),
             (12194, '编码规则删除', 'system:code-rule:delete', 4)) AS v(id, name, perm, sort)
WHERE EXISTS (SELECT 1 FROM system_menu WHERE id = 12190 AND deleted = 0)
  AND NOT EXISTS (SELECT 1 FROM system_menu WHERE id = v.id);

-- ---------------------------------------------------------------------------
-- 3) 授权：授给已拥有「基础资料」的角色，并补祖先链
-- ---------------------------------------------------------------------------
WITH RECURSIVE need AS (
    SELECT id, parent_id FROM system_menu WHERE id = 12190 AND deleted = 0
    UNION ALL
    SELECT m.id, m.parent_id FROM system_menu m JOIN need n ON m.id = n.parent_id WHERE m.deleted = 0
), target_role AS (
    SELECT DISTINCT rm.role_id, rm.tenant_id FROM system_role_menu rm
    WHERE rm.deleted = 0 AND rm.menu_id = 12180
), want AS (
    SELECT id FROM need UNION ALL SELECT 12191 UNION ALL SELECT 12192 UNION ALL SELECT 12193 UNION ALL SELECT 12194
)
INSERT INTO system_role_menu (id, role_id, menu_id, creator, create_time, updater, update_time, deleted, tenant_id)
SELECT nextval('system_role_menu_seq'), t.role_id, w.id, 'script57', now(), 'script57', now(), 0, t.tenant_id
FROM target_role t CROSS JOIN want w
WHERE NOT EXISTS (SELECT 1 FROM system_role_menu x
                   WHERE x.deleted = 0 AND x.role_id = t.role_id AND x.menu_id = w.id);

-- ---------------------------------------------------------------------------
-- 4) 序列与自检
-- ---------------------------------------------------------------------------
SELECT setval('system_menu_seq', (SELECT COALESCE(MAX(id), 1) FROM system_menu), true);

SELECT '菜单与按钮' AS item,
       COALESCE((SELECT string_agg(id || ':' || name, ' | ' ORDER BY id) FROM system_menu
                  WHERE deleted = 0 AND id IN (12190, 12191, 12192, 12193, 12194)), '无') AS value
UNION ALL SELECT '已授角色数',
       (SELECT count(DISTINCT role_id)::text FROM system_role_menu WHERE deleted = 0 AND menu_id = 12190)
UNION ALL SELECT '编码规则条数', (SELECT count(*)::text FROM system_code_rule WHERE deleted = 0)
UNION ALL SELECT '菜单序列下一个值（须 > max(id)）',
       (SELECT CASE WHEN (SELECT last_value FROM system_menu_seq) >= (SELECT MAX(id) FROM system_menu) THEN 'OK' ELSE '异常' END);

COMMIT;
