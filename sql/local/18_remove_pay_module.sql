-- ============================================================================
-- 支付模块下线（本分支商城只走线下转账，切除线上支付）
--
-- 背景：客户下单后线下转账、上传付款截图，后台核验收款；不再使用线上支付。
-- 本脚本清理支付模块在系统里的残留：菜单权限、字典、定时任务、数据表。
--
-- 说明：
--   1. pay_channel_code 字典**保留**（线下收款渠道 offline_transfer/offline_wx/
--      offline_alipay/offline_cash 仍在用，后台核验弹窗、订单详情要展示渠道名）；
--   2. 支付相关数据表采用「重命名归档」而不是 DROP：先 zz_deprecated_ 前缀隔离，
--      确认线上无影响后再执行文件末尾注释里的 DROP（重命名可随时回滚）；
--   3. 脚本幂等，可重复执行。
-- ============================================================================

-- 1) 菜单与角色关联（支付管理整棵树 + 支付/钱包权限点；erp 付款单、trade 收款核验不动）
DELETE FROM system_role_menu
WHERE menu_id IN (SELECT id FROM system_menu
                  WHERE component LIKE 'pay/%' OR permission LIKE 'pay:%' OR id IN (1117, 2551));
DELETE FROM system_menu
WHERE component LIKE 'pay/%' OR permission LIKE 'pay:%' OR id IN (1117, 2551);

-- 2) 字典：保留 pay_channel_code
DELETE FROM system_dict_data
WHERE dict_type IN ('pay_notify_status', 'pay_order_status', 'pay_refund_status', 'pay_notify_type', 'pay_transfer_status');
DELETE FROM system_dict_type
WHERE type IN ('pay_notify_status', 'pay_order_status', 'pay_refund_status', 'pay_notify_type', 'pay_transfer_status');

-- 3) 定时任务（支付通知、支付单同步/过期、退款同步、转账同步）
DELETE FROM infra_job
WHERE handler_name IN ('payNotifyJob', 'payOrderSyncJob', 'payOrderExpireJob', 'payRefundSyncJob', 'payTransferSyncJob');

-- 4) 数据表归档重命名（可回滚：ALTER TABLE zz_deprecated_pay_app RENAME TO pay_app;）
ALTER TABLE IF EXISTS pay_app RENAME TO zz_deprecated_pay_app;
ALTER TABLE IF EXISTS pay_channel RENAME TO zz_deprecated_pay_channel;
ALTER TABLE IF EXISTS pay_demo_order RENAME TO zz_deprecated_pay_demo_order;
ALTER TABLE IF EXISTS pay_demo_withdraw RENAME TO zz_deprecated_pay_demo_withdraw;
ALTER TABLE IF EXISTS pay_notify_log RENAME TO zz_deprecated_pay_notify_log;
ALTER TABLE IF EXISTS pay_notify_task RENAME TO zz_deprecated_pay_notify_task;
ALTER TABLE IF EXISTS pay_order RENAME TO zz_deprecated_pay_order;
ALTER TABLE IF EXISTS pay_order_extension RENAME TO zz_deprecated_pay_order_extension;
ALTER TABLE IF EXISTS pay_refund RENAME TO zz_deprecated_pay_refund;
ALTER TABLE IF EXISTS pay_transfer RENAME TO zz_deprecated_pay_transfer;
ALTER TABLE IF EXISTS pay_wallet RENAME TO zz_deprecated_pay_wallet;
ALTER TABLE IF EXISTS pay_wallet_recharge RENAME TO zz_deprecated_pay_wallet_recharge;
ALTER TABLE IF EXISTS pay_wallet_recharge_package RENAME TO zz_deprecated_pay_wallet_recharge_package;
ALTER TABLE IF EXISTS pay_wallet_transaction RENAME TO zz_deprecated_pay_wallet_transaction;

-- 5) 归档确认无误后，可执行以下语句彻底删除（默认不执行，保留回滚余地）：
-- DROP TABLE IF EXISTS zz_deprecated_pay_app, zz_deprecated_pay_channel, zz_deprecated_pay_demo_order,
--   zz_deprecated_pay_demo_withdraw, zz_deprecated_pay_notify_log, zz_deprecated_pay_notify_task,
--   zz_deprecated_pay_order, zz_deprecated_pay_order_extension, zz_deprecated_pay_refund,
--   zz_deprecated_pay_transfer, zz_deprecated_pay_wallet, zz_deprecated_pay_wallet_recharge,
--   zz_deprecated_pay_wallet_recharge_package, zz_deprecated_pay_wallet_transaction;

-- 6) 校验：以下查询应分别返回 0 / 只剩 pay_channel_code
-- SELECT count(*) FROM system_menu WHERE component LIKE 'pay/%' OR permission LIKE 'pay:%';
-- SELECT type FROM system_dict_type WHERE type LIKE 'pay%';
