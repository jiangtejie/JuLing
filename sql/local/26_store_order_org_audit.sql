-- =============================================================================
-- 门店订货链 S1：一店三面绑定 + 订单归属快照 + 供应链审核
--
-- 背景：
--   门店订货链设计（docs/store-ordering-flow-design.md）第一阶段。当前商城订单只有 user_id，
--   不知道是哪家门店、记谁的账；也没有审核环节。本脚本做结构准备：
--     1) erp_customer（客户/门店/代理）增加 所属部门、上级代理、店型、结算模式、账期、信用额度；
--     2) member_user（订货账号）增加 所属部门、所属客户，实现「一店三面」绑定；
--     3) trade_order 增加 组织/客户/代理快照 + 结算模式 + 审核状态与审批实例；
--     4) 字典：结算模式、店型、订单审核状态；
--     5) 按钮权限：订单「提交审核」。
--
-- 幂等：可重复执行（ADD COLUMN IF NOT EXISTS / ON CONFLICT DO NOTHING）。
-- 执行：psql -U root -d yate -f sql/local/26_store_order_org_audit.sql
-- =============================================================================

-- ---------- 1) 客户档案：门店/代理维度 ----------
ALTER TABLE erp_customer ADD COLUMN IF NOT EXISTS dept_id            bigint;
ALTER TABLE erp_customer ADD COLUMN IF NOT EXISTS parent_customer_id bigint;
ALTER TABLE erp_customer ADD COLUMN IF NOT EXISTS store_type         varchar(20);
ALTER TABLE erp_customer ADD COLUMN IF NOT EXISTS settlement_mode    varchar(20);
ALTER TABLE erp_customer ADD COLUMN IF NOT EXISTS credit_days        integer;
ALTER TABLE erp_customer ADD COLUMN IF NOT EXISTS credit_limit       numeric(24, 6);

COMMENT ON COLUMN erp_customer.dept_id            IS '所属部门（门店节点，system_dept.id）';
COMMENT ON COLUMN erp_customer.parent_customer_id IS '上级代理客户编号（代理 → 多门店）';
COMMENT ON COLUMN erp_customer.store_type         IS '店型：DIRECT 直营 / FRANCHISE 加盟（字典 erp_store_type）';
COMMENT ON COLUMN erp_customer.settlement_mode    IS '结算模式：PREPAID 先款后货 / MONTHLY 月结（字典 trade_settlement_mode）';
COMMENT ON COLUMN erp_customer.credit_days        IS '账期天数（月结时生效）';
COMMENT ON COLUMN erp_customer.credit_limit       IS '信用额度（月结时生效）';

CREATE INDEX IF NOT EXISTS idx_erp_customer_dept_id     ON erp_customer (dept_id);
CREATE INDEX IF NOT EXISTS idx_erp_customer_parent_id   ON erp_customer (parent_customer_id);

-- ---------- 2) 订货账号：绑定客户与门店 ----------
ALTER TABLE member_user ADD COLUMN IF NOT EXISTS dept_id     bigint;
ALTER TABLE member_user ADD COLUMN IF NOT EXISTS customer_id bigint;

COMMENT ON COLUMN member_user.dept_id     IS '所属部门（门店节点，system_dept.id）';
COMMENT ON COLUMN member_user.customer_id IS '所属客户（门店/代理，erp_customer.id；代理账号可切门店下单）';

CREATE INDEX IF NOT EXISTS idx_member_user_customer_id ON member_user (customer_id);

-- ---------- 3) 交易订单：归属快照 + 审核 ----------
ALTER TABLE trade_order ADD COLUMN IF NOT EXISTS dept_id             bigint;
ALTER TABLE trade_order ADD COLUMN IF NOT EXISTS customer_id         bigint;
ALTER TABLE trade_order ADD COLUMN IF NOT EXISTS agent_customer_id   bigint;
ALTER TABLE trade_order ADD COLUMN IF NOT EXISTS settlement_mode     varchar(20);
ALTER TABLE trade_order ADD COLUMN IF NOT EXISTS audit_status        smallint NOT NULL DEFAULT 0;
ALTER TABLE trade_order ADD COLUMN IF NOT EXISTS audit_user_id       bigint;
ALTER TABLE trade_order ADD COLUMN IF NOT EXISTS audit_time          timestamp;
ALTER TABLE trade_order ADD COLUMN IF NOT EXISTS audit_remark        varchar(500) DEFAULT '';
ALTER TABLE trade_order ADD COLUMN IF NOT EXISTS process_instance_id varchar(64) DEFAULT '';

