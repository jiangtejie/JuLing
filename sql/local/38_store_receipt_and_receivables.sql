-- ============================================================================
-- 38 门店收货（多收/少收差异）+ 门店库存账 + 门店往来台账（应收 / 预收）
--
-- 依据：docs/store-receipt-and-receivables-design.md
--   · 门店仓：erp_warehouse 增加 warehouse_type / store_customer_id / dept_id，
--     并按门店客户（erp_customer.store_type 非空且无下级）生成「一店一仓」；
--   · 收货单：trade_order_receipt / trade_order_receipt_item（门店确认收货留痕 + 差异）；
--   · 往来台账：erp_customer_account（配送出库→应收，收款核验→冲减，收货差异→调整）；
--   · 要货单行补 delivered_count / receipt_count；订单补 receipt_status；
--   · 出库单行补 source_item_id（要货单行 → 出库单行的行级血缘，用于生成收货单）。
--
-- 幂等：全脚本可重复执行（DDL 用 IF NOT EXISTS，数据用 NOT EXISTS / ON CONFLICT 兜底）。
-- ============================================================================

-- ---------------------------------------------------------------------------
-- 1. 门店仓（erp_warehouse）
-- ---------------------------------------------------------------------------
ALTER TABLE erp_warehouse ADD COLUMN IF NOT EXISTS warehouse_type     varchar(16) NOT NULL DEFAULT 'CENTER';
ALTER TABLE erp_warehouse ADD COLUMN IF NOT EXISTS store_customer_id  bigint;
ALTER TABLE erp_warehouse ADD COLUMN IF NOT EXISTS dept_id            bigint;
COMMENT ON COLUMN erp_warehouse.warehouse_type    IS '仓库类型：CENTER 中心库 / STORE 门店仓';
COMMENT ON COLUMN erp_warehouse.store_customer_id IS '门店仓对应的门店客户（erp_customer.id）；中心库为空';
COMMENT ON COLUMN erp_warehouse.dept_id           IS '门店仓对应的部门（erp_customer.dept_id 冗余，便于按组织过滤）';

CREATE UNIQUE INDEX IF NOT EXISTS uk_erp_warehouse_store_customer
    ON erp_warehouse (store_customer_id) WHERE deleted = 0 AND store_customer_id IS NOT NULL;

-- 1.1 既有仓库归位（默认类型 CENTER）
UPDATE erp_warehouse SET warehouse_type = 'CENTER' WHERE warehouse_type IS NULL OR warehouse_type = '';

-- 1.2 历史「门店虚拟仓-X」的处理（两种去向，二选一，避免同一门店出现两个仓）：
--     (a) 该门店已经有别的门店仓 → 软删这条空的历史仓（仅当它没有库存/批次/流水，有数据一律不动）；
--     (b) 该门店还没有门店仓 → 直接把它补绑成门店仓（保留 id，历史数据零迁移）。
UPDATE erp_warehouse w
SET deleted = 1, updater = 'script38', update_time = now()
FROM erp_customer c
WHERE w.deleted = 0
  AND w.warehouse_type = 'CENTER'
  AND w.store_customer_id IS NULL
  AND w.name LIKE '门店虚拟仓-%'
  AND replace(w.name, '门店虚拟仓-', '') = replace(c.name, '（门店）', '')
  AND c.deleted = 0
  AND c.store_type IS NOT NULL
  AND EXISTS (SELECT 1 FROM erp_warehouse w2 WHERE w2.deleted = 0 AND w2.store_customer_id = c.id)
  AND NOT EXISTS (SELECT 1 FROM erp_stock_batch b WHERE b.warehouse_id = w.id AND b.deleted = 0)
  AND NOT EXISTS (SELECT 1 FROM erp_stock s WHERE s.warehouse_id = w.id AND s.deleted = 0 AND s.count <> 0);

UPDATE erp_warehouse w
SET warehouse_type = 'STORE',
    store_customer_id = c.id,
    dept_id = c.dept_id
