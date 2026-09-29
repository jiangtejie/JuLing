-- ============================================================================
-- 49 清理门店订货链的测试订单历史数据
--
-- 背景：门店订货链联调期间造了一批测试单据（下单 / 上传凭证 / 两级审批 / 配送出库 / 门店收货），
--   现网 trade_order 里全是测试数据（8 单，含 2 单 E2E 造的单），要求清空。
--
-- 做法：先把要删的表**整表备份**到 schema `bak_test_orders_20260929`（可用
--   `ALTER TABLE bak_test_orders_20260929.trade_order RENAME TO ...` 或直接查回），再按
--   外键顺序删除；只清"订单链"产生的数据：
--     订单 / 订单行 / 付款凭证 / 门店收货单(含行) / 订单日志 / 门店往来台账 /
--     门店收货产生的门店仓批次（erp_stock_batch.source_biz_type = 90，即 STORE_RECEIPT）
--   **不动**：ERP 期初批次、中心库库存流水、BPM/Flowable 审批历史（act_* 由 Flowable 管理，
--   直接删有外键风险，如需清理走 BPM 后台或 Flowable API）、门店客户/会员主数据。
--
-- 幂等：可重复执行（备份表用 CREATE TABLE IF NOT EXISTS + 只补差异行）。
-- ============================================================================

BEGIN;

CREATE SCHEMA IF NOT EXISTS bak_test_orders_20260929;

CREATE TABLE IF NOT EXISTS bak_test_orders_20260929.trade_order AS SELECT * FROM trade_order WHERE false;
INSERT INTO bak_test_orders_20260929.trade_order SELECT * FROM trade_order t
WHERE NOT EXISTS (SELECT 1 FROM bak_test_orders_20260929.trade_order b WHERE b.id = t.id);

CREATE TABLE IF NOT EXISTS bak_test_orders_20260929.trade_order_item AS SELECT * FROM trade_order_item WHERE false;
INSERT INTO bak_test_orders_20260929.trade_order_item SELECT * FROM trade_order_item t
WHERE NOT EXISTS (SELECT 1 FROM bak_test_orders_20260929.trade_order_item b WHERE b.id = t.id);

CREATE TABLE IF NOT EXISTS bak_test_orders_20260929.trade_order_payment_proof AS SELECT * FROM trade_order_payment_proof WHERE false;
INSERT INTO bak_test_orders_20260929.trade_order_payment_proof SELECT * FROM trade_order_payment_proof t
WHERE NOT EXISTS (SELECT 1 FROM bak_test_orders_20260929.trade_order_payment_proof b WHERE b.id = t.id);

CREATE TABLE IF NOT EXISTS bak_test_orders_20260929.trade_order_receipt AS SELECT * FROM trade_order_receipt WHERE false;
INSERT INTO bak_test_orders_20260929.trade_order_receipt SELECT * FROM trade_order_receipt t
WHERE NOT EXISTS (SELECT 1 FROM bak_test_orders_20260929.trade_order_receipt b WHERE b.id = t.id);

CREATE TABLE IF NOT EXISTS bak_test_orders_20260929.trade_order_receipt_item AS SELECT * FROM trade_order_receipt_item WHERE false;
INSERT INTO bak_test_orders_20260929.trade_order_receipt_item SELECT * FROM trade_order_receipt_item t
WHERE NOT EXISTS (SELECT 1 FROM bak_test_orders_20260929.trade_order_receipt_item b WHERE b.id = t.id);

CREATE TABLE IF NOT EXISTS bak_test_orders_20260929.trade_order_log AS SELECT * FROM trade_order_log WHERE false;
INSERT INTO bak_test_orders_20260929.trade_order_log SELECT * FROM trade_order_log t
WHERE NOT EXISTS (SELECT 1 FROM bak_test_orders_20260929.trade_order_log b WHERE b.id = t.id);

CREATE TABLE IF NOT EXISTS bak_test_orders_20260929.erp_customer_account AS SELECT * FROM erp_customer_account WHERE false;
INSERT INTO bak_test_orders_20260929.erp_customer_account SELECT * FROM erp_customer_account t
WHERE NOT EXISTS (SELECT 1 FROM bak_test_orders_20260929.erp_customer_account b WHERE b.id = t.id);

-- 门店收货入库产生的门店仓批次：ErpStockRecordBizTypeEnum.STORE_RECEIPT = 90（作废 91）
CREATE TABLE IF NOT EXISTS bak_test_orders_20260929.erp_stock_batch_store_receipt AS
SELECT * FROM erp_stock_batch WHERE source_biz_type IN (90, 91);

-- 按外键顺序删除
DELETE FROM trade_order_receipt_item;
DELETE FROM trade_order_receipt;
DELETE FROM trade_order_payment_proof;
DELETE FROM trade_order_log;
DELETE FROM trade_order_item;
DELETE FROM trade_order;
DELETE FROM erp_customer_account;
DELETE FROM erp_stock_batch WHERE source_biz_type IN (90, 91);

-- 自检
SELECT '订单 / 订单行 / 凭证 / 收货单 / 收货行 / 日志 / 往来台账（应全 0）' AS item,
       (SELECT count(*) FROM trade_order)::text || ' / ' ||
       (SELECT count(*) FROM trade_order_item)::text || ' / ' ||
       (SELECT count(*) FROM trade_order_payment_proof)::text || ' / ' ||
       (SELECT count(*) FROM trade_order_receipt)::text || ' / ' ||
       (SELECT count(*) FROM trade_order_receipt_item)::text || ' / ' ||
       (SELECT count(*) FROM trade_order_log)::text || ' / ' ||
       (SELECT count(*) FROM erp_customer_account)::text AS value
UNION ALL
SELECT '备份 schema 里保留的行数（订单/凭证/往来/门店批次）',
       (SELECT count(*) FROM bak_test_orders_20260929.trade_order)::text || ' / ' ||
       (SELECT count(*) FROM bak_test_orders_20260929.trade_order_payment_proof)::text || ' / ' ||
       (SELECT count(*) FROM bak_test_orders_20260929.erp_customer_account)::text || ' / ' ||
       (SELECT count(*) FROM bak_test_orders_20260929.erp_stock_batch_store_receipt)::text
UNION ALL
SELECT '中心库/期初批次是否保留（应 > 0）',
       (SELECT count(*) FROM erp_stock_batch WHERE source_biz_type IS NULL OR source_biz_type NOT IN (90, 91))::text
UNION ALL
SELECT 'BPM 审批历史（未清理）',
       (SELECT count(*) FROM act_hi_procinst)::text;

COMMIT;
