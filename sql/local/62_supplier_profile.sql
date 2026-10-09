-- ============================================================================
-- 62 供应商档案扩展（采购部门需求）
--
-- 需求来源：采购在金蝶建档时只能录供应商名称，缺开票资质/结账方式/税点/账户/合同/交期。
-- 设计：docs/supplier-master-data-design.md（本文按用户最新清单收敛，未做多账户/合同-组织子表）。
--
-- 与现有列的合并（**不重复造字段**）：
--   供应商名称 → 复用 name          ｜ 税号   → 复用 tax_no
--   银行账号   → 复用 bank_account  ｜ 开户银行 → 复用 bank_name
--   开票税点   → 复用 tax_percent（语义明确为「开票税率」，0 表示免税）
--   bank_address（开户地址）保留，与新增的 registered_address（注册地址）是两回事：
--     注册地址是开专票要的营业地址；开户地址是银行侧的地址。
--
-- 新增 12 列 + 3 个字典。
-- 幂等：可重复执行。
-- ============================================================================

BEGIN;

-- 1) 新增列
ALTER TABLE erp_supplier ADD COLUMN IF NOT EXISTS account_name             varchar(128);
ALTER TABLE erp_supplier ADD COLUMN IF NOT EXISTS registered_address       varchar(255);
ALTER TABLE erp_supplier ADD COLUMN IF NOT EXISTS settlement_type          varchar(32);
ALTER TABLE erp_supplier ADD COLUMN IF NOT EXISTS credit_days              int4;
ALTER TABLE erp_supplier ADD COLUMN IF NOT EXISTS invoice_mode             varchar(32);
ALTER TABLE erp_supplier ADD COLUMN IF NOT EXISTS invoice_ratio            numeric(5,2);
ALTER TABLE erp_supplier ADD COLUMN IF NOT EXISTS invoice_type             varchar(32);
ALTER TABLE erp_supplier ADD COLUMN IF NOT EXISTS delivery_days            int4;
ALTER TABLE erp_supplier ADD COLUMN IF NOT EXISTS contract_signed          boolean DEFAULT false;
ALTER TABLE erp_supplier ADD COLUMN IF NOT EXISTS contract_entity          varchar(128);
ALTER TABLE erp_supplier ADD COLUMN IF NOT EXISTS business_license_urls    varchar(1024);
ALTER TABLE erp_supplier ADD COLUMN IF NOT EXISTS production_license_urls  varchar(1024);

-- 2) 注释
COMMENT ON COLUMN erp_supplier.account_name            IS '账户户名（银行账户的开户名称，通常同公司全称）';
COMMENT ON COLUMN erp_supplier.registered_address      IS '注册地址（营业执照上的营业地址；开增值税专用发票需要）';
COMMENT ON COLUMN erp_supplier.settlement_type         IS '结账方式：MONTHLY 月结 / HALF_MONTH 半月结 / CASH_FIRST 次结(先款后货) / GOODS_FIRST 次结(先货后款)（字典 erp_supplier_settlement_type）';
COMMENT ON COLUMN erp_supplier.credit_days             IS '账期天数（月结/半月结时有意义，如月结 30 天、半月结 15 天）';
COMMENT ON COLUMN erp_supplier.invoice_mode            IS '开票情况：FULL 全额开票 / RATIO 按销售额比例开票 / PLUS_TAX 需加税点 / NONE 不开发票（字典 erp_supplier_invoice_mode）';
COMMENT ON COLUMN erp_supplier.invoice_ratio           IS '开票比例(%)：开票情况为「按销售额比例开票」时填写，如 15~25';
COMMENT ON COLUMN erp_supplier.invoice_type            IS '开票类型：VAT_NORMAL 增值税普通发票 / VAT_SPECIAL 增值税专用发票（字典 erp_supplier_invoice_type）';
COMMENT ON COLUMN erp_supplier.delivery_days           IS '交期时间（天）：下单到到货的承诺天数';
COMMENT ON COLUMN erp_supplier.contract_signed         IS '是否已签订合同';
COMMENT ON COLUMN erp_supplier.contract_entity         IS '合同签订主体（由亚特哪个公司/主体签订）';
COMMENT ON COLUMN erp_supplier.business_license_urls   IS '营业执照（文件/图片，多个用逗号分隔）';
COMMENT ON COLUMN erp_supplier.production_license_urls IS '生产许可证（文件/图片，多个用逗号分隔）';
COMMENT ON COLUMN erp_supplier.tax_percent             IS '开票税点(%)：0 表示免税，其余填 1~13（开票/应付单据据此带出，允许按单覆盖）';

