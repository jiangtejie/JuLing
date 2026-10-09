-- ============================================================================
-- 46 补「会员统计」查询权限（商城首页的会员统计卡片在用）
--
-- 背景：40 脚本按产品决策删掉「会员中心 / 会员统计」页面时，把 `statistics:member:query`
--   这条权限一并删了；但「商城首页」（mall/home）的会员统计卡片仍在调用
--   /admin-api/statistics/member/{summary,analyse,area-statistics-list,sex-statistics-list,
--   terminal-statistics-list,user-count-comparison,register-count-list} 这 7 个接口
--   （代码已随 9f47cebd 之后的修复恢复），却没有任何菜单承载这条权限，
--   于是除超级管理员外调用都会 403。这里补一条**隐藏按钮权限**（独立页面不恢复，
--   因为「会员统计」页面已按产品决策下线），并授给已经在看「交易统计」的角色。
--
-- 幂等：可重复执行。
-- ============================================================================

BEGIN;

-- 1) 隐藏按钮权限：统计中心(2358) → 会员统计查询
INSERT INTO system_menu (id, name, permission, type, sort, parent_id, path, icon, component, component_name,
                         status, visible, keep_alive, always_show, creator, create_time, updater, update_time, deleted)
SELECT 12150, '会员统计查询', 'statistics:member:query', 3, 3, 2358, '', '', NULL, NULL,
       0, true, true, true, 'script46', now(), 'script46', now(), 0
WHERE NOT EXISTS (SELECT 1 FROM system_menu WHERE id = 12150);

-- 2) 授给「已有交易统计查询权限」的角色，并补祖先链
--    （yudao 会剔除「父菜单未授权」的节点，只授子不授父等于看不见）
WITH RECURSIVE need AS (
    SELECT id, parent_id FROM system_menu WHERE id = 2358 AND deleted = 0
    UNION ALL
    SELECT m.id, m.parent_id FROM system_menu m JOIN need n ON m.id = n.parent_id WHERE m.deleted = 0
), target_role AS (
    SELECT DISTINCT rm.role_id, rm.tenant_id
    FROM system_role_menu rm
    WHERE rm.deleted = 0
      AND rm.menu_id IN (SELECT id FROM system_menu WHERE deleted = 0 AND permission = 'statistics:trade:query')
), want AS (
    SELECT id FROM need UNION ALL SELECT 12150
)
INSERT INTO system_role_menu (id, role_id, menu_id, creator, create_time, updater, update_time, deleted, tenant_id)
SELECT nextval('system_role_menu_seq'), t.role_id, w.id, 'script46', now(), 'script46', now(), 0, t.tenant_id
FROM target_role t CROSS JOIN want w
WHERE NOT EXISTS (SELECT 1 FROM system_role_menu x
                   WHERE x.deleted = 0 AND x.role_id = t.role_id AND x.menu_id = w.id);

-- 3) 推进菜单序列（补丁用显式 id 插入，序列会滞后；界面新增菜单会报 duplicate key）
SELECT setval('system_menu_seq', (SELECT COALESCE(MAX(id), 1) FROM system_menu), true);

-- 4) 自检
SELECT '会员统计权限菜单' AS item,
       (SELECT id || ' / ' || name || ' / ' || permission || ' / parent=' || parent_id
        FROM system_menu WHERE id = 12150) AS value
UNION ALL
SELECT '已授该权限的角色',
       COALESCE((SELECT string_agg(DISTINCT r.name || '(' || r.id || ')', ', ')
                 FROM system_role_menu rm JOIN system_role r ON r.id = rm.role_id
                 WHERE rm.deleted = 0 AND rm.menu_id = 12150), '无')
UNION ALL
SELECT 'system_menu_seq 下一个值',
       (SELECT nextval('system_menu_seq')::text)
UNION ALL
SELECT '菜单序列回退检查（下一个值须 > max(id)）',
       (SELECT CASE WHEN (SELECT last_value FROM system_menu_seq) > (SELECT MAX(id) FROM system_menu)
                    THEN 'OK' ELSE '异常' END);

COMMIT;
