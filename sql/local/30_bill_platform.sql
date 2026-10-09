-- =============================================================================
-- 单据基座（Bill Platform）—— 平台化的单据地基
--
-- 目标：把"每张单据各写一套 CRUD"改为"统一基座 + 单据只声明差异"，支撑后续 20+ 张单据
--       （采购/入库/出库/调拨/盘点/报损/门店收货/直配/自采/应收应付…）与后期财务凭证。
--
-- 六件套：
--   1) bill_type    单据类型注册表（编号规则、是否审批/影响库存/影响核算、BPM 流程 key）
--   2) bill_no_seq  单号流水（按 类型×组织×期间 递增，支持按日/月/年/不重置）
--   3) bill_relation 单据关联（上溯下推 + 防重复下推，头级与行级都支持）
--   4) bill_log     单据操作日志（操作类型/前后状态/操作人）
--   5) bill_ext     单据扩展字段（key-value，小需求不改表）
--   6) 状态机在代码里（BillStatusEnum + 迁移校验），本脚本只落库表
--
-- 幂等：CREATE TABLE IF NOT EXISTS + ON CONFLICT DO NOTHING
-- 执行：psql -U root -d yate -f sql/local/30_bill_platform.sql
-- =============================================================================

-- ---------- 1) 单据类型注册表 ----------
CREATE TABLE IF NOT EXISTS bill_type (
    id                 bigint NOT NULL PRIMARY KEY,
    code               varchar(64)  NOT NULL,
    name               varchar(64)  NOT NULL,
    module             varchar(32)  DEFAULT '',
    no_prefix          varchar(16)  DEFAULT '',
    no_date_format     varchar(16)  DEFAULT 'yyyyMMdd',
    no_reset           varchar(8)   DEFAULT 'D',
    no_seq_length      smallint     DEFAULT 4,
    need_audit         boolean      DEFAULT FALSE,
    bpm_process_key    varchar(64)  DEFAULT '',
    affect_stock       boolean      DEFAULT FALSE,
    affect_finance     boolean      DEFAULT FALSE,
    status             smallint     DEFAULT 0,
    sort               integer      DEFAULT 0,
    remark             varchar(255) DEFAULT '',
    tenant_id          bigint       NOT NULL DEFAULT 0,
    creator            varchar(64)  DEFAULT '',
    create_time        timestamp    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updater            varchar(64)  DEFAULT '',
    update_time        timestamp    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted            smallint     NOT NULL DEFAULT 0
);
CREATE UNIQUE INDEX IF NOT EXISTS uk_bill_type_code ON bill_type (code, tenant_id) WHERE deleted = 0;
COMMENT ON COLUMN bill_type.no_reset IS '重置周期：D 按日 / M 按月 / Y 按年 / N 不重置';
COMMENT ON COLUMN bill_type.no_seq_length IS '流水号位数，左补零';
COMMENT ON COLUMN bill_type.affect_finance IS '是否产生会计事件（后期凭证引擎据此过滤）';

-- ---------- 2) 单号流水 ----------
CREATE TABLE IF NOT EXISTS bill_no_seq (
    id          bigint NOT NULL PRIMARY KEY,
    bill_type   varchar(64) NOT NULL,
    org_id      bigint      NOT NULL DEFAULT 0,
    period      varchar(16) NOT NULL,
    last_no     bigint      NOT NULL DEFAULT 0,
    tenant_id   bigint      NOT NULL DEFAULT 0,
    creator     varchar(64) DEFAULT '',
    create_time timestamp   NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updater     varchar(64) DEFAULT '',
    update_time timestamp   NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted     smallint    NOT NULL DEFAULT 0
);
CREATE UNIQUE INDEX IF NOT EXISTS uk_bill_no_seq ON bill_no_seq (bill_type, org_id, period, tenant_id) WHERE deleted = 0;

