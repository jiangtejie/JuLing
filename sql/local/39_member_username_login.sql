-- ============================================================================
-- 39 订货账号（会员登录名）+ 后台开账号 / 重置密码权限
--
-- 背景：私域订货 H5 不开放给 C 端，加盟客户原本就是"开一个订货账号"，用「名字 + 密码」登录。
--   之前 member_user 只有手机号一个身份键，且 3 个订货账号的密码是空的 → 根本登不进去。
--
-- 口径：
--   · username 是**独立列**，不复用 mobile —— mobile 在会员体系里是身份键
--     （短信登录 / 社交绑定 / createUserIfAbsent 都按它找人），复用会破坏语义；
--   · 登录：先按 username 找，找不到再按 mobile 找（兼容历史账号）；
--   · mobile 改为可选（列本来就是 nullable），后台开账号时可不填。
--
-- 幂等：可重复执行。
-- ============================================================================

ALTER TABLE member_user ADD COLUMN IF NOT EXISTS username varchar(64);
COMMENT ON COLUMN member_user.username IS '订货账号（私域加盟客户的登录名，通常就是门店名；唯一）';

CREATE UNIQUE INDEX IF NOT EXISTS uk_member_user_username
    ON member_user (username) WHERE deleted = 0 AND username IS NOT NULL;

-- 回填 1：绑了门店的会员，账号名 = 门店名（去掉「（门店）」后缀），更符合"用名字登录"的习惯
UPDATE member_user u
SET username = replace(c.name, '（门店）', '')
FROM erp_customer c
WHERE u.deleted = 0
  AND u.username IS NULL
  AND u.customer_id = c.id
  AND c.deleted = 0
  AND c.name IS NOT NULL
  AND c.name <> ''
  AND NOT EXISTS (SELECT 1 FROM member_user u2
                   WHERE u2.deleted = 0 AND u2.username = replace(c.name, '（门店）', ''));

-- 回填 2：其余账号用手机号兜底（保证每个历史账号都能用账号名登录）
UPDATE member_user u
SET username = u.mobile
WHERE u.deleted = 0
  AND u.username IS NULL
  AND u.mobile IS NOT NULL
  AND u.mobile <> ''
  AND NOT EXISTS (SELECT 1 FROM member_user u2
                   WHERE u2.deleted = 0 AND u2.id <> u.id AND u2.username = u.mobile);

-- ---------------------------------------------------------------------------
-- 菜单与权限：会员管理（2317）下新增「开订货账号」「重置密码」
-- ---------------------------------------------------------------------------
INSERT INTO system_menu (id, name, permission, type, sort, parent_id, path, icon, component, component_name,
                         status, visible, keep_alive, always_show, creator, create_time, updater, update_time, deleted)
SELECT v.id, v.name, v.permission, 3, v.sort, 2317, '', '', '', '', 0, true, true, true,
       'script39', now(), 'script39', now(), 0
FROM (VALUES (12130, '开订货账号', 'member:user:create', 4),
             (12131, '重置订货账号密码', 'member:user:reset-password', 5)
     ) AS v(id, name, permission, sort)
WHERE NOT EXISTS (SELECT 1 FROM system_menu WHERE id = v.id);

-- 授给已经拥有「会员管理」父菜单的角色 + 补祖先链
INSERT INTO system_role_menu (id, role_id, menu_id, creator, create_time, updater, update_time, deleted, tenant_id)
SELECT nextval('system_role_menu_seq'), rm.role_id, m.id, 'script39', now(), 'script39', now(), 0, rm.tenant_id
FROM (SELECT DISTINCT role_id, tenant_id FROM system_role_menu WHERE deleted = 0 AND menu_id = 2317) rm
CROSS JOIN (SELECT 12130 AS id UNION ALL SELECT 12131) m
WHERE NOT EXISTS (SELECT 1 FROM system_role_menu x
                   WHERE x.deleted = 0 AND x.role_id = rm.role_id AND x.menu_id = m.id);

WITH RECURSIVE need AS (
    SELECT id, parent_id FROM system_menu WHERE id IN (12130, 12131) AND deleted = 0
    UNION ALL
    SELECT m.id, m.parent_id FROM system_menu m JOIN need n ON m.id = n.parent_id WHERE m.deleted = 0
)
INSERT INTO system_role_menu (id, role_id, menu_id, creator, create_time, updater, update_time, deleted, tenant_id)
SELECT nextval('system_role_menu_seq'), rm.role_id, n.id, 'script39', now(), 'script39', now(), 0, rm.tenant_id
FROM (SELECT DISTINCT role_id, tenant_id FROM system_role_menu WHERE deleted = 0 AND menu_id IN (12130, 12131)) rm
CROSS JOIN need n
WHERE NOT EXISTS (SELECT 1 FROM system_role_menu x
                   WHERE x.deleted = 0 AND x.role_id = rm.role_id AND x.menu_id = n.id);

-- ---------------------------------------------------------------------------
-- 自检
-- ---------------------------------------------------------------------------
SELECT id, username, COALESCE(mobile, '(无手机号)') AS mobile, nickname,
       CASE WHEN password IS NULL OR password = '' THEN '密码为空' ELSE '已设密码' END AS password_state,
       COALESCE(customer_id::text, '(未绑门店)') AS customer_id
FROM member_user WHERE deleted = 0 ORDER BY id;
