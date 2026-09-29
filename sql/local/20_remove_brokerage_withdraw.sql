-- ============================================================================
-- 佣金提现功能下线（业务无需求）
--
-- 背景：亚特的分销佣金不做线上提现，前端页面与后端 Controller/Service/Mapper 已删除。
-- 本脚本清理数据库层残留：提现菜单与权限、提现状态字典、提现表归档。
--
-- 说明：
--   1. 字典 brokerage_withdraw_type 保留——交易配置「可提现方式」仍在用（TradeConfigDO）；
--   2. 表用重命名归档而非 DROP，可随时回滚：
--      ALTER TABLE zz_deprecated_trade_brokerage_withdraw RENAME TO trade_brokerage_withdraw;
--   3. 幂等，可重复执行。
-- ============================================================================

-- 1) 佣金提现菜单（页面 + 查询 + 审核）与角色关联
DELETE FROM system_role_menu
WHERE menu_id IN (SELECT id FROM system_menu
                  WHERE permission LIKE 'trade:brokerage-withdraw%'
                     OR component = 'mall/trade/brokerage/withdraw/index');
DELETE FROM system_menu
WHERE permission LIKE 'trade:brokerage-withdraw%'
   OR component = 'mall/trade/brokerage/withdraw/index';

-- 2) 提现状态字典（唯一消费方是已删除的提现页面）
DELETE FROM system_dict_data WHERE dict_type = 'brokerage_withdraw_status';
DELETE FROM system_dict_type WHERE type = 'brokerage_withdraw_status';

-- 3) 提现表归档
ALTER TABLE IF EXISTS trade_brokerage_withdraw RENAME TO zz_deprecated_trade_brokerage_withdraw;

-- 4) 归档确认无误后可执行（默认不执行）：
-- DROP TABLE IF EXISTS zz_deprecated_trade_brokerage_withdraw;

-- 5) 校验：应返回 0 / 0 / 只剩 type 字典
-- SELECT count(*) FROM system_menu WHERE permission LIKE 'trade:brokerage-withdraw%';
-- SELECT count(*) FROM system_dict_type WHERE type = 'brokerage_withdraw_status';
-- SELECT type FROM system_dict_type WHERE type LIKE 'brokerage%';
