-- ============================================================================
-- 50 清理测试订货单在 ERP / BPM 侧的关联数据（与 49 配套）
--
-- 背景：49 已清掉商城侧的订单/凭证/收货单与门店往来台账，但这条链在 ERP 与 BPM 侧还留着：
--   · 2 张配送出库单（XSCK20260929000003 / 04，由要货单下推）+ 3 行明细；
--   · 11 条库存流水（销售出库 50 / 出库作废 51 / 门店收货入库 90）；
--   · 门店仓的库存余额与批次（收货入库留下的）；
--   · Flowable 的 22 个流程实例历史（审批中/已通过/已撤销都算）。
--   这些单据动过中心库库存，所以清理必须**先把中心库回补**，否则库存对不上。
--
-- 做法：先整表备份到 schema `bak_test_erp_20260929`，再
--   1) 按待删流水的净影响回补中心库 erp_stock / erp_stock_batch（OPENING 批次）；
--   2) 删门店仓库存与批次、删上述库存流水、删 2 张出库单与明细；
--   3) 删 Flowable 实例历史（**保留** act_re_procdef 流程定义与 act_ge_bytearray 模型）。
--
-- 不动：FMS/ERP 的采购单据与中心库期初批次（那是演示基线，删了反而"无源可查"）、
--       商品/供应商/客户等主数据、流程定义与模型。
--
-- 幂等：可重复执行。
-- ============================================================================

BEGIN;

CREATE SCHEMA IF NOT EXISTS bak_test_erp_20260929;
CREATE TABLE IF NOT EXISTS bak_test_erp_20260929.erp_sale_out AS SELECT * FROM erp_sale_out;
CREATE TABLE IF NOT EXISTS bak_test_erp_20260929.erp_sale_out_items AS SELECT * FROM erp_sale_out_items;
CREATE TABLE IF NOT EXISTS bak_test_erp_20260929.erp_stock_record AS SELECT * FROM erp_stock_record;
CREATE TABLE IF NOT EXISTS bak_test_erp_20260929.erp_stock AS SELECT * FROM erp_stock;
CREATE TABLE IF NOT EXISTS bak_test_erp_20260929.erp_stock_batch AS SELECT * FROM erp_stock_batch;
CREATE TABLE IF NOT EXISTS bak_test_erp_20260929.act_hi_procinst AS SELECT * FROM act_hi_procinst;
CREATE TABLE IF NOT EXISTS bak_test_erp_20260929.act_hi_taskinst AS SELECT * FROM act_hi_taskinst;
CREATE TABLE IF NOT EXISTS bak_test_erp_20260929.act_hi_comment AS SELECT * FROM act_hi_comment;
CREATE TABLE IF NOT EXISTS bak_test_erp_20260929.bill_relation AS SELECT * FROM bill_relation;
CREATE TABLE IF NOT EXISTS bak_test_erp_20260929.bill_log AS SELECT * FROM bill_log;

-- 1) 中心库回补：按待删流水的净影响反向冲销（门店仓的行不参与，它们随门店库存一起删）
UPDATE erp_stock s SET count = s.count - x.delta, update_time = now()
FROM (SELECT warehouse_id, product_id, sum(count) AS delta
      FROM erp_stock_record
      WHERE deleted = 0 AND warehouse_id = 2
        AND (biz_no IN ('XSCK20260929000003', 'XSCK20260929000004') OR biz_type IN (90, 91))
      GROUP BY warehouse_id, product_id) x
WHERE s.warehouse_id = x.warehouse_id AND s.product_id = x.product_id;

UPDATE erp_stock_batch b SET count = b.count - x.delta, update_time = now()
FROM (SELECT warehouse_id, product_id, batch_no, sum(count) AS delta
      FROM erp_stock_record
      WHERE deleted = 0 AND warehouse_id = 2 AND batch_no IS NOT NULL
        AND (biz_no IN ('XSCK20260929000003', 'XSCK20260929000004') OR biz_type IN (90, 91))
      GROUP BY warehouse_id, product_id, batch_no) x
WHERE b.warehouse_id = x.warehouse_id AND b.product_id = x.product_id AND b.batch_no = x.batch_no;

