-- ============================================================================
-- 56 统一编码：编码规则表 + 各主数据 code 列 + 唯一性
--
-- 背景（见 docs/master-data-unified-design.md §3.3 G1）：本仓库**全部主数据没有业务编码** ——
--   实测 erp_customer / erp_supplier / erp_warehouse / erp_product_unit / product_spu
--   的字段只有 name + status（+ taxNo），唯一像编码的 product_sku.bar_code 是条形码不是内部编码。
--   全部靠自增 id 引用、靠 name 人工识别。而金蝶的骨架特征正是「每个基础资料有编码，
--   按组织内编码唯一校验」（该文 §1.2）。这是与金蝶差距最大的一条。
--
-- 本脚本做三件事：
--   1) 建编码规则表 system_code_rule（对齐金蝶的「编码规则」）：前缀 + 流水长度 + 当前值；
--   2) 给 6 个主数据对象加 code 列，并按 id 顺序回填存量数据；
--   3) 建 (tenant_id, code) 唯一索引（deleted = 0 部分索引）。
--
-- 设计取舍（与设计文档的偏差，已记录）：
--   · 唯一性取**租户内唯一**而非「组织内唯一」—— 「多组织」在本系统尚未成立
--     （品牌算不算组织仍是设计文档 §7 的待确认项），先按租户内唯一落地；
--   · system_dept 统一用 BM 前缀，不再按门店/组织分裂成 MD/BM ——
--     节点类型已由 dept_type 精确表达，编码前缀保持单一更稳定。
--
-- code 允许为 NULL（唯一索引带 code IS NOT NULL 条件）：新建路径若尚未接入编码生成，
-- 不会因为 NOT NULL 直接插入失败；接入后新数据一定有码。
--
-- 幂等：可重复执行。
-- ============================================================================

BEGIN;

-- ---------------------------------------------------------------------------
-- 1) 编码规则表
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS system_code_rule (
    id            bigint       NOT NULL,
    rule_key      varchar(64)  NOT NULL,
    name          varchar(64)  NOT NULL,
    prefix        varchar(16)  NOT NULL,
    seq_length    smallint     NOT NULL DEFAULT 6,
    current_value bigint       NOT NULL DEFAULT 0,
    remark        varchar(255) DEFAULT '',
    tenant_id     bigint       NOT NULL DEFAULT 0,
    creator       varchar(64)  DEFAULT '',
    create_time   timestamp    NOT NULL DEFAULT now(),
    updater       varchar(64)  DEFAULT '',
    update_time   timestamp    NOT NULL DEFAULT now(),
    deleted       smallint     NOT NULL DEFAULT 0,
    CONSTRAINT pk_system_code_rule PRIMARY KEY (id)
);
COMMENT ON TABLE  system_code_rule               IS '编码规则：主数据的业务编码前缀与流水（对齐金蝶的「编码规则」）';
COMMENT ON COLUMN system_code_rule.rule_key      IS '规则标识，与主数据对象一一对应，如 erp_customer';
COMMENT ON COLUMN system_code_rule.prefix        IS '编码前缀，如 KH';
COMMENT ON COLUMN system_code_rule.seq_length    IS '流水号长度（左补零），如 6 → KH000001';
COMMENT ON COLUMN system_code_rule.current_value IS '当前已分配到的流水值';

CREATE UNIQUE INDEX IF NOT EXISTS uk_system_code_rule_key
    ON system_code_rule (tenant_id, rule_key) WHERE deleted = 0;

CREATE SEQUENCE IF NOT EXISTS system_code_rule_seq;

INSERT INTO system_code_rule (id, rule_key, name, prefix, seq_length, current_value, remark, tenant_id, creator, create_time, updater, update_time, deleted)
VALUES
    (1, 'erp_customer',     '客户（门店）编码', 'KH',  6, 0, '门店 / 往来客户', 1, 'script56', now(), 'script56', now(), 0),
    (2, 'erp_supplier',     '供应商编码',       'GYS', 6, 0, '',                1, 'script56', now(), 'script56', now(), 0),
    (3, 'erp_warehouse',    '仓库编码',         'CK',  4, 0, '',                1, 'script56', now(), 'script56', now(), 0),
    (4, 'erp_product_unit', '计量单位编码',     'DW',  4, 0, '',                1, 'script56', now(), 'script56', now(), 0),
    (5, 'product_spu',      '物料（商品）编码', 'WL',  6, 0, '',                1, 'script56', now(), 'script56', now(), 0),
    (6, 'system_dept',      '组织节点编码',     'BM',  4, 0, '组织架构节点（含门店）', 1, 'script56', now(), 'script56', now(), 0)