FROM erp_customer c
WHERE w.deleted = 0
  AND w.warehouse_type = 'CENTER'
  AND w.store_customer_id IS NULL
  AND w.name LIKE '门店虚拟仓-%'
  AND replace(w.name, '门店虚拟仓-', '') = replace(c.name, '（门店）', '')
  AND c.deleted = 0
  AND c.store_type IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM erp_warehouse w2 WHERE w2.deleted = 0 AND w2.store_customer_id = c.id);

-- 1.3 一店一仓：门店客户 = store_type 非空、非根客户、且没有下级门店（排除代理商）
INSERT INTO erp_warehouse (id, name, address, sort, remark, principal, warehouse_price, truckage_price,
                           status, default_status, warehouse_type, store_customer_id, dept_id,
                           tenant_id, creator, create_time, updater, update_time, deleted)
SELECT nextval('erp_warehouse_seq'),
       '门店仓·' || replace(c.name, '（门店）', ''),
       '', 100, '由 38 脚本按门店客户自动生成', '门店店长', 0, 0,
       0, false, 'STORE', c.id, c.dept_id,
       c.tenant_id, 'script38', now(), 'script38', now(), 0
FROM erp_customer c
WHERE c.deleted = 0
  AND c.store_type IS NOT NULL
  AND c.id <> 1
  AND NOT EXISTS (SELECT 1 FROM erp_customer sub WHERE sub.deleted = 0 AND sub.parent_customer_id = c.id)
  AND NOT EXISTS (SELECT 1 FROM erp_warehouse w WHERE w.deleted = 0 AND w.store_customer_id = c.id);

-- 1.4 去重：同一门店出现多个门店仓时，保留「有库存/流水」且 id 最小的一个，其余（且无库存）软删
WITH dup AS (
    SELECT w.id,
           row_number() OVER (PARTITION BY w.store_customer_id ORDER BY
               CASE WHEN EXISTS (SELECT 1 FROM erp_stock_batch b WHERE b.warehouse_id = w.id AND b.deleted = 0)
                      OR EXISTS (SELECT 1 FROM erp_stock s WHERE s.warehouse_id = w.id AND s.deleted = 0 AND s.count <> 0)
                     THEN 0 ELSE 1 END,
               w.id) AS rn
    FROM erp_warehouse w
    WHERE w.deleted = 0 AND w.warehouse_type = 'STORE' AND w.store_customer_id IS NOT NULL
)
UPDATE erp_warehouse w
SET deleted = 1, updater = 'script38', update_time = now()
FROM dup d
WHERE w.id = d.id
  AND d.rn > 1
  AND NOT EXISTS (SELECT 1 FROM erp_stock_batch b WHERE b.warehouse_id = w.id AND b.deleted = 0)
  AND NOT EXISTS (SELECT 1 FROM erp_stock s WHERE s.warehouse_id = w.id AND s.deleted = 0 AND s.count <> 0);

-- 1.5 中心库（默认仓）不允许是门店仓
UPDATE erp_warehouse SET warehouse_type = 'CENTER', store_customer_id = NULL, dept_id = NULL
WHERE deleted = 0 AND default_status = true;

-- ---------------------------------------------------------------------------
-- 2. 出库单行 ← 要货单行的行级血缘
-- ---------------------------------------------------------------------------
ALTER TABLE erp_sale_out_items ADD COLUMN IF NOT EXISTS source_item_id bigint;
COMMENT ON COLUMN erp_sale_out_items.source_item_id IS '来源业务行 id（门店要货单行 trade_order_item.id；手工出库单为空）';

