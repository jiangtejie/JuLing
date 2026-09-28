-- =============================================================================
-- 合并「亚特餐饮(123)」历史租户到「亚特(1)」，并清除 tenant_id=0 的全局残留
--
-- 背景：
--   线上库曾有第二个租户 亚特餐饮(tenant_id=123)，是早期切租户测试时产生的历史脏数据，
--   但里面装着**真实组织结构**（萍姐/卤校长/直营门店/中心库 及下属公司、职能部门、13 家门店，
--   共 47 个部门）、三个业务账号（贺玲/张新宇/谢欣然）与两个供应链岗位。
--   亚特(1) 反而是 yudao 演示部门 + 全部业务数据。本次按「转换为亚特缺失的，其余清除」处理。
--
-- 内容：
--   0) 先把受影响的行备份到 schema bak_tenant123_20260928（可整表还原）
--   1) 转换：47 个部门 -> 租户 1（id 119-165 与亚特 100-118/166-169 不冲突，故不改 id，
--      既有业务引用如 erp_customer.dept_id 继续有效）
--   2) 转换：岗位「供应链物配主管 gyl_wpzg」「供应链物配文员 gyl_wpwy」-> 租户 1；
--      「供应链采购文员 gyl_cg」亚特已有同名(gylcgwy) -> 删除
--   3) 转换：账号 heling(贺玲)/zhangxinyu(张新宇) -> 租户 1；
--      xiexinran(谢欣然) 亚特已有(id 152) 故删除 123 的重复号；123 的默认 admin 删除
--   4) 转换：岗位绑定随人迁移，并给两个账号绑亚特的「供应链 gyl」角色（他们在 123 里无任何角色）
--   5) 清除：123 的角色菜单(221)/用户角色/账号/角色/操作日志、重复的「荤菜」分类与「无」品牌
--   6) 清除：tenant_id=0 的 infra_api_error_log / system_sms_code / 孤儿 system_role_menu
--   7) 清除：租户本体 system_tenant(123) 与其套餐 system_tenant_package(111)
--
-- 幂等：可重复执行（第二次执行各步影响 0 行）。
-- 执行：psql -U root -d yate -f sql/local/27_merge_tenant123_into_yate.sql
-- 回滚：受影响行全部在 schema bak_tenant123_20260928 中（见脚本末尾还原示例）
-- =============================================================================

-- ---------- 0) 备份（已存在则跳过） ----------
CREATE SCHEMA IF NOT EXISTS bak_tenant123_20260928;
CREATE TABLE IF NOT EXISTS bak_tenant123_20260928.system_users          AS SELECT * FROM system_users          WHERE tenant_id = 123;
CREATE TABLE IF NOT EXISTS bak_tenant123_20260928.system_dept           AS SELECT * FROM system_dept           WHERE tenant_id = 123;
CREATE TABLE IF NOT EXISTS bak_tenant123_20260928.system_post           AS SELECT * FROM system_post           WHERE tenant_id = 123;
CREATE TABLE IF NOT EXISTS bak_tenant123_20260928.system_role           AS SELECT * FROM system_role           WHERE tenant_id = 123;
CREATE TABLE IF NOT EXISTS bak_tenant123_20260928.system_role_menu      AS SELECT * FROM system_role_menu      WHERE tenant_id IN (0, 123);
CREATE TABLE IF NOT EXISTS bak_tenant123_20260928.system_user_role      AS SELECT * FROM system_user_role      WHERE tenant_id = 123;
CREATE TABLE IF NOT EXISTS bak_tenant123_20260928.system_user_post      AS SELECT * FROM system_user_post      WHERE tenant_id = 123;
CREATE TABLE IF NOT EXISTS bak_tenant123_20260928.system_operate_log    AS SELECT * FROM system_operate_log    WHERE tenant_id = 123;
CREATE TABLE IF NOT EXISTS bak_tenant123_20260928.product_category      AS SELECT * FROM product_category      WHERE tenant_id = 123;
CREATE TABLE IF NOT EXISTS bak_tenant123_20260928.product_brand         AS SELECT * FROM product_brand         WHERE tenant_id = 123;
CREATE TABLE IF NOT EXISTS bak_tenant123_20260928.infra_api_error_log   AS SELECT * FROM infra_api_error_log   WHERE tenant_id = 0;
CREATE TABLE IF NOT EXISTS bak_tenant123_20260928.system_sms_code       AS SELECT * FROM system_sms_code       WHERE tenant_id = 0;
CREATE TABLE IF NOT EXISTS bak_tenant123_20260928.system_tenant         AS SELECT * FROM system_tenant         WHERE id = 123;
CREATE TABLE IF NOT EXISTS bak_tenant123_20260928.system_tenant_package AS SELECT * FROM system_tenant_package WHERE id = 111;