-- ---------- 3) 单据关联（下推） ----------
CREATE TABLE IF NOT EXISTS bill_relation (
    id             bigint NOT NULL PRIMARY KEY,
    source_type    varchar(64) NOT NULL,
    source_id      bigint      NOT NULL,
    source_no      varchar(64) DEFAULT '',
    source_item_id bigint,
    target_type    varchar(64) NOT NULL,
    target_id      bigint      NOT NULL,
    target_no      varchar(64) DEFAULT '',
    target_item_id bigint,
    qty            numeric(24, 6),
    status         smallint    DEFAULT 0,
    remark         varchar(255) DEFAULT '',
    tenant_id      bigint      NOT NULL DEFAULT 0,
    creator        varchar(64) DEFAULT '',
    create_time    timestamp   NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updater        varchar(64) DEFAULT '',
    update_time    timestamp   NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted        smallint    NOT NULL DEFAULT 0
);
CREATE INDEX IF NOT EXISTS idx_bill_relation_source ON bill_relation (source_type, source_id);
CREATE INDEX IF NOT EXISTS idx_bill_relation_target ON bill_relation (target_type, target_id);
CREATE UNIQUE INDEX IF NOT EXISTS uk_bill_relation ON bill_relation (source_type, source_id, COALESCE(source_item_id, 0), target_type, target_id, COALESCE(target_item_id, 0), tenant_id) WHERE deleted = 0;
COMMENT ON COLUMN bill_relation.qty IS '下推数量（行级关联时必填，用于防超推）';

-- ---------- 4) 单据操作日志 ----------
CREATE TABLE IF NOT EXISTS bill_log (
    id            bigint NOT NULL PRIMARY KEY,
    bill_type     varchar(64) NOT NULL,
    bill_id       bigint      NOT NULL,
    bill_no       varchar(64) DEFAULT '',
    operate_type  varchar(32) NOT NULL,
    before_status smallint,
    after_status  smallint,
    operator_id   bigint,
    operator_name varchar(64) DEFAULT '',
    operate_time  timestamp   NOT NULL DEFAULT CURRENT_TIMESTAMP,
    remark        varchar(500) DEFAULT '',
    tenant_id     bigint      NOT NULL DEFAULT 0,
    creator       varchar(64) DEFAULT '',
    create_time   timestamp   NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updater       varchar(64) DEFAULT '',
    update_time   timestamp   NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted       smallint    NOT NULL DEFAULT 0
);
CREATE INDEX IF NOT EXISTS idx_bill_log_bill ON bill_log (bill_type, bill_id);

-- ---------- 5) 单据扩展字段 ----------
CREATE TABLE IF NOT EXISTS bill_ext (
    id          bigint NOT NULL PRIMARY KEY,
    bill_type   varchar(64) NOT NULL,
    bill_id     bigint      NOT NULL,
    field_key   varchar(64) NOT NULL,
    field_value text,
    field_type  varchar(16) DEFAULT 'string',
    tenant_id   bigint      NOT NULL DEFAULT 0,
    creator     varchar(64) DEFAULT '',
    create_time timestamp   NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updater     varchar(64) DEFAULT '',
    update_time timestamp   NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted     smallint    NOT NULL DEFAULT 0
);
CREATE UNIQUE INDEX IF NOT EXISTS uk_bill_ext ON bill_ext (bill_type, bill_id, field_key, tenant_id) WHERE deleted = 0;

-- ---------- 5.5) 主键兜底（已存在的表补主键，幂等） ----------
-- 说明：PostgreSQL 的 ON CONFLICT (id) 需要唯一约束；本仓库历史上有 453 张表缺主键
--       （见 sql/local/15_add_missing_primary_keys.sql），新表一律显式建主键。
DO $$
DECLARE t text;
BEGIN
  FOREACH t IN ARRAY ARRAY['bill_type', 'bill_no_seq', 'bill_relation', 'bill_log', 'bill_ext'] LOOP
    IF NOT EXISTS (
      SELECT 1 FROM pg_constraint c JOIN pg_class r ON r.oid = c.conrelid
      WHERE r.relname = t AND c.contype = 'p'
    ) THEN
      EXECUTE format('ALTER TABLE %I ADD CONSTRAINT pk_%s PRIMARY KEY (id)', t, t);
      RAISE NOTICE '已为 % 补主键', t;
    END IF;
  END LOOP;
END $$;

