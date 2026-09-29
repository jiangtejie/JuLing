-- ============================================================================
-- 订单/清单项金额列兜底：adjust_price 允许 NULL，但业务代码是按「0 表示未调价」写的，
-- NULL 会让首次调价 / 售后等路径直接 NPE（对外表现为「系统异常」）。
-- 这里补列默认值并回填历史 NULL，幂等。
-- ============================================================================

ALTER TABLE trade_order_item ALTER COLUMN adjust_price SET DEFAULT 0;
UPDATE trade_order_item SET adjust_price = 0 WHERE adjust_price IS NULL;

ALTER TABLE trade_order ALTER COLUMN adjust_price SET DEFAULT 0;
UPDATE trade_order SET adjust_price = 0 WHERE adjust_price IS NULL;
UPDATE trade_order SET refund_price = 0 WHERE refund_price IS NULL;
UPDATE trade_order SET refund_point = 0 WHERE refund_point IS NULL;

-- 校验：以下应全部返回 0
-- SELECT count(*) FROM trade_order_item WHERE adjust_price IS NULL;
-- SELECT count(*) FROM trade_order WHERE adjust_price IS NULL OR refund_price IS NULL OR refund_point IS NULL;