-- ---------------------------------------------------------------------------
-- 3. 门店收货单
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS trade_order_receipt (
    id              bigint        NOT NULL,
    no              varchar(64)   NOT NULL,
    order_id        bigint        NOT NULL,
    order_no        varchar(64),
    customer_id     bigint,
    dept_id         bigint,
    member_user_id  bigint,
    warehouse_id    bigint,
    sale_out_id     bigint,
    sale_out_no     varchar(64),
    status          smallint      NOT NULL DEFAULT 0,
    diff_type       smallint      NOT NULL DEFAULT 0,
    total_count     numeric(24,6) NOT NULL DEFAULT 0,
    receipt_count   numeric(24,6) NOT NULL DEFAULT 0,
    diff_count      numeric(24,6) NOT NULL DEFAULT 0,
    total_price     numeric(24,2) NOT NULL DEFAULT 0,
    receipt_price   numeric(24,2) NOT NULL DEFAULT 0,
    diff_amount     numeric(24,2) NOT NULL DEFAULT 0,
    receive_time    timestamp,
    receiver_name   varchar(64),
    receiver_mobile varchar(32),
    file_urls       text,
    remark          varchar(500),
    cancel_user_id  bigint,
    cancel_time     timestamp,
    cancel_reason   varchar(500),
    tenant_id       bigint        NOT NULL DEFAULT 0,
    creator         varchar(64)   DEFAULT '',
    create_time     timestamp     NOT NULL DEFAULT now(),
    updater         varchar(64)   DEFAULT '',
    update_time     timestamp     NOT NULL DEFAULT now(),
    deleted         smallint      NOT NULL DEFAULT 0,
    CONSTRAINT pk_trade_order_receipt PRIMARY KEY (id)
);
COMMENT ON TABLE  trade_order_receipt              IS '门店收货单（配送出库后由门店确认收货，含多收/少收/破损差异）';
COMMENT ON COLUMN trade_order_receipt.status       IS '状态：0 待确认 / 10 已确认 / 20 已作废';
COMMENT ON COLUMN trade_order_receipt.diff_type    IS '差异类型：0 无差异 / 1 少收 / 2 多收 / 3 破损 / 4 混合';
COMMENT ON COLUMN trade_order_receipt.diff_count   IS '差异合计（实收 − 应收，正数=多收）';

CREATE UNIQUE INDEX IF NOT EXISTS uk_trade_order_receipt_no
    ON trade_order_receipt (no) WHERE deleted = 0;
-- 一张配送出库单最多一张**有效**收货单：出库单反审核会把收货单置为「已作废」，
-- 之后重新审核要能再生成一张新的，因此唯一索引必须把「已作废(20)」排除在外。
DROP INDEX IF EXISTS uk_trade_order_receipt_sale_out;
CREATE UNIQUE INDEX IF NOT EXISTS uk_trade_order_receipt_sale_out
    ON trade_order_receipt (sale_out_id) WHERE deleted = 0 AND sale_out_id IS NOT NULL AND status <> 20;
CREATE INDEX IF NOT EXISTS idx_trade_order_receipt_order
    ON trade_order_receipt (order_id) WHERE deleted = 0;
CREATE INDEX IF NOT EXISTS idx_trade_order_receipt_customer
    ON trade_order_receipt (customer_id, status) WHERE deleted = 0;

CREATE TABLE IF NOT EXISTS trade_order_receipt_item (
    id              bigint        NOT NULL,
    receipt_id      bigint        NOT NULL,
    order_item_id   bigint        NOT NULL,
    spu_id          bigint,
    sku_id          bigint,
    spu_name        varchar(255),
    properties      varchar(255),
    pic_url         varchar(512),
    product_id      bigint,
    price           numeric(24,2) NOT NULL DEFAULT 0,
    expect_count    numeric(24,6) NOT NULL DEFAULT 0,
    receipt_count   numeric(24,6) NOT NULL DEFAULT 0,
    diff_count      numeric(24,6) NOT NULL DEFAULT 0,
    diff_amount     numeric(24,2) NOT NULL DEFAULT 0,
    diff_reason     varchar(255),
    batch_no        varchar(64),
    production_date date,
    expiry_date     date,
    remark          varchar(500),
    tenant_id       bigint        NOT NULL DEFAULT 0,
    creator         varchar(64)   DEFAULT '',
    create_time     timestamp     NOT NULL DEFAULT now(),
    updater         varchar(64)   DEFAULT '',
    update_time     timestamp     NOT NULL DEFAULT now(),
    deleted         smallint      NOT NULL DEFAULT 0,
    CONSTRAINT pk_trade_order_receipt_item PRIMARY KEY (id)
);
COMMENT ON TABLE  trade_order_receipt_item             IS '门店收货单明细（应收/实收/差异 + 批次效期）';
COMMENT ON COLUMN trade_order_receipt_item.price       IS '配送价（门店进货单位成本，用于门店库存账与差异金额）';
COMMENT ON COLUMN trade_order_receipt_item.diff_count  IS '差异数量（实收 − 应收，正数=多收）';