ON CONFLICT (id) DO NOTHING;

-- ---------------------------------------------------------------------------
-- 2) 加 code 列
-- ---------------------------------------------------------------------------
ALTER TABLE erp_customer     ADD COLUMN IF NOT EXISTS code varchar(32);
ALTER TABLE erp_supplier     ADD COLUMN IF NOT EXISTS code varchar(32);
ALTER TABLE erp_warehouse    ADD COLUMN IF NOT EXISTS code varchar(32);
ALTER TABLE erp_product_unit ADD COLUMN IF NOT EXISTS code varchar(32);
ALTER TABLE product_spu      ADD COLUMN IF NOT EXISTS code varchar(32);
ALTER TABLE system_dept      ADD COLUMN IF NOT EXISTS code varchar(32);

COMMENT ON COLUMN erp_customer.code     IS '客户编码（规则 KH + 6 位流水；租户内唯一）';
COMMENT ON COLUMN erp_supplier.code     IS '供应商编码（规则 GYS + 6 位流水；租户内唯一）';
COMMENT ON COLUMN erp_warehouse.code    IS '仓库编码（规则 CK + 4 位流水；租户内唯一）';
COMMENT ON COLUMN erp_product_unit.code IS '计量单位编码（规则 DW + 4 位流水；租户内唯一）';
COMMENT ON COLUMN product_spu.code      IS '物料（商品）编码（规则 WL + 6 位流水；租户内唯一）';
COMMENT ON COLUMN system_dept.code      IS '组织节点编码（规则 BM + 4 位流水；租户内唯一）';

-- ---------------------------------------------------------------------------
-- 3) 回填存量数据（按 id 升序，保证可重复执行结果一致）
--    用规则表里的 prefix / seq_length 拼接，避免把格式写死在六处
-- ---------------------------------------------------------------------------
UPDATE erp_customer t SET code = r.prefix || lpad(s.rn::text, r.seq_length, '0')
FROM (SELECT id, row_number() OVER (ORDER BY id) AS rn FROM erp_customer WHERE code IS NULL) s,
     (SELECT prefix, seq_length FROM system_code_rule WHERE rule_key = 'erp_customer' AND deleted = 0) r
WHERE t.id = s.id;

UPDATE erp_supplier t SET code = r.prefix || lpad(s.rn::text, r.seq_length, '0')
FROM (SELECT id, row_number() OVER (ORDER BY id) AS rn FROM erp_supplier WHERE code IS NULL) s,
     (SELECT prefix, seq_length FROM system_code_rule WHERE rule_key = 'erp_supplier' AND deleted = 0) r
WHERE t.id = s.id;

UPDATE erp_warehouse t SET code = r.prefix || lpad(s.rn::text, r.seq_length, '0')
FROM (SELECT id, row_number() OVER (ORDER BY id) AS rn FROM erp_warehouse WHERE code IS NULL) s,
     (SELECT prefix, seq_length FROM system_code_rule WHERE rule_key = 'erp_warehouse' AND deleted = 0) r
WHERE t.id = s.id;

UPDATE erp_product_unit t SET code = r.prefix || lpad(s.rn::text, r.seq_length, '0')
FROM (SELECT id, row_number() OVER (ORDER BY id) AS rn FROM erp_product_unit WHERE code IS NULL) s,
     (SELECT prefix, seq_length FROM system_code_rule WHERE rule_key = 'erp_product_unit' AND deleted = 0) r
WHERE t.id = s.id;

UPDATE product_spu t SET code = r.prefix || lpad(s.rn::text, r.seq_length, '0')
FROM (SELECT id, row_number() OVER (ORDER BY id) AS rn FROM product_spu WHERE code IS NULL) s,
     (SELECT prefix, seq_length FROM system_code_rule WHERE rule_key = 'product_spu' AND deleted = 0) r
WHERE t.id = s.id;

UPDATE system_dept t SET code = r.prefix || lpad(s.rn::text, r.seq_length, '0')
FROM (SELECT id, row_number() OVER (ORDER BY id) AS rn FROM system_dept WHERE code IS NULL) s,
     (SELECT prefix, seq_length FROM system_code_rule WHERE rule_key = 'system_dept' AND deleted = 0) r
WHERE t.id = s.id;