BEGIN;

-- ---------- 1) 组织树 ----------
UPDATE system_dept SET tenant_id = 1, updater = '1', update_time = now() WHERE tenant_id = 123;

-- ---------- 2) 岗位 ----------
UPDATE system_post SET tenant_id = 1, updater = '1', update_time = now()
 WHERE tenant_id = 123 AND code IN ('gyl_wpzg', 'gyl_wpwy');
DELETE FROM system_post WHERE tenant_id = 123;

-- ---------- 3) 账号 ----------
UPDATE system_users SET tenant_id = 1, updater = '1', update_time = now()
 WHERE tenant_id = 123 AND username IN ('heling', 'zhangxinyu');

-- ---------- 4) 绑定 ----------
UPDATE system_user_post SET tenant_id = 1, updater = '1', update_time = now()
 WHERE tenant_id = 123 AND user_id IN (SELECT id FROM system_users WHERE tenant_id = 1 AND username IN ('heling', 'zhangxinyu'));
DELETE FROM system_user_post WHERE tenant_id = 123;
-- 绑亚特的「供应链 gyl」角色（亚特该角色 id=157；不存在则跳过）
INSERT INTO system_user_role (id, user_id, role_id, creator, create_time, updater, update_time, deleted, tenant_id)
SELECT (SELECT COALESCE(MAX(id), 0) FROM system_user_role) + row_number() OVER (), u.id, r.id, '1', now(), '1', now(), 0, 1
FROM system_users u
CROSS JOIN (SELECT id FROM system_role WHERE tenant_id = 1 AND code = 'gyl') r
WHERE u.tenant_id = 1 AND u.username IN ('heling', 'zhangxinyu')
  AND NOT EXISTS (SELECT 1 FROM system_user_role ur WHERE ur.user_id = u.id AND ur.role_id = r.id);

-- ---------- 5) 清 123 剩余 ----------
DELETE FROM system_role_menu   WHERE tenant_id = 123;
DELETE FROM system_user_role   WHERE tenant_id = 123;
DELETE FROM system_users       WHERE tenant_id = 123;
DELETE FROM system_role        WHERE tenant_id = 123;
DELETE FROM system_operate_log WHERE tenant_id = 123;
DELETE FROM product_category   WHERE tenant_id = 123;   -- 重复：亚特已有「荤菜」(id=4)
DELETE FROM product_brand      WHERE tenant_id = 123;   -- 重复：亚特已有「亚特品牌」(id=2)

-- ---------- 6) tenant_id = 0 全局残留 ----------
DELETE FROM infra_api_error_log WHERE tenant_id = 0;
DELETE FROM system_sms_code     WHERE tenant_id = 0;
DELETE FROM system_role_menu    WHERE tenant_id = 0;

-- ---------- 7) 租户本体 ----------
DELETE FROM system_tenant         WHERE id = 123;
DELETE FROM system_tenant_package WHERE id = 111;

COMMIT;

-- 复核：以下查询应返回 0 行
--   SELECT count(*) FROM system_users WHERE tenant_id <> 1;
--   SELECT count(*) FROM system_dept  WHERE tenant_id <> 1;
--   SELECT count(*) FROM system_tenant WHERE id <> 1;

-- 回滚示例（按需）：
--   UPDATE system_dept  d SET tenant_id = 123 FROM bak_tenant123_20260928.system_dept  b WHERE d.id = b.id;
--   UPDATE system_users u SET tenant_id = 123 FROM bak_tenant123_20260928.system_users b WHERE u.id = b.id;
--   INSERT INTO system_users        SELECT * FROM bak_tenant123_20260928.system_users        ON CONFLICT (id) DO NOTHING;
--   INSERT INTO system_role         SELECT * FROM bak_tenant123_20260928.system_role         ON CONFLICT (id) DO NOTHING;
--   INSERT INTO system_role_menu    SELECT * FROM bak_tenant123_20260928.system_role_menu    ON CONFLICT (id) DO NOTHING;
--   INSERT INTO system_tenant       SELECT * FROM bak_tenant123_20260928.system_tenant       ON CONFLICT (id) DO NOTHING;
--   INSERT INTO system_tenant_package SELECT * FROM bak_tenant123_20260928.system_tenant_package ON CONFLICT (id) DO NOTHING;
