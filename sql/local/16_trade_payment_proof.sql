-- =============================================================================
-- 线下收款（付款凭证）改造 —— 结构 / 字典 / 权限
--
-- 背景：
--   本商城实际业务走线下转账：客户提交订货单后上传付款截图，后台核验收款，不经过线上支付。
--   线上支付（pay 模块的支付单）在本定制分支将逐步移除，本脚本只做线下收款所需的结构准备。
--
-- 内容：
--   1) 新表 trade_order_payment_proof：一次上传 = 一行，支持多图、多次上传、驳回重传；
--   2) trade_order 增加 paid_amount（已确认收款金额，单位分）与 payment_proof_status（收款状态）；
--   3) 字典 trade_payment_proof_status；pay_channel_code 增加 4 个线下收款渠道；
--   4) 「交易订单」菜单下新增按钮权限 trade:order:payment-proof:audit（收款核验）。
--
-- 幂等：可重复执行（CREATE ... IF NOT EXISTS / ON CONFLICT DO NOTHING）。
-- 执行：psql -U root -d yate -f sql/local/16_trade_payment_proof.sql
-- =============================================================================

-- ---------- 1) 付款凭证表 ----------
CREATE SEQUENCE IF NOT EXISTS trade_order_payment_proof_seq START 1;

CREATE TABLE IF NOT EXISTS trade_order_payment_proof (
    id                bigint NOT NULL,
    order_id          bigint NOT NULL,
    urls              text NOT NULL,
    amount            integer NOT NULL,
    confirmed_amount  integer,
    payer_name        varchar(64) DEFAULT '',
    pay_channel_code  varchar(32) DEFAULT '',
    transfer_time     timestamp,
    remark            varchar(255) DEFAULT '',
    status            smallint NOT NULL DEFAULT 0,
    audit_user_id     bigint,
    audit_time        timestamp,
    audit_remark      varchar(255) DEFAULT '',
    tenant_id         bigint NOT NULL DEFAULT 0,
    creator           varchar(64) DEFAULT '',
    create_time       timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updater           varchar(64) DEFAULT '',
    update_time       timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted           smallint NOT NULL DEFAULT 0
);
CREATE INDEX IF NOT EXISTS idx_trade_order_payment_proof_order_id ON trade_order_payment_proof (order_id);

-- ---------- 2) 交易订单：收款汇总字段 ----------
ALTER TABLE trade_order ADD COLUMN IF NOT EXISTS paid_amount integer NOT NULL DEFAULT 0;
ALTER TABLE trade_order ADD COLUMN IF NOT EXISTS payment_proof_status smallint NOT NULL DEFAULT 0;

-- ---------- 3) 字典 ----------
INSERT INTO system_dict_type (id, name, type, status, remark, creator, create_time, updater, update_time, deleted)
VALUES (11300, '交易订单-收款状态', 'trade_payment_proof_status', 0, '线下收款流程：凭证核验与收款进度',
        '1', now(), '1', now(), 0)
ON CONFLICT (id) DO NOTHING;

INSERT INTO system_dict_data (id, sort, label, value, dict_type, status, color_type, css_class, remark, creator, create_time, updater, update_time, deleted)
VALUES
    (113000, 0, '未上传凭证', '0', 'trade_payment_proof_status', 0, 'default', '', '', '1', now(), '1', now(), 0),
    (113001, 1, '待核验',     '1', 'trade_payment_proof_status', 0, 'warning', '', '', '1', now(), '1', now(), 0),
    (113002, 2, '已驳回',     '2', 'trade_payment_proof_status', 0, 'danger',  '', '', '1', now(), '1', now(), 0),
    (113003, 3, '部分收款',   '3', 'trade_payment_proof_status', 0, 'primary', '', '', '1', now(), '1', now(), 0),
    (113004, 4, '已收齐',     '4', 'trade_payment_proof_status', 0, 'success', '', '', '1', now(), '1', now(), 0)
ON CONFLICT (id) DO NOTHING;

-- pay_channel_code 增加线下收款渠道（后台订单列表按该字典筛渠道）
INSERT INTO system_dict_data (id, sort, label, value, dict_type, status, color_type, css_class, remark, creator, create_time, updater, update_time, deleted)
VALUES
    (113100, 30, '线下转账',   'offline_transfer', 'pay_channel_code', 0, 'default', '', '客户银行/对公转账', '1', now(), '1', now(), 0),
    (113101, 31, '现金',       'offline_cash',     'pay_channel_code', 0, 'default', '', '', '1', now(), '1', now(), 0),
    (113102, 32, '微信转账',   'offline_wx',       'pay_channel_code', 0, 'default', '', '', '1', now(), '1', now(), 0),
    (113103, 33, '支付宝转账', 'offline_alipay',   'pay_channel_code', 0, 'default', '', '', '1', now(), '1', now(), 0)
ON CONFLICT (id) DO NOTHING;

-- ---------- 4) 按钮权限（挂在「交易订单」菜单 2076 下） ----------
INSERT INTO system_menu (id, name, permission, type, sort, parent_id, path, icon, component, component_name, status, visible, keep_alive, always_show, creator, create_time, updater, update_time, deleted)
VALUES (11320, '订单收款核验', 'trade:order:payment-proof:audit', 3, 11, 2076, '', '', '', '', 0, TRUE, TRUE, FALSE, '1', now(), '1', now(), 0)
ON CONFLICT (id) DO NOTHING;
