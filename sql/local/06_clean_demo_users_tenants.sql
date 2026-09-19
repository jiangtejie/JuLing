-- 清理演示账号与演示租户（保留 system_users.id = 1 的 admin 与租户 1 棱信矩灵）
BEGIN;

-- 1) 演示账号：仅保留 id = 1
DELETE FROM system_user_role WHERE user_id <> 1;
DELETE FROM system_users WHERE id <> 1;

-- 2) 演示租户 121(小租户)、122(测试租户) 及其名下系统数据
DELETE FROM system_role_menu WHERE tenant_id IN (121, 122);
DELETE FROM system_user_role WHERE tenant_id IN (121, 122);
DELETE FROM system_users     WHERE tenant_id IN (121, 122);
DELETE FROM system_role      WHERE tenant_id IN (121, 122);
DELETE FROM system_dept      WHERE tenant_id IN (121, 122);
DELETE FROM system_social_client WHERE tenant_id IN (121, 122);
DELETE FROM system_tenant    WHERE id IN (121, 122);

COMMIT;

\echo '--- 剩余用户 ---'
SELECT id, username, nickname, tenant_id, status FROM system_users ORDER BY id;
\echo '--- 剩余租户 ---'
SELECT id, name, status FROM system_tenant ORDER BY id;
