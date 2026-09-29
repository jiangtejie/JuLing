-- ============================================================================
-- 42 把「订货账号」菜单挪到「商城系统」下
--
-- 业务理由：订货账号 = 门店/代理人的订货身份（谁能下单、以哪家门店下单、订单归属哪家店），
--   与「订单中心 / 订单工作台 / 门店收货单」是同一条订货链上的不同环节，
--   使用者是总部运营/供应链而不是 IT，理应和它们在同一棵树下。
--   （独立顶层入口是 41 脚本为修「菜单孤儿」临时给的，现在归位。）
--
-- 做法：把目录 12140 的 parent_id 从 0 改成 2362（商城系统），path 改为相对段 order-account；
--   再给「已授 12140 但没授商城系统」的角色补上商城系统及其祖先链
--   （yudao 会剔除「父菜单未授权」的节点，只授子不授父等于看不见）。
--
-- 幂等：可重复执行。
-- ============================================================================

BEGIN;

UPDATE system_menu
SET parent_id = 2362,
    path = 'order-account',
    sort = 62,
    updater = 'script42',
    update_time = now()
WHERE id = 12140 AND deleted = 0;

-- 给已授 12140 的角色补商城系统与其祖先链
WITH RECURSIVE need AS (
    SELECT id, parent_id FROM system_menu WHERE id = 2362 AND deleted = 0
    UNION ALL
    SELECT m.id, m.parent_id FROM system_menu m JOIN need n ON m.id = n.parent_id WHERE m.deleted = 0
)
INSERT INTO system_role_menu (id, role_id, menu_id, creator, create_time, updater, update_time, deleted, tenant_id)
SELECT nextval('system_role_menu_seq'), rm.role_id, n.id, 'script42', now(), 'script42', now(), 0, rm.tenant_id
FROM (SELECT DISTINCT role_id, tenant_id FROM system_role_menu WHERE deleted = 0 AND menu_id = 12140) rm
CROSS JOIN need n
WHERE NOT EXISTS (SELECT 1 FROM system_role_menu x
                   WHERE x.deleted = 0 AND x.role_id = rm.role_id AND x.menu_id = n.id);

-- 自检
SELECT '商城系统下的订货账号' AS item,
       (SELECT parent_id || ' / ' || path || ' / sort=' || sort FROM system_menu WHERE id = 12140) AS value
UNION ALL
SELECT '顶层是否还有订货账号',
       COALESCE((SELECT count(*)::text FROM system_menu WHERE deleted = 0 AND parent_id = 0 AND id = 12140), '0')
UNION ALL
SELECT '已授 12140 的角色数',
       (SELECT count(DISTINCT role_id)::text FROM system_role_menu WHERE deleted = 0 AND menu_id = 12140)
UNION ALL
SELECT '这些角色里没授商城系统的',
       COALESCE((SELECT string_agg(DISTINCT role_id::text, ', ') FROM system_role_menu
                  WHERE deleted = 0 AND menu_id = 12140
                    AND role_id NOT IN (SELECT role_id FROM system_role_menu WHERE deleted = 0 AND menu_id = 2362)), '无');

COMMIT;
