-- ============================================================================
-- 63 采购订单记住「结算方式」与「交期」（从供应商带出，允许按单覆盖）
--
-- 背景：docs/supplier-master-data-design.md §3 要求下游单据带出供应商的结算方式/交期。
--   供应商档案已有这两项（62 号脚本），但采购订单表没有落点，所以「带出」无处可存。
--   本次给 erp_purchase_order 加两列。
--
-- 语义：**下单时从供应商带出默认值，允许按单覆盖**。落库而不是每次实时查供应商档案，
--   是因为供应商的结算方式/交期会变，历史订单要保留**当时的约定**（同单据冗余快照的原则，
--   见 docs/master-data-unified-design.md §4.4：允许存必要快照，不允许复制成第二个维护点）。
--
-- 幂等：可重复执行。
-- ============================================================================

BEGIN;

ALTER TABLE erp_purchase_order ADD COLUMN IF NOT EXISTS settlement_type varchar(32);
ALTER TABLE erp_purchase_order ADD COLUMN IF NOT EXISTS delivery_days   int4;

COMMENT ON COLUMN erp_purchase_order.settlement_type IS '结账方式（下单时从供应商带出，允许按单覆盖；字典 erp_supplier_settlement_type）';
COMMENT ON COLUMN erp_purchase_order.delivery_days   IS '交期时间（天）（下单时从供应商带出，允许按单覆盖）';

SELECT '新增列数（应为 2）' AS item, count(*)::text AS value FROM information_schema.columns
 WHERE table_schema = 'public' AND table_name = 'erp_purchase_order'
   AND column_name IN ('settlement_type', 'delivery_days');

COMMIT;