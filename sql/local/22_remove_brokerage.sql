-- ============================================================================
-- 商品分销（分销用户 / 佣金记录 / 佣金提现）物理清除
--
-- 背景：亚特的业务不涉及商品分销，且已确认「以后也不会做」。
--       后端（分销 Controller/Service/Mapper/DO/Convert/Job、SKU 佣金字段、订单推广人字段、
--       统计佣金口径、分销枚举与错误码）与前端（vben 三个模板、admin-uniapp 的分销页面与
--       配置项）均已删除。本脚本把数据库层的残留一并**物理删除**：
--       分销菜单与权限、分销字典、分销定时任务、三张分销表、以及相关的 14 个列。
--
-- 说明：
--   1. 本脚本是 20_remove_brokerage_withdraw.sql 的收口：那张「归档」表也在这里一并 DROP。
--   2. 执行前已确认无数据可丢（迁移时实测）：
--      trade_brokerage_user / trade_brokerage_record / trade_brokerage_withdraw 均 0 行；
--      trade_config 0 行且 10 个分销列均可空无默认值；trade_order.brokerage_user_id 全为 NULL；
--      trade_statistics 0 行。product_sku 的两级佣金列有 16 行配置值，随分销下线一并丢弃。
--   3. 幂等（IF EXISTS / LIKE 条件），可重复执行。
--   4. 回滚：代码侧 git revert 对应提交，数据库侧需恢复建表与建列语句（本脚本不含），
--      且已丢弃的配置值无法找回。
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

-- 2) 分销字典（enabled_condition / bind_mode / record_biz_type / record_status /
--            withdraw_type / withdraw_status / bank_name）
DELETE FROM system_dict_data WHERE dict_type LIKE 'brokerage%';
DELETE FROM system_dict_type WHERE type LIKE 'brokerage%';

-- 3) 分销定时任务（佣金解冻；基线脚本曾注册，代码侧已删除该 Job）
DELETE FROM infra_job WHERE handler_name LIKE '%Brokerage%';

-- 4) 分销表物理删除（含 20 号脚本归档出来的那张）
DROP TABLE IF EXISTS zz_deprecated_trade_brokerage_user;
DROP TABLE IF EXISTS zz_deprecated_trade_brokerage_record;
DROP TABLE IF EXISTS zz_deprecated_trade_brokerage_withdraw;
DROP TABLE IF EXISTS trade_brokerage_user;
DROP TABLE IF EXISTS trade_brokerage_record;
DROP TABLE IF EXISTS trade_brokerage_withdraw;

-- 5) 分销列物理删除（代码侧已不读写）
ALTER TABLE trade_config      DROP COLUMN IF EXISTS brokerage_enabled;
ALTER TABLE trade_config      DROP COLUMN IF EXISTS brokerage_enabled_condition;
ALTER TABLE trade_config      DROP COLUMN IF EXISTS brokerage_bind_mode;
ALTER TABLE trade_config      DROP COLUMN IF EXISTS brokerage_poster_urls;
ALTER TABLE trade_config      DROP COLUMN IF EXISTS brokerage_first_percent;
ALTER TABLE trade_config      DROP COLUMN IF EXISTS brokerage_second_percent;
ALTER TABLE trade_config      DROP COLUMN IF EXISTS brokerage_withdraw_min_price;
ALTER TABLE trade_config      DROP COLUMN IF EXISTS brokerage_withdraw_fee_percent;
ALTER TABLE trade_config      DROP COLUMN IF EXISTS brokerage_frozen_days;
ALTER TABLE trade_config      DROP COLUMN IF EXISTS brokerage_withdraw_types;
ALTER TABLE trade_order       DROP COLUMN IF EXISTS brokerage_user_id;
ALTER TABLE product_sku       DROP COLUMN IF EXISTS first_brokerage_price;
ALTER TABLE product_sku       DROP COLUMN IF EXISTS second_brokerage_price;
ALTER TABLE trade_statistics  DROP COLUMN IF EXISTS brokerage_settlement_price;

-- 6) 校验：以下查询应全部返回 0 行 / 0 条
-- SELECT count(*) FROM system_menu  WHERE permission LIKE 'trade:brokerage%';
-- SELECT count(*) FROM system_dict_type WHERE type LIKE 'brokerage%';
-- SELECT count(*) FROM system_dict_data WHERE dict_type LIKE 'brokerage%';
-- SELECT count(*) FROM infra_job WHERE handler_name LIKE '%Brokerage%';
-- SELECT table_name FROM information_schema.tables  WHERE table_schema='public' AND table_name LIKE '%brokerage%';
-- SELECT table_name, column_name FROM information_schema.columns WHERE table_schema='public' AND column_name LIKE '%brokerage%';
