-- ============================================================================
-- 商品分销（分销用户 / 佣金记录）整体下线
--
-- 背景：亚特的业务不涉及商品分销。后端（分销 Controller/Service/Mapper/DO/Convert/Job、
--       SKU 佣金字段、订单推广人字段、统计佣金口径、分销枚举与错误码）与前端
--       （vben 三个模板、admin-uniapp 的分销页面与配置项）均已删除。
--       本脚本清理数据库层残留：分销菜单与权限、分销字典、两张分销表归档、分销定时任务。
--
-- 说明：
--   1. 表一律「重命名归档」而非 DROP，可随时回滚：
--      ALTER TABLE zz_deprecated_trade_brokerage_user   RENAME TO trade_brokerage_user;
--      ALTER TABLE zz_deprecated_trade_brokerage_record RENAME TO trade_brokerage_record;
--   2. 列一律保留（不 DROP），代码侧已不再读写，确认无历史依赖后再执行文件末尾注释的语句：
--      - trade_config 的 10 个 brokerage_* 列（该表当前 0 行，列均可空无默认值）
--      - trade_order.brokerage_user_id（当前全为 NULL）
--      - product_sku.first_brokerage_price / second_brokerage_price
--      - trade_statistics.brokerage_settlement_price（当前该表 0 行）
--   3. 幂等，可重复执行。
-- ============================================================================

-- 1) 分销菜单与角色关联（分销管理 / 分销用户 / 佣金记录 / 佣金提现审核）
DELETE FROM system_role_menu
WHERE menu_id IN (SELECT id FROM system_menu
                  WHERE permission LIKE 'trade:brokerage%'
                     OR component LIKE 'mall/trade/brokerage/%'
                     OR name IN ('分销管理', '分销用户', '佣金记录'));
DELETE FROM system_menu
WHERE permission LIKE 'trade:brokerage%'
   OR component LIKE 'mall/trade/brokerage/%'
   OR name IN ('分销管理', '分销用户', '佣金记录');

-- 2) 分销字典（brokerage_enabled_condition / bind_mode / record_biz_type /
--            record_status / withdraw_type / withdraw_status / bank_name）
DELETE FROM system_dict_data WHERE dict_type LIKE 'brokerage%';
DELETE FROM system_dict_type WHERE type LIKE 'brokerage%';

-- 3) 分销定时任务（佣金解冻；基线脚本曾注册，代码侧已删除该 Job）
DELETE FROM infra_job WHERE handler_name LIKE '%Brokerage%';

-- 4) 分销表归档
ALTER TABLE IF EXISTS trade_brokerage_user   RENAME TO zz_deprecated_trade_brokerage_user;
ALTER TABLE IF EXISTS trade_brokerage_record RENAME TO zz_deprecated_trade_brokerage_record;
-- 佣金提现表已由 20_remove_brokerage_withdraw.sql 归档；这里再兜一次底
ALTER TABLE IF EXISTS trade_brokerage_withdraw RENAME TO zz_deprecated_trade_brokerage_withdraw;

-- 5) 归档确认无误、且业务确认无需追溯后可执行（默认不执行）：
-- DROP TABLE IF EXISTS zz_deprecated_trade_brokerage_user;
-- DROP TABLE IF EXISTS zz_deprecated_trade_brokerage_record;
-- DROP TABLE IF EXISTS zz_deprecated_trade_brokerage_withdraw;
-- ALTER TABLE trade_config      DROP COLUMN IF EXISTS brokerage_enabled;
-- ALTER TABLE trade_config      DROP COLUMN IF EXISTS brokerage_enabled_condition;
-- ALTER TABLE trade_config      DROP COLUMN IF EXISTS brokerage_bind_mode;
-- ALTER TABLE trade_config      DROP COLUMN IF EXISTS brokerage_poster_urls;
-- ALTER TABLE trade_config      DROP COLUMN IF EXISTS brokerage_first_percent;
-- ALTER TABLE trade_config      DROP COLUMN IF EXISTS brokerage_second_percent;
-- ALTER TABLE trade_config      DROP COLUMN IF EXISTS brokerage_withdraw_min_price;
-- ALTER TABLE trade_config      DROP COLUMN IF EXISTS brokerage_withdraw_fee_percent;
-- ALTER TABLE trade_config      DROP COLUMN IF EXISTS brokerage_frozen_days;
-- ALTER TABLE trade_config      DROP COLUMN IF EXISTS brokerage_withdraw_types;
-- ALTER TABLE trade_order       DROP COLUMN IF EXISTS brokerage_user_id;
-- ALTER TABLE product_sku       DROP COLUMN IF EXISTS first_brokerage_price;
-- ALTER TABLE product_sku       DROP COLUMN IF EXISTS second_brokerage_price;
-- ALTER TABLE trade_statistics  DROP COLUMN IF EXISTS brokerage_settlement_price;

-- 6) 校验：下面各查询应依次返回 0 / 0 / 0 / 0，且表名以 zz_deprecated_ 开头
-- SELECT count(*) FROM system_menu  WHERE permission LIKE 'trade:brokerage%';
-- SELECT count(*) FROM system_dict_type WHERE type LIKE 'brokerage%';
-- SELECT count(*) FROM system_dict_data WHERE dict_type LIKE 'brokerage%';
-- SELECT count(*) FROM infra_job WHERE handler_name LIKE '%Brokerage%';
-- SELECT table_name FROM information_schema.tables WHERE table_name LIKE '%brokerage%';
