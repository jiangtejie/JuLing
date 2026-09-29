-- ============================================================================
-- 43 物理删除 C 端商城的营销体系与商品评价
--
-- 背景：亚特商城只做私域订货（门店/代理人用订货账号下单、中心库配送、线下转账）。
--   C 端营销玩法（秒杀/拼团/砍价/满减/限时折扣/优惠券/积分商城/装修/文章/Banner/客服）
--   与商品评价体系完全用不上：营销活动表全 0 行、product_comment 0 行、
--   H5 里没有任何营销/评论/客服页面与接口调用（已核实）。
--
-- 做法：
--   1) 先把 24 张营销/评价表 + 订单与订单项（含营销列）整表备份到 schema bak_promotion_20260929；
--   2) DROP 这 24 张表；
--   3) 删掉 trade_order(17 列) / trade_order_item(6 列) 上的营销与评价字段（当前 6 张订单里这些值全为 0/NULL）；
--   4) 删「营销中心」(2030) / 「客服中心」(2797) / 「商品评论」(2336) 三棵菜单子树与角色授权；
--   5) 删 promotion_* 字典与两个营销定时任务（拼团过期 / 优惠券过期）。
--
-- 幂等：可重复执行。整个脚本包在事务里，中途失败整体回滚。
-- ============================================================================

BEGIN;

-- ---------------------------------------------------------------------------
-- 1. 备份
-- ---------------------------------------------------------------------------
DO $$
DECLARE
    bak text := 'bak_promotion_20260929';
    i   text;
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.schemata WHERE schema_name = bak) THEN
        RAISE NOTICE '备份 schema % 已存在，跳过备份', bak;
    ELSE
        EXECUTE format('CREATE SCHEMA %I', bak);
        FOR i IN SELECT unnest(ARRAY[
            'promotion_article','promotion_article_category','promotion_banner',
            'promotion_bargain_activity','promotion_bargain_help','promotion_bargain_record',
            'promotion_combination_activity','promotion_combination_product','promotion_combination_record',
            'promotion_coupon','promotion_coupon_template','promotion_discount_activity','promotion_discount_product',
            'promotion_diy_page','promotion_diy_template','promotion_kefu_conversation','promotion_kefu_message',
            'promotion_point_activity','promotion_point_product','promotion_reward_activity',
            'promotion_seckill_activity','promotion_seckill_config','promotion_seckill_product',
            'product_comment','trade_order','trade_order_item'])
        LOOP
            IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name=i) THEN
                EXECUTE format('CREATE TABLE %I.%I AS SELECT * FROM public.%I', bak, i, i);
            END IF;
        END LOOP;
        RAISE NOTICE '已备份 26 张表到 schema %', bak;
    END IF;
END $$;

-- ---------------------------------------------------------------------------
-- 2. 删表（24 张）
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS promotion_article CASCADE;
DROP TABLE IF EXISTS promotion_article_category CASCADE;
DROP TABLE IF EXISTS promotion_banner CASCADE;
DROP TABLE IF EXISTS promotion_bargain_activity CASCADE;
DROP TABLE IF EXISTS promotion_bargain_help CASCADE;
DROP TABLE IF EXISTS promotion_bargain_record CASCADE;
DROP TABLE IF EXISTS promotion_combination_activity CASCADE;
DROP TABLE IF EXISTS promotion_combination_product CASCADE;
DROP TABLE IF EXISTS promotion_combination_record CASCADE;
DROP TABLE IF EXISTS promotion_coupon CASCADE;
DROP TABLE IF EXISTS promotion_coupon_template CASCADE;
DROP TABLE IF EXISTS promotion_discount_activity CASCADE;
DROP TABLE IF EXISTS promotion_discount_product CASCADE;
DROP TABLE IF EXISTS promotion_diy_page CASCADE;
DROP TABLE IF EXISTS promotion_diy_template CASCADE;
DROP TABLE IF EXISTS promotion_kefu_conversation CASCADE;
DROP TABLE IF EXISTS promotion_kefu_message CASCADE;
DROP TABLE IF EXISTS promotion_point_activity CASCADE;
DROP TABLE IF EXISTS promotion_point_product CASCADE;
DROP TABLE IF EXISTS promotion_reward_activity CASCADE;
DROP TABLE IF EXISTS promotion_seckill_activity CASCADE;
DROP TABLE IF EXISTS promotion_seckill_config CASCADE;
DROP TABLE IF EXISTS promotion_seckill_product CASCADE;
DROP TABLE IF EXISTS product_comment CASCADE;