CREATE INDEX IF NOT EXISTS idx_trade_order_receipt_item_receipt
    ON trade_order_receipt_item (receipt_id) WHERE deleted = 0;
CREATE UNIQUE INDEX IF NOT EXISTS uk_trade_order_receipt_item_order_item
    ON trade_order_receipt_item (receipt_id, order_item_id) WHERE deleted = 0;
CREATE INDEX IF NOT EXISTS idx_trade_order_receipt_item_product
    ON trade_order_receipt_item (product_id) WHERE deleted = 0;

-- ---------------------------------------------------------------------------
-- 4. 门店往来台账（应收 / 收款 / 调整）
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS erp_customer_account (
    id          bigint        NOT NULL,
    customer_id bigint        NOT NULL,
    dept_id     bigint,
    biz_type    smallint      NOT NULL,
    amount      numeric(24,2) NOT NULL,
    balance     numeric(24,2) NOT NULL DEFAULT 0,
    bill_time   timestamp     NOT NULL DEFAULT now(),
    source_type varchar(32),
    source_id   bigint,
    source_no   varchar(64),
    remark      varchar(500),
    tenant_id   bigint        NOT NULL DEFAULT 0,
    creator     varchar(64)   DEFAULT '',
    create_time timestamp     NOT NULL DEFAULT now(),
    updater     varchar(64)   DEFAULT '',
    update_time timestamp     NOT NULL DEFAULT now(),
    deleted     smallint      NOT NULL DEFAULT 0,
    CONSTRAINT pk_erp_customer_account PRIMARY KEY (id)
);
COMMENT ON TABLE  erp_customer_account           IS '门店往来台账：正数=门店欠总部（应收增加），负数=门店已付/应收减少；余额=累计和';
COMMENT ON COLUMN erp_customer_account.biz_type  IS '业务类型：1 配送应收 / 2 直拨应收 / 3 收款（含预收） / 4 收货差异调整 / 5 退货冲减 / 11 配送应收冲销 / 12 直拨应收冲销';
COMMENT ON COLUMN erp_customer_account.balance   IS '记账后余额快照（同一门店串行记账，事务内取号后用 pg_advisory_xact_lock 保证）';

CREATE INDEX IF NOT EXISTS idx_erp_customer_account_customer
    ON erp_customer_account (customer_id, id) WHERE deleted = 0;
-- 注意：**不做** (biz_type, source_type, source_id) 唯一索引。
-- 门店往来的幂等靠「目标净额 − 已挂账净额」的差额法（见 ErpCustomerAccountService#record 注释）：
-- 「配送出库审核 → 反审核 → 重新审核」会产生 +金额 / −金额 / +金额 三笔，
-- 若用唯一键去重，第三笔会被误判成重复而漏记，门店应收凭空少一笔。
DROP INDEX IF EXISTS uk_erp_customer_account_source;
CREATE INDEX IF NOT EXISTS idx_erp_customer_account_source
    ON erp_customer_account (source_type, source_id) WHERE deleted = 0 AND source_id IS NOT NULL;

-- ---------------------------------------------------------------------------
-- 5. 序列
-- ---------------------------------------------------------------------------
CREATE SEQUENCE IF NOT EXISTS trade_order_receipt_seq;
CREATE SEQUENCE IF NOT EXISTS trade_order_receipt_item_seq;
CREATE SEQUENCE IF NOT EXISTS erp_customer_account_seq;
SELECT setval('trade_order_receipt_seq',      COALESCE((SELECT max(id) FROM trade_order_receipt), 0) + 1, false);
SELECT setval('trade_order_receipt_item_seq', COALESCE((SELECT max(id) FROM trade_order_receipt_item), 0) + 1, false);
SELECT setval('erp_customer_account_seq',     COALESCE((SELECT max(id) FROM erp_customer_account), 0) + 1, false);

