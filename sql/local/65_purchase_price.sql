-- ============================================================================
-- 65 采购价目表（头 + 明细）
--
-- 背景：目前 `erp_product.purchase_price» 是**一个物料一个采购价**，表达不了采购天天遇到的三件事：
--   · 同一物料不同供应商不同价   · 同一供应商调价（要有效期）   · 量大价优（阶梯价）
--   后果不是「少个功能」，而是采购下单只能手工改单价 —— 而**采购单价直接决定存货成本**：
--     采购订单行 product_price → 采购入库行 product_price
--     → ErpPurchaseInServiceImpl:247  inReqBO.setUnitCost(...)
--     → ErpStockBatchServiceImpl:129  batch.setUnitCost(...)
--     → 出库/领用成本 = batch.unit_cost × qty
--   即：**填错的价一路进到成本，且无据可查**。价目表就是让订单价有据可依。
--
-- 模型（对齐金蝶的「价目表 + 价目表明细」）：
--   头 erp_purchase_price      —— 编码/名称/供应商(可空=通用)/默认/状态/有效期
--   行 erp_purchase_price_item —— 物料/数量区间/单价(不含税)/税率
--
-- 两处**有意收敛**（不照搬金蝶）：
--   1) 不存「含税单价」：金蝶存 单价+含税单价+税率% 三个，其中一个是冗余的，两处存必然漂移。
--      只存不含税单价 + 税率，含税单价是计算值（界面仍可录含税价，自动换算）。
--      与本仓库订单行的 productPrice/taxPercent/taxPrice 口径一致。
--   2) 不要「计价单位」列：金蝶有它是因为一个物料可多单位；本系统 erp_product 只有一个 unit_id，
--      计价单位由物料决定，展示时取物料的单位即可。
--
-- 与采购订单的关系：订单**只存快照价，不引用价目表 id** —— 价目表改了历史订单不受影响，
--   也因此价目表删除无需引用校验。
--
-- 归口：菜单挂在「基础资料 → 公共资料」下，与结算账户、物料单位同层 —— 它是采购/财务都要引用的
--   价格主数据，符合「主数据集中维护、子系统引用」的归口原则（金蝶放在采购管理下，是有意不同）。
--
-- 幂等：可重复执行。
-- ============================================================================

BEGIN;

-- ---------------------------------------------------------------------------
-- 1) 建表
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS erp_purchase_price (
    id             bigint       NOT NULL,
    code           varchar(32),
    name           varchar(64)  NOT NULL,
    supplier_id    bigint,
    is_default     boolean      NOT NULL DEFAULT false,
    status         int4         NOT NULL DEFAULT 0,
    effective_date date,
    expiry_date    date,
    remark         varchar(255),
    tenant_id      bigint       NOT NULL DEFAULT 0,
    creator        varchar(64)  DEFAULT '',
    create_time    timestamp    NOT NULL DEFAULT now(),
    updater        varchar(64)  DEFAULT '',
    update_time    timestamp    NOT NULL DEFAULT now(),
    deleted        int2         NOT NULL DEFAULT 0,
    CONSTRAINT pk_erp_purchase_price PRIMARY KEY (id)
);
CREATE SEQUENCE IF NOT EXISTS erp_purchase_price_seq;

CREATE TABLE IF NOT EXISTS erp_purchase_price_item (
    id          bigint        NOT NULL,
    price_id    bigint        NOT NULL,
    product_id  bigint        NOT NULL,
    from_qty    numeric(24,6),
    to_qty      numeric(24,6),
    price       numeric(24,6) NOT NULL DEFAULT 0,
    tax_percent numeric(24,6),
    remark      varchar(255),
    tenant_id   bigint        NOT NULL DEFAULT 0,
    creator     varchar(64)   DEFAULT '',
    create_time timestamp     NOT NULL DEFAULT now(),
    updater     varchar(64)   DEFAULT '',
    update_time timestamp     NOT NULL DEFAULT now(),
    deleted     int2          NOT NULL DEFAULT 0,
    CONSTRAINT pk_erp_purchase_price_item PRIMARY KEY (id)
);
CREATE SEQUENCE IF NOT EXISTS erp_purchase_price_item_seq;

CREATE INDEX IF NOT EXISTS idx_erp_purchase_price_supplier      ON erp_purchase_price (supplier_id);
CREATE INDEX IF NOT EXISTS idx_erp_purchase_price_item_price_id ON erp_purchase_price_item (price_id);
CREATE INDEX IF NOT EXISTS idx_erp_purchase_price_item_product  ON erp_purchase_price_item (product_id);

-- ---------------------------------------------------------------------------
-- 2) 注释
-- ---------------------------------------------------------------------------
COMMENT ON TABLE  erp_purchase_price                 IS '采购价目表（头）：一套报价的容器，带供应商/有效期/默认标记';
COMMENT ON COLUMN erp_purchase_price.code            IS '业务编码（编码规则 erp_purchase_price，前缀 CJJM）';
COMMENT ON COLUMN erp_purchase_price.supplier_id     IS '供应商编号；**为空表示通用价目表**（不限供应商，优先级低于供应商专项）';
COMMENT ON COLUMN erp_purchase_price.is_default      IS '是否默认价目表（同层级内优先取它）';
COMMENT ON COLUMN erp_purchase_price.status          IS '状态：0 启用 / 1 停用（仅启用中的价目表参与取价）';
COMMENT ON COLUMN erp_purchase_price.effective_date  IS '生效日期（为空表示不限）';
COMMENT ON COLUMN erp_purchase_price.expiry_date     IS '失效日期（为空表示长期有效）';
COMMENT ON TABLE  erp_purchase_price_item            IS '采购价目表明细（行）：一个物料一档价，支持数量区间做阶梯价';
COMMENT ON COLUMN erp_purchase_price_item.product_id IS '物料编号';
COMMENT ON COLUMN erp_purchase_price_item.from_qty   IS '数量区间起（含）；为空表示不限下界';
COMMENT ON COLUMN erp_purchase_price_item.to_qty     IS '数量区间止（不含）；为空表示不限上界';
COMMENT ON COLUMN erp_purchase_price_item.price      IS '单价（**不含税**，权威值）；含税单价 = price × (1 + tax_percent/100)，是计算值不落库';
COMMENT ON COLUMN erp_purchase_price_item.tax_percent IS '税率(%)，如 13';

-- ---------------------------------------------------------------------------
-- 3) 编码规则
-- ---------------------------------------------------------------------------
INSERT INTO system_code_rule (id, rule_key, name, prefix, seq_length, current_value, remark, tenant_id, creator, create_time, updater, update_time, deleted)
VALUES (7, 'erp_purchase_price', '采购价目表编码', 'CJJM', 4, 0, '一套报价一个编码', 1, 'script65', now(), 'script65', now(), 0)
ON CONFLICT (id) DO NOTHING;

-- ---------------------------------------------------------------------------
-- 4) 菜单：基础资料(12180) → 公共资料(12182) → 采购价目表
-- ---------------------------------------------------------------------------
INSERT INTO system_menu (id, name, permission, type, sort, parent_id, path, icon, component, component_name,
                         status, visible, keep_alive, always_show, creator, create_time, updater, update_time, deleted)
SELECT 12200, '采购价目表', '', 2, 5, 12182, 'purchase-price', 'lucide:tags', 'erp/purchase/price/index', 'ErpPurchasePrice',
       0, true, true, true, 'script65', now(), 'script65', now(), 0
WHERE EXISTS (SELECT 1 FROM system_menu WHERE id = 12182 AND deleted = 0)
  AND NOT EXISTS (SELECT 1 FROM system_menu WHERE id = 12200);

INSERT INTO system_menu (id, name, permission, type, sort, parent_id, path, icon, component, component_name,
                         status, visible, keep_alive, always_show, creator, create_time, updater, update_time, deleted)
SELECT v.id, v.name, v.perm, 3, v.sort, 12200, '', '', NULL, NULL,
       0, true, true, true, 'script65', now(), 'script65', now(), 0
FROM (VALUES (12201, '采购价目表查询', 'erp:purchase-price:query',  1),
             (12202, '采购价目表创建', 'erp:purchase-price:create', 2),
             (12203, '采购价目表更新', 'erp:purchase-price:update', 3),
             (12204, '采购价目表删除', 'erp:purchase-price:delete', 4),
             (12205, '采购价目表导出', 'erp:purchase-price:export', 5)) AS v(id, name, perm, sort)
WHERE EXISTS (SELECT 1 FROM system_menu WHERE id = 12200 AND deleted = 0)
  AND NOT EXISTS (SELECT 1 FROM system_menu WHERE id = v.id);

-- ---------------------------------------------------------------------------
-- 5) 授权：给已拥有「基础资料」(12180) 的角色补上（含祖先链）
-- ---------------------------------------------------------------------------
WITH RECURSIVE need AS (
    SELECT id, parent_id FROM system_menu WHERE id = 12200 AND deleted = 0
    UNION ALL SELECT m.id, m.parent_id FROM system_menu m JOIN need n ON m.id = n.parent_id WHERE m.deleted = 0
), target_role AS (
    SELECT DISTINCT rm.role_id, rm.tenant_id FROM system_role_menu rm WHERE rm.deleted = 0 AND rm.menu_id = 12180
), want AS (
    SELECT id FROM need UNION ALL SELECT 12201 UNION ALL SELECT 12202 UNION ALL SELECT 12203
    UNION ALL SELECT 12204 UNION ALL SELECT 12205
)
INSERT INTO system_role_menu (id, role_id, menu_id, creator, create_time, updater, update_time, deleted, tenant_id)
SELECT nextval('system_role_menu_seq'), t.role_id, w.id, 'script65', now(), 'script65', now(), 0, t.tenant_id
FROM target_role t CROSS JOIN want w
WHERE NOT EXISTS (SELECT 1 FROM system_role_menu x
                   WHERE x.deleted = 0 AND x.role_id = t.role_id AND x.menu_id = w.id);

SELECT setval('system_menu_seq', (SELECT COALESCE(MAX(id), 1) FROM system_menu), true);
SELECT setval('system_code_rule_seq', (SELECT COALESCE(MAX(id), 1) FROM system_code_rule), true);

-- ---------------------------------------------------------------------------
-- 6) 顺带补齐：物料主数据的业务编码
--
-- 起因：做价目表时发现 erp_product **没有业务编码** —— 而客户/供应商/仓库/计量单位/商品
--   五个主数据都有（见 sql/local/56_code_rule.sql），唯独物料漏了。金蝶的价目表里
--   「物料编码」正是行的主标识，没有它价目表只能显示名称，同名物料无法区分。
--   这里按同一套机制补上（规则表 + code 列 + 回填 + 唯一索引）。
-- ---------------------------------------------------------------------------
ALTER TABLE erp_product ADD COLUMN IF NOT EXISTS code varchar(32);
COMMENT ON COLUMN erp_product.code IS '物料编码（编码规则 WL + 6 位流水；租户内唯一。见 sql/local/56_code_rule.sql）';

INSERT INTO system_code_rule (id, rule_key, name, prefix, seq_length, current_value, remark, tenant_id, creator, create_time, updater, update_time, deleted)
VALUES (8, 'erp_product', '物料编码', 'WL', 6, 0, 'ERP 物料主数据', 1, 'script65', now(), 'script65', now(), 0)
ON CONFLICT (id) DO NOTHING;

UPDATE erp_product t SET code = r.prefix || lpad(s.rn::text, r.seq_length, '0')
FROM (SELECT id, row_number() OVER (ORDER BY id) AS rn FROM erp_product WHERE code IS NULL) s,
     (SELECT prefix, seq_length FROM system_code_rule WHERE rule_key = 'erp_product' AND deleted = 0) r
WHERE t.id = s.id;

CREATE UNIQUE INDEX IF NOT EXISTS uk_erp_product_code ON erp_product (tenant_id, code) WHERE deleted = 0 AND code IS NOT NULL;

UPDATE system_code_rule r SET current_value = COALESCE((SELECT max(right(t.code, r.seq_length)::bigint) FROM erp_product t WHERE t.code IS NOT NULL), 0),
  updater = 'script65', update_time = now() WHERE r.rule_key = 'erp_product';

-- ---------------------------------------------------------------------------
-- 7) 自检
-- ---------------------------------------------------------------------------
SELECT '新建表数（应为 2）' AS item, count(*)::text AS value FROM information_schema.tables
 WHERE table_schema = 'public' AND table_name IN ('erp_purchase_price', 'erp_purchase_price_item')
UNION ALL SELECT '编码规则', COALESCE((SELECT prefix || '(' || seq_length || ')' FROM system_code_rule WHERE rule_key = 'erp_purchase_price'), '无')
UNION ALL SELECT '菜单与按钮', COALESCE((SELECT string_agg(id || ':' || name, ' | ' ORDER BY id) FROM system_menu WHERE deleted = 0 AND id IN (12200,12201,12202,12203,12204,12205)), '无')
UNION ALL SELECT '已授角色数', (SELECT count(DISTINCT role_id)::text FROM system_role_menu WHERE deleted = 0 AND menu_id = 12200)
UNION ALL SELECT '公共资料下现有菜单', COALESCE((SELECT string_agg(name, ' | ' ORDER BY sort, id) FROM system_menu WHERE deleted = 0 AND parent_id = 12182), '无')
UNION ALL SELECT '物料编码未回填数（应为 0）', (SELECT count(*)::text FROM erp_product WHERE code IS NULL)
UNION ALL SELECT '物料编码规则', COALESCE((SELECT prefix || '(' || seq_length || ', 当前' || current_value || ')' FROM system_code_rule WHERE rule_key = 'erp_product'), '无');

COMMIT;