-- ---------------------------------------------------------------------------
-- 4) 唯一索引（deleted = 0 部分索引；code 允许为空，故带 IS NOT NULL 条件）
-- ---------------------------------------------------------------------------
CREATE UNIQUE INDEX IF NOT EXISTS uk_erp_customer_code     ON erp_customer     (tenant_id, code) WHERE deleted = 0 AND code IS NOT NULL;
CREATE UNIQUE INDEX IF NOT EXISTS uk_erp_supplier_code     ON erp_supplier     (tenant_id, code) WHERE deleted = 0 AND code IS NOT NULL;
CREATE UNIQUE INDEX IF NOT EXISTS uk_erp_warehouse_code    ON erp_warehouse    (tenant_id, code) WHERE deleted = 0 AND code IS NOT NULL;
CREATE UNIQUE INDEX IF NOT EXISTS uk_erp_product_unit_code ON erp_product_unit (tenant_id, code) WHERE deleted = 0 AND code IS NOT NULL;
CREATE UNIQUE INDEX IF NOT EXISTS uk_product_spu_code      ON product_spu      (tenant_id, code) WHERE deleted = 0 AND code IS NOT NULL;
CREATE UNIQUE INDEX IF NOT EXISTS uk_system_dept_code      ON system_dept      (tenant_id, code) WHERE deleted = 0 AND code IS NOT NULL;

-- ---------------------------------------------------------------------------
-- 5) 规则当前值对齐回填结果（取各表已用编码的流水最大值）
-- ---------------------------------------------------------------------------
UPDATE system_code_rule r SET current_value = COALESCE((SELECT max(right(t.code, r.seq_length)::bigint) FROM erp_customer t WHERE t.code IS NOT NULL), 0),
  updater = 'script56', update_time = now() WHERE r.rule_key = 'erp_customer';
UPDATE system_code_rule r SET current_value = COALESCE((SELECT max(right(t.code, r.seq_length)::bigint) FROM erp_supplier t WHERE t.code IS NOT NULL), 0),
  updater = 'script56', update_time = now() WHERE r.rule_key = 'erp_supplier';
UPDATE system_code_rule r SET current_value = COALESCE((SELECT max(right(t.code, r.seq_length)::bigint) FROM erp_warehouse t WHERE t.code IS NOT NULL), 0),
  updater = 'script56', update_time = now() WHERE r.rule_key = 'erp_warehouse';
UPDATE system_code_rule r SET current_value = COALESCE((SELECT max(right(t.code, r.seq_length)::bigint) FROM erp_product_unit t WHERE t.code IS NOT NULL), 0),
  updater = 'script56', update_time = now() WHERE r.rule_key = 'erp_product_unit';
UPDATE system_code_rule r SET current_value = COALESCE((SELECT max(right(t.code, r.seq_length)::bigint) FROM product_spu t WHERE t.code IS NOT NULL), 0),
  updater = 'script56', update_time = now() WHERE r.rule_key = 'product_spu';
UPDATE system_code_rule r SET current_value = COALESCE((SELECT max(right(t.code, r.seq_length)::bigint) FROM system_dept t WHERE t.code IS NOT NULL), 0),
  updater = 'script56', update_time = now() WHERE r.rule_key = 'system_dept';

SELECT setval('system_code_rule_seq', (SELECT COALESCE(MAX(id), 1) FROM system_code_rule), true);

-- ---------------------------------------------------------------------------
-- 6) 自检
-- ---------------------------------------------------------------------------
SELECT '规则' AS item, string_agg(rule_key || '=' || prefix || '(' || seq_length || ', 当前' || current_value || ')', ' | ' ORDER BY id) AS value
  FROM system_code_rule WHERE deleted = 0
UNION ALL SELECT '客户编码样例（前 3 条）', COALESCE((SELECT string_agg(code, ', ' ORDER BY id) FROM (SELECT code, id FROM erp_customer WHERE code IS NOT NULL ORDER BY id LIMIT 3) t), '无')
UNION ALL SELECT '组织节点编码样例（前 3 条）', COALESCE((SELECT string_agg(code, ', ' ORDER BY id) FROM (SELECT code, id FROM system_dept WHERE code IS NOT NULL ORDER BY id LIMIT 3) t), '无')
UNION ALL SELECT '未回填的客户数（应为 0）', (SELECT count(*)::text FROM erp_customer WHERE code IS NULL)
UNION ALL SELECT '未回填的组织节点数（应为 0）', (SELECT count(*)::text FROM system_dept WHERE code IS NULL);

COMMIT;