-- ---------- 6) 单据类型种子（与蓝图流程对应） ----------
INSERT INTO bill_type (id, code, name, module, no_prefix, no_date_format, no_reset, no_seq_length, need_audit, bpm_process_key, affect_stock, affect_finance, status, sort, remark, tenant_id, creator, create_time, updater, update_time, deleted) VALUES
 (1,  'PURCHASE_REQ',      '采购申请单',     'erp', 'CGSQ', 'yyyyMMdd', 'D', 4, TRUE,  '', FALSE, FALSE, 0, 10, 'CY-013 前置', 1, '1', now(), '1', now(), 0),
 (2,  'PURCHASE_ORDER',    '采购订单',       'erp', 'CGDD', 'yyyyMMdd', 'D', 4, TRUE,  '', FALSE, FALSE, 0, 20, 'CY-013', 1, '1', now(), '1', now(), 0),
 (3,  'PURCHASE_IN',       '采购入库单',     'erp', 'CGRK', 'yyyyMMdd', 'D', 4, TRUE,  '', TRUE,  TRUE,  0, 30, 'CY-013 入库（自动生成应付）', 1, '1', now(), '1', now(), 0),
 (4,  'PURCHASE_RETURN',   '采购退货单',     'erp', 'CGTH', 'yyyyMMdd', 'D', 4, TRUE,  '', TRUE,  TRUE,  0, 40, 'CY-013', 1, '1', now(), '1', now(), 0),
 (5,  'RECEIPT_NOTICE',    '收料通知单',     'erp', 'SLTZ', 'yyyyMMdd', 'D', 4, FALSE, '', FALSE, FALSE, 0, 50, 'CY-013 采购订单→收料通知', 1, '1', now(), '1', now(), 0),
 (6,  'QUALITY_INSPECT',   '检验单',         'erp', 'JYD',  'yyyyMMdd', 'D', 4, TRUE,  '', FALSE, FALSE, 0, 60, 'CY-013 可复用 MES 质检', 1, '1', now(), '1', now(), 0),
 (7,  'STORE_REQUISITION', '门店要货申请单', 'mall','YH',   'yyyyMMdd', 'D', 4, FALSE, '', FALSE, FALSE, 0, 70, 'CY-002 商城订单即要货申请（S1 已实现）', 1, '1', now(), '1', now(), 0),
 (8,  'DELIVERY_OUT',      '配送出库单',     'erp', 'PSCK', 'yyyyMMdd', 'D', 4, TRUE,  '', TRUE,  TRUE,  0, 80, 'CY-002 统配', 1, '1', now(), '1', now(), 0),
 (9,  'STORE_RECEIPT',     '门店收货单',     'erp', 'MDSH', 'yyyyMMdd', 'D', 4, TRUE,  '', TRUE,  TRUE,  0, 90, 'CY-002 门店收货（多收/少收差异）', 1, '1', now(), '1', now(), 0),
 (10, 'DELIVERY_DIFF',     '配送异常通知单', 'erp', 'PSYC', 'yyyyMMdd', 'D', 4, TRUE,  '', FALSE, FALSE, 0, 100, 'CY-003/004', 1, '1', now(), '1', now(), 0),
 (11, 'DELIVERY_SUPPLEMENT','配送补货单',    'erp', 'PSBH', 'yyyyMMdd', 'D', 4, TRUE,  '', TRUE,  TRUE,  0, 110, 'CY-003/004', 1, '1', now(), '1', now(), 0),
 (12, 'STORE_RETURN',      '门店退货申请单', 'erp', 'MDTH', 'yyyyMMdd', 'D', 4, TRUE,  '', FALSE, FALSE, 0, 120, 'CY-005 必须源单', 1, '1', now(), '1', now(), 0),
 (13, 'STORE_RETURN_OUT',  '配送退货单',     'erp', 'PSTH', 'yyyyMMdd', 'D', 4, TRUE,  '', TRUE,  TRUE,  0, 130, 'CY-005', 1, '1', now(), '1', now(), 0),
 (14, 'STORE_SCRAP',       '报损出库单',     'erp', 'BS',   'yyyyMMdd', 'D', 4, TRUE,  '', TRUE,  TRUE,  0, 140, 'CY-010', 1, '1', now(), '1', now(), 0),
 (15, 'DIRECT_SALE',       '门店直拨单',     'erp', 'ZB',   'yyyyMMdd', 'D', 4, TRUE,  '', TRUE,  TRUE,  0, 150, 'CY-006 供应商直送门店（内部配送出库 执行系统=N）', 1, '1', now(), '1', now(), 0),
 (16, 'STORE_SELF_PURCHASE','门店自采单',    'erp', 'MDZC', 'yyyyMMdd', 'D', 4, TRUE,  '', TRUE,  TRUE,  0, 160, 'CY-007', 1, '1', now(), '1', now(), 0),
 (17, 'STOCK_TRANSFER',    '调拨单',         'erp', 'DB',   'yyyyMMdd', 'D', 4, TRUE,  '', TRUE,  TRUE,  0, 170, 'CY-008 跨组织分调出/调入两张', 1, '1', now(), '1', now(), 0),
 (18, 'STOCK_CHECK',       '盘点单',         'erp', 'PD',   'yyyyMMdd', 'D', 4, TRUE,  '', FALSE, FALSE, 0, 180, 'CY-009', 1, '1', now(), '1', now(), 0),
 (19, 'STOCK_CHECK_PROFIT', '盘盈单',        'erp', 'PY',   'yyyyMMdd', 'D', 4, TRUE,  '', TRUE,  TRUE,  0, 190, 'CY-009', 1, '1', now(), '1', now(), 0),
 (20, 'STOCK_CHECK_LOSS',  '盘亏单',         'erp', 'PK',   'yyyyMMdd', 'D', 4, TRUE,  '', TRUE,  TRUE,  0, 200, 'CY-009', 1, '1', now(), '1', now(), 0),
 (21, 'PAYABLE',           '应付单',         'erp', 'YF',   'yyyyMMdd', 'D', 4, TRUE,  '', FALSE, TRUE,  0, 210, 'CY-016', 1, '1', now(), '1', now(), 0),
 (22, 'RECEIVABLE',        '应收单',         'erp', 'YS',   'yyyyMMdd', 'D', 4, TRUE,  '', FALSE, TRUE,  0, 220, 'CY-002 配送出库→应收', 1, '1', now(), '1', now(), 0),
 (23, 'FINANCE_PAYMENT',   '付款单',         'erp', 'FK',   'yyyyMMdd', 'D', 4, TRUE,  '', FALSE, TRUE,  0, 230, 'CY-016', 1, '1', now(), '1', now(), 0),
 (24, 'FINANCE_RECEIPT',   '收款单',         'erp', 'SK',   'yyyyMMdd', 'D', 4, TRUE,  '', FALSE, TRUE,  0, 240, '线下收款核验配套', 1, '1', now(), '1', now(), 0),
 (25, 'OTHER_IN',          '其他入库单',     'erp', 'QTRK', 'yyyyMMdd', 'D', 4, TRUE,  '', TRUE,  TRUE,  0, 250, '兜底（需人工填金额）', 1, '1', now(), '1', now(), 0),
 (26, 'OTHER_OUT',         '其他出库单',     'erp', 'QTCK', 'yyyyMMdd', 'D', 4, TRUE,  '', TRUE,  TRUE,  0, 260, '兜底', 1, '1', now(), '1', now(), 0)
ON CONFLICT (id) DO NOTHING;

-- ---------- 7) 序列（yudao 用 @KeySequence + IdType.INPUT，需显式建序列） ----------
CREATE SEQUENCE IF NOT EXISTS bill_type_seq START 100;
CREATE SEQUENCE IF NOT EXISTS bill_no_seq_seq START 1;
CREATE SEQUENCE IF NOT EXISTS bill_relation_seq START 1;
CREATE SEQUENCE IF NOT EXISTS bill_log_seq START 1;
CREATE SEQUENCE IF NOT EXISTS bill_ext_seq START 1;
SELECT setval('bill_type_seq', (SELECT COALESCE(MAX(id), 1) FROM bill_type), true);