-- ---------------------------------------------------------------------------
-- 6. 商城订单 / 订单行补字段
-- ---------------------------------------------------------------------------
ALTER TABLE trade_order      ADD COLUMN IF NOT EXISTS receipt_status  smallint      NOT NULL DEFAULT 0;
ALTER TABLE trade_order_item ADD COLUMN IF NOT EXISTS delivered_count numeric(24,6) NOT NULL DEFAULT 0;
ALTER TABLE trade_order_item ADD COLUMN IF NOT EXISTS receipt_count   numeric(24,6) NOT NULL DEFAULT 0;
COMMENT ON COLUMN trade_order.receipt_status           IS '收货状态：0 未收货 / 10 部分收货 / 20 已收货';
COMMENT ON COLUMN trade_order_item.delivered_count     IS 'ERP 已发货数量（配送出库单审核后回写）';
COMMENT ON COLUMN trade_order_item.receipt_count       IS '门店已确认收货数量';

-- ---------------------------------------------------------------------------
-- 7. 菜单与权限
-- ---------------------------------------------------------------------------
-- 7.1 订单中心 → 门店收货单
INSERT INTO system_menu (id, name, permission, type, sort, parent_id, path, icon, component, component_name,
                         status, visible, keep_alive, always_show, creator, create_time, updater, update_time, deleted)
SELECT 12100, '门店收货单', '', 2, 3, 2072, 'store-receipt', 'lucide:package-check',
       'mall/trade/receipt/index', 'TradeStoreReceipt', 0, true, true, true,
       'script38', now(), 'script38', now(), 0
WHERE NOT EXISTS (SELECT 1 FROM system_menu WHERE id = 12100);

INSERT INTO system_menu (id, name, permission, type, sort, parent_id, path, icon, component, component_name,
                         status, visible, keep_alive, always_show, creator, create_time, updater, update_time, deleted)
SELECT v.id, v.name, v.permission, 3, v.sort, 12100, '', '', '', '', 0, true, true, true,
       'script38', now(), 'script38', now(), 0
FROM (VALUES (12101, '门店收货单查询', 'trade:store-receipt:query',  1),
             (12102, '门店收货单代录', 'trade:store-receipt:create', 2),
             (12103, '门店收货单作废', 'trade:store-receipt:cancel', 3),
             (12104, '门店收货单导出', 'trade:store-receipt:export', 4)
     ) AS v(id, name, permission, sort)
WHERE NOT EXISTS (SELECT 1 FROM system_menu WHERE id = v.id);

-- 7.2 库存管理 → 门店库存
INSERT INTO system_menu (id, name, permission, type, sort, parent_id, path, icon, component, component_name,
                         status, visible, keep_alive, always_show, creator, create_time, updater, update_time, deleted)
SELECT 12110, '门店库存', '', 2, 8, 2583, 'store-stock', 'lucide:store',
       'erp/stock/store/index', 'ErpStoreStock', 0, true, true, true,
       'script38', now(), 'script38', now(), 0
WHERE NOT EXISTS (SELECT 1 FROM system_menu WHERE id = 12110);

INSERT INTO system_menu (id, name, permission, type, sort, parent_id, path, icon, component, component_name,
                         status, visible, keep_alive, always_show, creator, create_time, updater, update_time, deleted)
SELECT 12111, '门店库存查询', 'erp:stock:store:query', 3, 1, 12110, '', '', '', '', 0, true, true, true,
       'script38', now(), 'script38', now(), 0
WHERE NOT EXISTS (SELECT 1 FROM system_menu WHERE id = 12111);

-- 7.3 财务 → 门店往来台账（挂到「收款单」同级菜单下，父菜单按权限反查，避免硬编码）
INSERT INTO system_menu (id, name, permission, type, sort, parent_id, path, icon, component, component_name,
                         status, visible, keep_alive, always_show, creator, create_time, updater, update_time, deleted)
