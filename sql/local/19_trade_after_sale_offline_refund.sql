-- ============================================================================
-- 售后「线下退款」登记字段
--
-- 背景：线下收款没有线上退款单可发起。商家线下把钱退给客户后，在后台登记
-- 退款渠道、回执凭证与备注，登记即视为退款完成（原 payRefundId 字段保留但不再写入）。
-- 幂等：可重复执行。
-- ============================================================================

ALTER TABLE trade_after_sale ADD COLUMN IF NOT EXISTS refund_channel_code varchar(32);
ALTER TABLE trade_after_sale ADD COLUMN IF NOT EXISTS refund_proof_urls text;
ALTER TABLE trade_after_sale ADD COLUMN IF NOT EXISTS refund_remark varchar(255);

COMMENT ON COLUMN trade_after_sale.refund_channel_code IS '线下退款渠道（字典 pay_channel_code 的线下值）';
COMMENT ON COLUMN trade_after_sale.refund_proof_urls IS '线下退款凭证图片（JSON 数组）';
COMMENT ON COLUMN trade_after_sale.refund_remark IS '线下退款备注';

-- 校验：应返回 3 行
-- SELECT column_name FROM information_schema.columns
--  WHERE table_name='trade_after_sale' AND column_name LIKE 'refund_%';