COMMENT ON COLUMN trade_order.dept_id             IS '下单门店所属部门（快照，system_dept.id）';
COMMENT ON COLUMN trade_order.customer_id         IS '下单门店客户编号（快照，erp_customer.id）';
COMMENT ON COLUMN trade_order.agent_customer_id   IS '代理客户编号（快照；代理账号切换门店下单时记录）';
COMMENT ON COLUMN trade_order.settlement_mode     IS '结算模式快照：PREPAID 先款后货 / MONTHLY 月结';
COMMENT ON COLUMN trade_order.audit_status        IS '审核状态：0 待提交 / 10 审核中 / 20 已通过 / 30 已驳回';
COMMENT ON COLUMN trade_order.process_instance_id IS 'BPM 审批流程实例编号';

CREATE INDEX IF NOT EXISTS idx_trade_order_customer_id  ON trade_order (customer_id);
CREATE INDEX IF NOT EXISTS idx_trade_order_dept_id      ON trade_order (dept_id);
CREATE INDEX IF NOT EXISTS idx_trade_order_audit_status ON trade_order (audit_status);

-- 历史订单：存量数据不因新审核闸门被卡住（默认视为已通过；新订单由代码写入 0 待提交）
UPDATE trade_order SET audit_status = 20 WHERE audit_status = 0;
UPDATE trade_order SET settlement_mode = 'PREPAID' WHERE settlement_mode IS NULL;

-- ---------- 4) 字典 ----------
INSERT INTO system_dict_type (id, name, type, status, remark, creator, create_time, updater, update_time, deleted)
VALUES (11500, '门店结算模式', 'trade_settlement_mode', 0, '门店订货结算方式：先款后货 / 月结', '1', now(), '1', now(), 0),
       (11510, '门店店型',     'erp_store_type',         0, '直营 / 加盟', '1', now(), '1', now(), 0),
       (11520, '订单审核状态', 'trade_order_audit_status', 0, '门店要货审核状态', '1', now(), '1', now(), 0)
ON CONFLICT (id) DO NOTHING;

INSERT INTO system_dict_data (id, sort, label, value, dict_type, status, color_type, css_class, remark, creator, create_time, updater, update_time, deleted)
VALUES
    (115000, 0, '先款后货', 'PREPAID', 'trade_settlement_mode', 0, 'primary', '', '线下转账到账后发货', '1', now(), '1', now(), 0),
    (115001, 1, '月结',     'MONTHLY', 'trade_settlement_mode', 0, 'warning', '', '按账期挂账', '1', now(), '1', now(), 0),
    (115010, 0, '直营',     'DIRECT',    'erp_store_type', 0, 'primary', '', '', '1', now(), '1', now(), 0),
    (115011, 1, '加盟',     'FRANCHISE', 'erp_store_type', 0, 'success', '', '加盟店＝经销商角色', '1', now(), '1', now(), 0),
    (115020, 0, '待提交',   '0', 'trade_order_audit_status', 0, 'default', '', '', '1', now(), '1', now(), 0),
    (115021, 1, '审核中',   '10', 'trade_order_audit_status', 0, 'warning', '', '', '1', now(), '1', now(), 0),
    (115022, 2, '已通过',   '20', 'trade_order_audit_status', 0, 'success', '', '', '1', now(), '1', now(), 0),
    (115023, 3, '已驳回',   '30', 'trade_order_audit_status', 0, 'danger',  '', '', '1', now(), '1', now(), 0)
ON CONFLICT (id) DO NOTHING;

-- ---------- 5) 按钮权限（挂在「交易订单」菜单 2076 下） ----------
INSERT INTO system_menu (id, name, permission, type, sort, parent_id, path, icon, component, component_name, status, visible, keep_alive, always_show, creator, create_time, updater, update_time, deleted)
VALUES (11530, '订单提交审核', 'trade:order:audit:submit', 3, 12, 2076, '', '', '', '', 0, TRUE, TRUE, FALSE, '1', now(), '1', now(), 0)
ON CONFLICT (id) DO NOTHING;
