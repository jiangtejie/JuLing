-- ============================================================================
-- 44 清理全局遗留：已下线的支付/钱包归档表 + 无人使用的种子角色
--
-- 背景（全局盘点结果）：
--   1) 支付/钱包模块下线时，14 张表被重命名为 zz_deprecated_pay_* 归档（当时备注"确认无误后再 DROP"）。
--      现在的业务是「线下转账 + 财务核验」，支付单/钱包/充值一条链路都不存在了，代码里零引用，
--      唯一有数据的是 zz_deprecated_pay_wallet（21 行历史余额）——备份后即可清除。
--   2) 种子角色「CRM 管理员」(crm_admin) 挂着 0 个用户，它给 MES 等模块的授权是死授权。
--      （「普通角色」虽然也挂着管理员，但它至少绑着真实用户，本轮不动。）
--
-- 幂等：可重复执行；整个脚本包在事务里。
-- ============================================================================

BEGIN;

-- ---------------------------------------------------------------------------
-- 1. 备份并删除 14 张归档表
-- ---------------------------------------------------------------------------
DO $$
DECLARE
    bak text := 'bak_pay_archive_20260929';
    i   text;
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.schemata WHERE schema_name = bak) THEN
        RAISE NOTICE '备份 schema % 已存在，跳过备份', bak;
    ELSE
        EXECUTE format('CREATE SCHEMA %I', bak);
        FOR i IN SELECT table_name FROM information_schema.tables
                  WHERE table_schema='public' AND table_name LIKE 'zz_deprecated_pay_%'
        LOOP
            EXECUTE format('CREATE TABLE %I.%I AS SELECT * FROM public.%I', bak, i, i);
        END LOOP;
        RAISE NOTICE '已备份归档表到 schema %', bak;
    END IF;
END $$;

DROP TABLE IF EXISTS zz_deprecated_pay_app CASCADE;
DROP TABLE IF EXISTS zz_deprecated_pay_channel CASCADE;
DROP TABLE IF EXISTS zz_deprecated_pay_demo_order CASCADE;
DROP TABLE IF EXISTS zz_deprecated_pay_demo_withdraw CASCADE;
DROP TABLE IF EXISTS zz_deprecated_pay_notify_log CASCADE;
DROP TABLE IF EXISTS zz_deprecated_pay_notify_task CASCADE;
DROP TABLE IF EXISTS zz_deprecated_pay_order CASCADE;
DROP TABLE IF EXISTS zz_deprecated_pay_order_extension CASCADE;
DROP TABLE IF EXISTS zz_deprecated_pay_refund CASCADE;
DROP TABLE IF EXISTS zz_deprecated_pay_transfer CASCADE;
DROP TABLE IF EXISTS zz_deprecated_pay_wallet CASCADE;
DROP TABLE IF EXISTS zz_deprecated_pay_wallet_recharge CASCADE;
DROP TABLE IF EXISTS zz_deprecated_pay_wallet_recharge_package CASCADE;
DROP TABLE IF EXISTS zz_deprecated_pay_wallet_transaction CASCADE;

-- ---------------------------------------------------------------------------
-- 2. 删除 0 用户的种子角色「CRM 管理员」
-- ---------------------------------------------------------------------------
DELETE FROM system_role_menu
WHERE role_id IN (SELECT id FROM system_role WHERE code = 'crm_admin' AND deleted = 0)
  AND NOT EXISTS (SELECT 1 FROM system_user_role ur WHERE ur.role_id = system_role_menu.role_id AND ur.deleted = 0);
DELETE FROM system_role
WHERE code = 'crm_admin' AND deleted = 0
  AND NOT EXISTS (SELECT 1 FROM system_user_role ur WHERE ur.role_id = system_role.id AND ur.deleted = 0);

-- ---------------------------------------------------------------------------
-- 3. 自检
-- ---------------------------------------------------------------------------
SELECT '剩余 zz_ 归档表' AS item, COALESCE(string_agg(table_name, ', ' ORDER BY table_name), '(无)') AS value
FROM information_schema.tables WHERE table_schema='public' AND table_name LIKE 'zz_%'
UNION ALL
SELECT '剩余角色', COALESCE(string_agg(r.name || '(' || COALESCE(u.c,0) || '人)', ', ' ORDER BY r.id), '(无)')
FROM system_role r
LEFT JOIN (SELECT role_id, count(*) c FROM system_user_role WHERE deleted=0 GROUP BY 1) u ON u.role_id = r.id
WHERE r.deleted = 0
UNION ALL
SELECT '归档备份表数', count(*)::text
FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
WHERE n.nspname='bak_pay_archive_20260929' AND c.relkind='r';

COMMIT;
