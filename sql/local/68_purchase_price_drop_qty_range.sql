-- ============================================================================
-- 68 采购价目表：去掉「数量区间」（阶梯价）
--
-- 起因：用户问「数量从 / 数量至 是不是没用」。核实后发现——**确实没用，但根因是实现缺口**：
--   · 前端只在「选物料那一刻」取一次价（matchPurchasePrice 传的是当时行上的数量，默认 1）
--   · 数量单元格没有任何 change 处理，改数量不会重新取价
--   · 后端只在「单价为空」时取价，而前端已经填了价 → 后端不会再按真实数量取
--   实际路径：选物料（数量 1）→ 取到第 1 档的价 → 用户改成 100 → 保存 → **存的是第 1 档的价**。
--
-- 也就是说：这是一个**填了也不生效**的字段 —— 用户会以为分档定价生效了，实际拿到错价，
--   比没有这个字段更糟。要让它真正生效，需要在前端引入「这一行的价是自动带出的还是手工改的」
--   这份隐藏状态，还要处理数量连续变化时的异步竞态；而收益（餐饮采购按数量分档定价）并不明确。
--   因此采纳用户建议：一期去掉。
--
-- 数据模型链（不要改 65 号，它是历史记录）：
--   65 号建表时带了 from_qty / to_qty  →  本脚本删掉这两列。
--
-- 连带的设计后果（代码已同步）：
--   去掉数量区间后，同一价目表里**同一物料只能有一行** —— 否则取价时两条都命中，取哪条取决于
--   排序细节。校验规则由「数量区间不重叠」换成「同一物料不可重复」
--   （错误码 1_030_104_001 改为 PURCHASE_PRICE_ITEM_PRODUCT_DUPLICATE）。
--
-- 取价算法同步简化为：供应商专项 > 通用 → 默认价目表 > 普通 → 生效日期新 > 旧。
--
-- ⚠️ 破坏性操作（DROP COLUMN），执行前先备份。幂等：可重复执行。
-- ============================================================================

BEGIN;

-- 1) 备份整表（含即将被删的两列）
CREATE SCHEMA IF NOT EXISTS bak_drop_price_qty_range_20261007;
CREATE TABLE IF NOT EXISTS bak_drop_price_qty_range_20261007.erp_purchase_price_item
    AS SELECT * FROM erp_purchase_price_item;

-- 2) 删列
ALTER TABLE erp_purchase_price_item DROP COLUMN IF EXISTS from_qty;
ALTER TABLE erp_purchase_price_item DROP COLUMN IF EXISTS to_qty;

-- 3) 自检
SELECT '两列是否已删（应为 0）' AS item, count(*)::text AS value
  FROM information_schema.columns
 WHERE table_schema = 'public' AND table_name = 'erp_purchase_price_item'
   AND column_name IN ('from_qty', 'to_qty')
UNION ALL SELECT '明细表现有列',
       COALESCE((SELECT string_agg(column_name, ', ' ORDER BY ordinal_position)
                   FROM information_schema.columns
                  WHERE table_schema = 'public' AND table_name = 'erp_purchase_price_item'), '无')
UNION ALL SELECT '备份行数', (SELECT count(*)::text FROM bak_drop_price_qty_range_20261007.erp_purchase_price_item);

COMMIT;