-- 2) 门店仓库存与批次（门店收货入库留下的）
DELETE FROM erp_stock WHERE warehouse_id IN (SELECT id FROM erp_warehouse WHERE warehouse_type = 'STORE');
DELETE FROM erp_stock_batch WHERE warehouse_id IN (SELECT id FROM erp_warehouse WHERE warehouse_type = 'STORE');

-- 3) 库存流水与两张配送出库单
DELETE FROM erp_stock_record
WHERE biz_no IN ('XSCK20260929000003', 'XSCK20260929000004') OR biz_type IN (90, 91);
DELETE FROM erp_sale_out_items WHERE out_id IN (11, 12);
DELETE FROM erp_sale_out WHERE id IN (11, 12);

-- 4) 单据平台的关联与操作日志（要货单 → 配送出库单的下推血缘，单子删了就成了悬空引用）
DELETE FROM bill_relation
WHERE target_no IN ('XSCK20260929000003', 'XSCK20260929000004')
   OR source_no IN ('E2E20260928165616', 'E2E220260928170522');
DELETE FROM bill_log
WHERE bill_no IN ('XSCK20260929000003', 'XSCK20260929000004')
   OR (bill_type = 'DELIVERY_OUT' AND bill_id IN (11, 12));

-- 5) Flowable 实例历史（全部为测试单产生；保留流程定义 act_re_procdef 与模型 act_ge_bytearray）
DELETE FROM act_hi_detail;
DELETE FROM act_hi_varinst;
DELETE FROM act_hi_identitylink;
DELETE FROM act_hi_comment;
DELETE FROM act_hi_taskinst;
DELETE FROM act_hi_actinst;
DELETE FROM act_hi_procinst;

-- 自检
SELECT '配送出库单剩余（应只剩 09-22 的历史演示单 1 张）' AS item,
       (SELECT count(*) FROM erp_sale_out)::text || ' 张 / 明细 ' || (SELECT count(*) FROM erp_sale_out_items)::text || ' 行' AS value
UNION ALL
SELECT '门店仓库存 / 批次（应 0）',
       (SELECT count(*) FROM erp_stock WHERE warehouse_id IN (SELECT id FROM erp_warehouse WHERE warehouse_type = 'STORE'))::text || ' / ' ||
       (SELECT count(*) FROM erp_stock_batch WHERE warehouse_id IN (SELECT id FROM erp_warehouse WHERE warehouse_type = 'STORE'))::text
UNION ALL
SELECT '库存流水剩余（应只剩采购入库等非本次数据）',
       (SELECT count(*) FROM erp_stock_record)::text || ' 条；其中 50/51/90/91 类型 ' ||
       (SELECT count(*) FROM erp_stock_record WHERE biz_type IN (50, 51, 90, 91))::text || ' 条'
UNION ALL
SELECT '单据平台关联 / 日志（本次相关应为 0）',
       (SELECT count(*) FROM bill_relation WHERE target_no LIKE 'XSCK20260929%' OR source_no LIKE 'E2E%')::text || ' / ' ||
       (SELECT count(*) FROM bill_log WHERE bill_no LIKE 'XSCK20260929%')::text
UNION ALL
SELECT 'Flowable 实例历史 / 流程定义（定义应保留 8）',
       (SELECT count(*) FROM act_hi_procinst)::text || ' / ' || (SELECT count(*) FROM act_re_procdef)::text
UNION ALL
SELECT '中心库库存合计',
       (SELECT sum(count) FROM erp_stock WHERE warehouse_id = 2)::text
UNION ALL
SELECT '备份 schema 行数（订单/明细/流水/库存/批次/流程实例）',
       (SELECT count(*) FROM bak_test_erp_20260929.erp_sale_out)::text || ' / ' ||
       (SELECT count(*) FROM bak_test_erp_20260929.erp_sale_out_items)::text || ' / ' ||
       (SELECT count(*) FROM bak_test_erp_20260929.erp_stock_record)::text || ' / ' ||
       (SELECT count(*) FROM bak_test_erp_20260929.erp_stock)::text || ' / ' ||
       (SELECT count(*) FROM bak_test_erp_20260929.erp_stock_batch)::text || ' / ' ||
       (SELECT count(*) FROM bak_test_erp_20260929.act_hi_procinst)::text;

COMMIT;
