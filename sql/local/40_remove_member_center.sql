-- ============================================================================
-- 40 物理删除「会员中心」，只保留「订货账号」
--
-- 背景：亚特是私域订货场景，门店/代理人只需一个订货账号，不需要 C 端会员中心
--       （等级 / 经验 / 积分 / 签到 / 标签 / 分组 / 会员配置 / 地址簿 / 会员统计）。
--       后端代码与后台页面已在同一批提交里物理删除，本脚本负责数据库侧。
--
-- 做法：
--   1) 先把要删的表整表备份到 schema bak_member_center_<日期>（CREATE TABLE AS SELECT），
--      确认无误后可 DROP SCHEMA ... CASCADE；
--   2) 删除 11 张会员中心表；
--   3) 删除「会员中心」菜单子树（2262）与「会员统计」（2374），**保留**会员管理（2317）子树
--      并改名为「订货账号」；
--   4) 清理 system_role_menu 里指向已删菜单的授权；
--   5) 删除 member_* 字典；
--   6) 删除 member_user 上只服务于会员中心的列（等级 / 积分 / 经验 / 分组 / 标签）。
--
-- 幂等：可重复执行。整个脚本包在一个事务里执行，中途失败会整体回滚，
-- 不会留下「表删了但菜单还在」的半成品状态。
-- ============================================================================

BEGIN;

-- ---------------------------------------------------------------------------
-- 1. 备份（只备份一次：schema 已存在就跳过，避免把空表覆盖掉有数据的备份）
-- ---------------------------------------------------------------------------
DO $$
DECLARE
    bak text := 'bak_member_center_20260929';
    i   text;
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.schemata WHERE schema_name = bak) THEN
        RAISE NOTICE '备份 schema % 已存在，跳过备份（如需重跑请先 DROP SCHEMA）', bak;
    ELSE
        EXECUTE format('CREATE SCHEMA %I', bak);
        FOR i IN SELECT unnest(ARRAY['member_user','member_address','member_config','member_experience_record',
                                    'member_group','member_level','member_level_record','member_point_record',
                                    'member_sign_in_config','member_sign_in_record','member_tag'])
        LOOP
            IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name=i) THEN
                EXECUTE format('CREATE TABLE %I.%I AS SELECT * FROM public.%I', bak, i, i);
            END IF;
        END LOOP;
        RAISE NOTICE '已备份会员中心 11 张表到 schema %', bak;
    END IF;
END $$;

-- ---------------------------------------------------------------------------
-- 2. 删表
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS member_address CASCADE;
DROP TABLE IF EXISTS member_config CASCADE;
DROP TABLE IF EXISTS member_experience_record CASCADE;
DROP TABLE IF EXISTS member_group CASCADE;
DROP TABLE IF EXISTS member_level CASCADE;
DROP TABLE IF EXISTS member_level_record CASCADE;
DROP TABLE IF EXISTS member_point_record CASCADE;
DROP TABLE IF EXISTS member_sign_in_config CASCADE;
DROP TABLE IF EXISTS member_sign_in_record CASCADE;
DROP TABLE IF EXISTS member_tag CASCADE;

-- ---------------------------------------------------------------------------
-- 3. 删菜单：「会员中心」(2262) 整棵子树 + 「会员统计」(2374)，但保留 2317（会员管理）子树
-- ---------------------------------------------------------------------------
-- 注意：这里**不能**用 ON COMMIT DROP —— psql 的 -f 是自动提交模式，
-- 临时表会在 CREATE 语句结束时就消失，后面的 DELETE 会报 relation does not exist。
CREATE TEMP TABLE tmp_menu_to_delete AS
WITH RECURSIVE tree AS (
    SELECT id, parent_id FROM system_menu WHERE deleted = 0 AND id IN (2262, 2374)
    UNION ALL
    SELECT c.id, c.parent_id FROM system_menu c JOIN tree t ON c.parent_id = t.id WHERE c.deleted = 0
),
keep_menu AS (
    SELECT id FROM system_menu WHERE deleted = 0 AND id = 2317
    UNION ALL
    SELECT c.id FROM system_menu c JOIN keep_menu k ON c.parent_id = k.id WHERE c.deleted = 0
)
SELECT id FROM tree WHERE id NOT IN (SELECT id FROM keep_menu);

DELETE FROM system_role_menu WHERE menu_id IN (SELECT id FROM tmp_menu_to_delete);
DELETE FROM system_menu WHERE id IN (SELECT id FROM tmp_menu_to_delete);
DROP TABLE tmp_menu_to_delete;

-- 2317（订货账号）子树是被保留的，但它下面还挂着两个指向已下线能力的按钮权限：
-- 2335 用户等级修改 member:user:update-level、2363 用户积分修改 member:user:update-point —— 一并删除
DELETE FROM system_role_menu WHERE menu_id IN (2335, 2363);
DELETE FROM system_menu WHERE id IN (2335, 2363);

-- 会员管理 → 订货账号（连同按钮文案）
UPDATE system_menu SET name = '订货账号', icon = 'lucide:key-round', sort = 1, updater = 'script40', update_time = now()
WHERE id = 2317 AND deleted = 0;
UPDATE system_menu SET name = '订货账号查询', updater = 'script40', update_time = now() WHERE id = 2318 AND deleted = 0;
UPDATE system_menu SET name = '订货账号更新', updater = 'script40', update_time = now() WHERE id = 2319 AND deleted = 0;

-- ---------------------------------------------------------------------------
-- 4. 字典清理（member_* 全部属于会员中心）
-- ---------------------------------------------------------------------------
DELETE FROM system_dict_data WHERE dict_type LIKE 'member%';
DELETE FROM system_dict_type WHERE type LIKE 'member%';

-- ---------------------------------------------------------------------------
-- 5. member_user 只服务于会员中心的列（等级 / 经验 / 积分 / 分组 / 标签）
-- ---------------------------------------------------------------------------
ALTER TABLE member_user DROP COLUMN IF EXISTS level_id;
ALTER TABLE member_user DROP COLUMN IF EXISTS experience;
ALTER TABLE member_user DROP COLUMN IF EXISTS point;
ALTER TABLE member_user DROP COLUMN IF EXISTS group_id;
ALTER TABLE member_user DROP COLUMN IF EXISTS tag_ids;

-- ---------------------------------------------------------------------------
-- 6. 自检
-- ---------------------------------------------------------------------------
SELECT '剩余 member_* 表' AS item, COALESCE(string_agg(table_name, ', ' ORDER BY table_name), '(无)') AS value
FROM information_schema.tables WHERE table_schema = 'public' AND table_name LIKE 'member%'
UNION ALL
SELECT '会员中心菜单残留', COALESCE(count(*)::text, '0') FROM system_menu WHERE deleted = 0 AND (id = 2262 OR path LIKE '%member/%' AND id <> 2317)
UNION ALL
SELECT '订货账号菜单', COALESCE(string_agg(id || ':' || name, ', ' ORDER BY id), '(无)') FROM system_menu WHERE deleted = 0 AND id IN (2317, 2318, 2319, 12130, 12131)
UNION ALL
SELECT 'member_user 剩余列', COALESCE(string_agg(column_name, ', ' ORDER BY ordinal_position), '(无)') FROM information_schema.columns WHERE table_schema='public' AND table_name='member_user'
UNION ALL
SELECT '会员字典残留', COALESCE(count(*)::text, '0') FROM system_dict_type WHERE type LIKE 'member%';

COMMIT;
