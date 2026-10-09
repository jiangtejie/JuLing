-- ============================================================================
-- 45 物理删除 7 个亚特用不到的 yudao 模块（MES / PMS / CRM / HRM / IM / IoT / 公众号）
--
-- 依据（实测）：按菜单授权递归统计，除超管外全库只有「供应链」(3 人) 与「财务」(1 人) 两个真实角色；
--   这 7 个模块的菜单**没有授权给任何真实角色**（MES 只授给了 0 用户的种子角色「CRM 管理员」）。
--   数据量：crm/im/mes/mp 各 0 行、hrm 1 行、iot 2 行、pms 4 行 —— 删表零业务损失。
--   外键：保留模块指向这 7 个模块的外键 **0 条**，删除不会波及保留模块。
--   亚特是餐饮连锁 + 私域订货，制造执行/项目管理/物联网/公众号/IM/CRM/HRM 都不在业务范围内。
--
-- 保留：ERP(进销存) / 商城(订货) / FMS(财务，替代金蝶的落点) / WMS(供应链在用) / AI(要接 deepseek) /
--       BPM(审批) / 系统 / 基础设施 / 单据平台。
--
-- 做法：整表备份到 schema bak_unused_modules_20260929 → DROP 全部表 → 删 7 棵菜单子树与角色授权 →
--       删对应字典 → 删 6 个定时任务。幂等；整个脚本包在事务里，中途失败整体回滚。
-- ============================================================================

BEGIN;

DO $$
DECLARE
    bak text := 'bak_unused_modules_20260929';
    r   record;
    n   int := 0;
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.schemata WHERE schema_name = bak) THEN
        RAISE NOTICE '备份 schema % 已存在，跳过备份', bak;
    ELSE
        EXECUTE format('CREATE SCHEMA %I', bak);
        FOR r IN SELECT table_name FROM information_schema.tables
                 WHERE table_schema='public' AND table_type='BASE TABLE'
                   AND split_part(table_name,'_',1) IN ('mes','pms','crm','hrm','im','iot','mp')
        LOOP
            EXECUTE format('CREATE TABLE %I.%I AS SELECT * FROM public.%I', bak, r.table_name, r.table_name);
            n := n + 1;
        END LOOP;
        RAISE NOTICE '已备份 % 张表到 schema %', n, bak;
    END IF;
END $$;

DO $$
DECLARE
    r record;
    n int := 0;
BEGIN
    FOR r IN SELECT table_name FROM information_schema.tables
             WHERE table_schema='public' AND table_type='BASE TABLE'
               AND split_part(table_name,'_',1) IN ('mes','pms','crm','hrm','im','iot','mp')
    LOOP
        EXECUTE format('DROP TABLE IF EXISTS public.%I CASCADE', r.table_name);
        n := n + 1;
    END LOOP;
    RAISE NOTICE '已删除 % 张表', n;
END $$;

-- 菜单：7 棵子树
CREATE TEMP TABLE tmp_del_menu AS
WITH RECURSIVE tree AS (
    SELECT id FROM system_menu WHERE deleted = 0 AND id IN (5100, 10410, 2397, 8810, 8300, 4000, 2084)
    UNION ALL
    SELECT c.id FROM system_menu c JOIN tree t ON c.parent_id = t.id WHERE c.deleted = 0
)
SELECT id FROM tree;

DELETE FROM system_role_menu WHERE menu_id IN (SELECT id FROM tmp_del_menu);
DELETE FROM system_menu       WHERE id IN (SELECT id FROM tmp_del_menu);
DROP TABLE tmp_del_menu;

-- 字典（按模块前缀）
DELETE FROM system_dict_data WHERE dict_type ~ '^(mes|pms|crm|hrm|im|iot|mp)_';
DELETE FROM system_dict_type WHERE type      ~ '^(mes|pms|crm|hrm|im|iot|mp)_';

-- 定时任务
DELETE FROM infra_job WHERE handler_name IN (
    'iotDeviceOfflineCheckJob', 'iotOtaUpgradeJob',
    'hrmSalaryChangeJob', 'hrmPerformanceAppealTimeoutJob', 'hrmEmployeeChangeJob',
    'pmsKnowledgeRecycleCleanJob');

-- 自检
SELECT '剩余这 7 个模块的表' AS item,
       COALESCE(string_agg(table_name, ', ' ORDER BY table_name), '(无)') AS value
FROM information_schema.tables
WHERE table_schema='public' AND table_type='BASE TABLE'
  AND split_part(table_name,'_',1) IN ('mes','pms','crm','hrm','im','iot','mp')
UNION ALL
SELECT '保留模块的表数量',
       count(*)::text
FROM information_schema.tables
WHERE table_schema='public' AND table_type='BASE TABLE'
  AND split_part(table_name,'_',1) IN ('erp','mall','trade','product','member','system','infra','bpm','bill','fms','wms','ai','statistics')
UNION ALL
SELECT '剩余顶层菜单',
       COALESCE(string_agg(name, ', ' ORDER BY sort), '(无)')
FROM system_menu WHERE deleted=0 AND parent_id=0
UNION ALL
SELECT '这 7 个模块的字典残留',
       COALESCE(count(*)::text, '0')
FROM system_dict_type WHERE type ~ '^(mes|pms|crm|hrm|im|iot|mp)_'
UNION ALL
SELECT '相关定时任务残留',
       COALESCE(count(*)::text, '0')
FROM infra_job WHERE handler_name IN ('iotDeviceOfflineCheckJob','iotOtaUpgradeJob','hrmSalaryChangeJob','hrmPerformanceAppealTimeoutJob','hrmEmployeeChangeJob','pmsKnowledgeRecycleCleanJob')
UNION ALL
SELECT '备份表数',
       (SELECT count(*)::text FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
         WHERE n.nspname='bak_unused_modules_20260929' AND c.relkind='r');

COMMIT;
