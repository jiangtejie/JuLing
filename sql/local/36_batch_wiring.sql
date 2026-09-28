-- =============================================================================
-- S2 库存中心（切片二）：把「采购入库」「销售出库（= 配送出库）」接上批次库存账
--
-- 背景（见 docs/stock-center.md §6/§7、docs/supply-chain-rebuild-plan.md §6）：
--   切片一已落地 erp_stock_batch + ErpStockBatchService（receiveBatch / issueByFifo /
--   reverseReceive / reverseIssue），但只接了「其它入库 / 其它出库」。采购入库与销售出库
--   仍只写 erp_stock，于是出现「有库存、批次表没有」，此时 FIFO 出库会报批次库存不足。
--
-- 本脚本只做一件事：给采购入库项补上批次三列（其它入库项 erp_stock_in_item 在
--   35_stock_center.sql 里已经加过同样的三列），让采购入库审核时能按批次入账：
--     · batch_no        批次号（为空时由服务生成 IN{yyyyMMdd}-{入库单项id}）
--     · production_date 生产日期
--     · expiry_date     到期日期（效期预警口径；FIFO 的次级排序键）
--
-- 幂等：全部 ADD COLUMN IF NOT EXISTS / COMMENT，可重复执行；只加列，不改既有列、不删数据。
-- 执行：docker exec -i postgres psql -U root -d yate -f - < sql/local/36_batch_wiring.sql
--
-- 【一致性判据】双写的唯一入口是 ErpStockBatchServiceImpl#writeStockRecord：
--   批次表每一次在仓数量变动都会经 ErpStockRecordService#createStockRecord 增量更新
--   erp_stock.count，两者在同一事务内，因此「按物料汇总的批次在仓量」应当等于
--   erp_stock.count。核对 SQL（偏差即为历史遗留，见 docs/stock-center.md §9）：
--     SELECT b.product_id, b.warehouse_id, SUM(b.count) AS batch_count, s.count AS stock_count,
--            SUM(b.count) - s.count AS diff
--       FROM erp_stock_batch b
--       JOIN erp_stock s ON s.product_id = b.product_id AND s.warehouse_id = b.warehouse_id
--                          AND s.deleted = 0
--      WHERE b.deleted = 0
--      GROUP BY b.product_id, b.warehouse_id, s.count
--     HAVING SUM(b.count) <> s.count;
--   偏差来源：① 切片一之前的历史单据（批次表无来源批次）；② 手工造数。
--   注意 FIFO 的「可出量」= SUM(count − occupied_count)，比 erp_stock.count 小，
--   两者在「有占用」时本来就不等（这是口径差异，不是偏差）。
-- =============================================================================

-- ---------- 采购入库项：批次与效期（对齐 erp_stock_in_item 的三列） ----------
ALTER TABLE erp_purchase_in_items ADD COLUMN IF NOT EXISTS batch_no        varchar(64);
ALTER TABLE erp_purchase_in_items ADD COLUMN IF NOT EXISTS production_date date;
ALTER TABLE erp_purchase_in_items ADD COLUMN IF NOT EXISTS expiry_date     date;

COMMENT ON COLUMN erp_purchase_in_items.batch_no        IS '批次号：为空时审核入库按 IN{yyyyMMdd}-{项id} 自动生成（ErpStockBatchService#receiveBatch）';
COMMENT ON COLUMN erp_purchase_in_items.production_date IS '生产日期（可空）';
COMMENT ON COLUMN erp_purchase_in_items.expiry_date     IS '到期日期（可空）：效期预警口径，FIFO 的次级排序键';

-- ---------- 核对：采购入库/销售出库接入后，两条链路都应双写 ----------
-- 最近的采购入库批次（来源 biz_type = 70）：
-- select id, warehouse_id, product_id, batch_no, count, unit_cost, in_date, expiry_date, source_biz_no
--   from erp_stock_batch where deleted = 0 and source_biz_type = 70 order by id desc limit 20;
-- 最近的销售出库 FIFO 拆批流水（来源 biz_type = 50，一行一批次，成本为负即结转）：
-- select id, product_id, warehouse_id, count, batch_no, unit_cost, total_cost, biz_no
--   from erp_stock_record where biz_type = 50 and batch_no is not null order by id desc limit 50;