SELECT 12120, '门店往来', '', 2, 20,
       COALESCE((SELECT parent_id FROM system_menu
                  WHERE permission = 'erp:finance-receipt:query' AND deleted = 0 LIMIT 1), 2563),
       'customer-account', 'lucide:wallet',
       'erp/finance/customeraccount/index', 'ErpCustomerAccount', 0, true, true, true,
       'script38', now(), 'script38', now(), 0
WHERE NOT EXISTS (SELECT 1 FROM system_menu WHERE id = 12120);

INSERT INTO system_menu (id, name, permission, type, sort, parent_id, path, icon, component, component_name,
                         status, visible, keep_alive, always_show, creator, create_time, updater, update_time, deleted)
SELECT v.id, v.name, v.permission, 3, v.sort, 12120, '', '', '', '', 0, true, true, true,
       'script38', now(), 'script38', now(), 0
FROM (VALUES (12121, '门店往来查询', 'erp:customer-account:query',  1),
             (12122, '门店往来记账', 'erp:customer-account:create', 2),
             (12123, '门店往来导出', 'erp:customer-account:export', 3)
     ) AS v(id, name, permission, sort)
WHERE NOT EXISTS (SELECT 1 FROM system_menu WHERE id = v.id);

-- 7.4 角色授权：凡是已拥有同级父菜单的角色，一并授予新菜单（含祖先链，避免「能调通看不到」）
INSERT INTO system_role_menu (id, role_id, menu_id, creator, create_time, updater, update_time, deleted, tenant_id)
SELECT nextval('system_role_menu_seq'), rm.role_id, m.id, 'script38', now(), 'script38', now(), 0, rm.tenant_id
FROM (SELECT DISTINCT role_id, tenant_id FROM system_role_menu WHERE deleted = 0 AND menu_id IN (2072, 2583)) rm
CROSS JOIN (SELECT 12100 AS id UNION ALL SELECT 12101 UNION ALL SELECT 12102 UNION ALL SELECT 12103
            UNION ALL SELECT 12104 UNION ALL SELECT 12110 UNION ALL SELECT 12111
            UNION ALL SELECT 12120 UNION ALL SELECT 12121 UNION ALL SELECT 12122 UNION ALL SELECT 12123) m
WHERE NOT EXISTS (SELECT 1 FROM system_role_menu x
                   WHERE x.deleted = 0 AND x.role_id = rm.role_id AND x.menu_id = m.id);

-- 7.5 已授权菜单的祖先链补齐（门店往来挂在财务下，若角色未授父菜单则整棵不可见）
WITH RECURSIVE need AS (
    SELECT id, parent_id FROM system_menu WHERE id IN (12100, 12110, 12120) AND deleted = 0
    UNION ALL
    SELECT m.id, m.parent_id FROM system_menu m JOIN need n ON m.id = n.parent_id WHERE m.deleted = 0
)
INSERT INTO system_role_menu (id, role_id, menu_id, creator, create_time, updater, update_time, deleted, tenant_id)
SELECT nextval('system_role_menu_seq'), rm.role_id, n.id, 'script38', now(), 'script38', now(), 0, rm.tenant_id
FROM (SELECT DISTINCT role_id, tenant_id FROM system_role_menu WHERE deleted = 0 AND menu_id IN (12100, 12110, 12120)) rm
CROSS JOIN need n
WHERE NOT EXISTS (SELECT 1 FROM system_role_menu x
                   WHERE x.deleted = 0 AND x.role_id = rm.role_id AND x.menu_id = n.id);

-- ---------------------------------------------------------------------------
-- 8. 自检
-- ---------------------------------------------------------------------------
SELECT '门店仓' AS item, count(*)::text AS value FROM erp_warehouse WHERE deleted = 0 AND warehouse_type = 'STORE'
UNION ALL SELECT '中心库', count(*)::text FROM erp_warehouse WHERE deleted = 0 AND warehouse_type = 'CENTER'
UNION ALL SELECT '新增菜单', count(*)::text FROM system_menu WHERE id IN (12100,12101,12102,12103,12104,12110,12111,12120,12121,12122,12123)
UNION ALL SELECT '菜单授权', count(*)::text FROM system_role_menu WHERE deleted = 0 AND menu_id BETWEEN 12100 AND 12123;