-- 3) 字典
INSERT INTO system_dict_type (id, name, type, status, remark, creator, create_time, updater, update_time, deleted)
VALUES (11580, '供应商结账方式', 'erp_supplier_settlement_type', 0, '月结 / 半月结 / 次结（先款后货、先货后款）', 'script62', now(), 'script62', now(), 0),
       (11581, '供应商开票情况', 'erp_supplier_invoice_mode',      0, '全额开票 / 按销售额比例开票 / 需加税点 / 不开发票', 'script62', now(), 'script62', now(), 0),
       (11582, '供应商开票类型', 'erp_supplier_invoice_type',      0, '增值税普通发票 / 增值税专用发票', 'script62', now(), 'script62', now(), 0)
ON CONFLICT (id) DO NOTHING;

INSERT INTO system_dict_data (id, sort, label, value, dict_type, status, color_type, css_class, remark, creator, create_time, updater, update_time, deleted)
VALUES (115800, 1, '月结',           'MONTHLY',     'erp_supplier_settlement_type', 0, 'primary', '', '按账期挂账，账期见「账期天数」', 'script62', now(), 'script62', now(), 0),
       (115801, 2, '半月结',         'HALF_MONTH',  'erp_supplier_settlement_type', 0, 'primary', '', '每半月结算一次', 'script62', now(), 'script62', now(), 0),
       (115802, 3, '次结（先款后货）', 'CASH_FIRST',  'erp_supplier_settlement_type', 0, 'warning', '', '每单先付款后发货', 'script62', now(), 'script62', now(), 0),
       (115803, 4, '次结（先货后款）', 'GOODS_FIRST', 'erp_supplier_settlement_type', 0, 'warning', '', '每单先发货后付款', 'script62', now(), 'script62', now(), 0),
       (115810, 1, '全额开票',        'FULL',     'erp_supplier_invoice_mode', 0, 'success', '', '按采购全额开票', 'script62', now(), 'script62', now(), 0),
       (115811, 2, '按销售额比例开票', 'RATIO',    'erp_supplier_invoice_mode', 0, 'primary', '', '比例见「开票比例」，如 15~25%', 'script62', now(), 'script62', now(), 0),
       (115812, 3, '需加税点',        'PLUS_TAX', 'erp_supplier_invoice_mode', 0, 'warning', '', '开票需在货款外另加税点', 'script62', now(), 'script62', now(), 0),
       (115813, 4, '不开发票',        'NONE',     'erp_supplier_invoice_mode', 0, 'danger',  '', '该供应商不提供发票', 'script62', now(), 'script62', now(), 0),
       (115820, 1, '增值税普通发票',   'VAT_NORMAL',  'erp_supplier_invoice_type', 0, 'primary', '', '', 'script62', now(), 'script62', now(), 0),
       (115821, 2, '增值税专用发票',   'VAT_SPECIAL', 'erp_supplier_invoice_type', 0, 'success', '', '可抵扣进项税', 'script62', now(), 'script62', now(), 0)
ON CONFLICT (id) DO NOTHING;

-- 4) 自检
SELECT '新增列数（应为 12）' AS item, count(*)::text AS value FROM information_schema.columns
 WHERE table_schema = 'public' AND table_name = 'erp_supplier'
   AND column_name IN ('account_name','registered_address','settlement_type','credit_days','invoice_mode','invoice_ratio','invoice_type','delivery_days','contract_signed','contract_entity','business_license_urls','production_license_urls')
UNION ALL SELECT '新增字典类型（应为 3）', count(*)::text FROM system_dict_type WHERE type LIKE 'erp\_supplier\_%' AND deleted = 0
UNION ALL SELECT '新增字典数据（应为 10）', count(*)::text FROM system_dict_data WHERE dict_type LIKE 'erp\_supplier\_%' AND deleted = 0
UNION ALL SELECT '供应商表总列数', (SELECT count(*)::text FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'erp_supplier');

COMMIT;