-- ---------------------------------------------------------------------------
-- 3. 删订单上的营销 / 评价列（当前数据全为 0/NULL，且已整表备份）
-- ---------------------------------------------------------------------------
ALTER TABLE trade_order
    DROP COLUMN IF EXISTS coupon_id,
    DROP COLUMN IF EXISTS coupon_price,
    DROP COLUMN IF EXISTS point_price,
    DROP COLUMN IF EXISTS use_point,
    DROP COLUMN IF EXISTS give_point,
    DROP COLUMN IF EXISTS refund_point,
    DROP COLUMN IF EXISTS vip_price,
    DROP COLUMN IF EXISTS give_coupon_template_counts,
    DROP COLUMN IF EXISTS give_coupon_ids,
    DROP COLUMN IF EXISTS seckill_activity_id,
    DROP COLUMN IF EXISTS bargain_activity_id,
    DROP COLUMN IF EXISTS bargain_record_id,
    DROP COLUMN IF EXISTS combination_activity_id,
    DROP COLUMN IF EXISTS combination_head_id,
    DROP COLUMN IF EXISTS combination_record_id,
    DROP COLUMN IF EXISTS point_activity_id,
    DROP COLUMN IF EXISTS comment_status;

ALTER TABLE trade_order_item
    DROP COLUMN IF EXISTS coupon_price,
    DROP COLUMN IF EXISTS point_price,
    DROP COLUMN IF EXISTS use_point,
    DROP COLUMN IF EXISTS give_point,
    DROP COLUMN IF EXISTS vip_price,
    DROP COLUMN IF EXISTS comment_status;

-- ---------------------------------------------------------------------------
-- 4. 删菜单（营销中心 / 客服中心 / 商品评论 三棵子树）
-- ---------------------------------------------------------------------------
CREATE TEMP TABLE tmp_del_menu AS
WITH RECURSIVE tree AS (
    SELECT id FROM system_menu WHERE deleted = 0 AND id IN (2030, 2797, 2336)
    UNION ALL
    SELECT c.id FROM system_menu c JOIN tree t ON c.parent_id = t.id WHERE c.deleted = 0
)
SELECT id FROM tree;

DELETE FROM system_role_menu WHERE menu_id IN (SELECT id FROM tmp_del_menu);
DELETE FROM system_menu       WHERE id IN (SELECT id FROM tmp_del_menu);
DROP TABLE tmp_del_menu;

-- ---------------------------------------------------------------------------
-- 5. 字典与定时任务
-- ---------------------------------------------------------------------------
DELETE FROM system_dict_data WHERE dict_type LIKE 'promotion%';
DELETE FROM system_dict_type WHERE type LIKE 'promotion%';
DELETE FROM infra_job WHERE handler_name IN ('combinationRecordExpireJob', 'couponExpireJob');

-- ---------------------------------------------------------------------------
-- 6. 自检
-- ---------------------------------------------------------------------------
SELECT '剩余 promotion_* / 评价表' AS item,
       COALESCE(string_agg(table_name, ', ' ORDER BY table_name), '(无)') AS value
FROM information_schema.tables
WHERE table_schema = 'public' AND (table_name LIKE 'promotion%' OR table_name = 'product_comment')
UNION ALL
SELECT 'trade_order 残留营销列',
       COALESCE(string_agg(column_name, ', '), '(无)')
FROM information_schema.columns
WHERE table_schema='public' AND table_name='trade_order'
  AND (column_name LIKE '%coupon%' OR column_name LIKE '%point%' OR column_name LIKE '%seckill%'
       OR column_name LIKE '%combination%' OR column_name LIKE '%bargain%' OR column_name LIKE '%vip%' OR column_name LIKE '%comment%')
UNION ALL
SELECT '商城系统下剩余一级菜单',
       COALESCE(string_agg(name, ', ' ORDER BY sort), '(无)')
FROM system_menu WHERE deleted=0 AND parent_id = 2362 AND type IN (1,2)
UNION ALL
SELECT 'promotion 字典残留', COALESCE(count(*)::text, '0') FROM system_dict_type WHERE type LIKE 'promotion%'
UNION ALL
SELECT '营销定时任务残留', COALESCE(count(*)::text, '0') FROM infra_job WHERE handler_name IN ('combinationRecordExpireJob','couponExpireJob');

COMMIT;
