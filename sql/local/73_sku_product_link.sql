-- ============================================================================
-- 73 商城 SKU ↔ ERP 物料：把隐式字符串约定变成显式外键
--
-- 【为什么做】两套物料目录（erp_product / product_spu+product_sku）现在靠
--   `product_sku.bar_code` = `erp_product.bar_code` 的**字符串 join** 相连
--   （见 TradeOrderWorkbenchServiceImpl:137 的既有做法）。三个失效模式：
--     · 条码改了      → 对应关系**断链**
--     · 条码重复      → 取到**错的物料**（配送价、库存都跟着错）
--     · 条码没维护    → **静默失配**（配送价悄悄回退到 SKU 价，无任何提示）
--
-- 【做了什么】加显式外键 + 唯一约束。**不合并两张表** —— 商城的多规格模型（SPU/SKU）
--   与 ERP 的单物料模型本就不同，硬合并会伤两边；要解决的是「对应关系必须是显式的」。
--
-- 【1 物料 : 1 SKU（用户确认）】
--   `erp_product_id` 上加唯一索引 —— 同时表达了两件事：
--     · 一个 SKU 最多对应一个物料
--     · 一个物料最多被一个 SKU 引用
--   （同一个唯一索引即可覆盖两个方向，不需要在 erp_product 侧再加列。）
--
-- 【留空策略】允许为空 —— 商城可能有非订货的展示商品。
--   但**列表与取价处要能看出「未关联」**，不能再像现在这样静默失配。
--
-- 幂等：可重复执行。
-- ============================================================================

BEGIN;

ALTER TABLE product_sku ADD COLUMN IF NOT EXISTS erp_product_id bigint;

COMMENT ON COLUMN product_sku.erp_product_id IS
  '对应的 ERP 物料 erp_product.id（1 物料 : 1 SKU，唯一）；为空表示未关联（非订货商品）。'
  '取代原先按 bar_code 字符串 join 的隐式约定';

-- 回填：按条码匹配（当前是空库，等于只建结构；条码重复的会因唯一索引而报出来）
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='product_sku' AND column_name='bar_code') THEN UPDATE product_sku s SET erp_product_id = p.id FROM erp_product p WHERE s.erp_product_id IS NULL AND s.deleted = 0 AND p.deleted = 0 AND s.bar_code IS NOT NULL AND s.bar_code <> '' AND s.bar_code = p.bar_code; END IF; END $$;

CREATE UNIQUE INDEX IF NOT EXISTS uk_product_sku_erp_product
    ON product_sku (erp_product_id) WHERE deleted = 0 AND erp_product_id IS NOT NULL;

SELECT '列是否就位' AS item,
       COALESCE((SELECT column_name || ':' || data_type FROM information_schema.columns
                  WHERE table_schema='public' AND table_name='product_sku' AND column_name='erp_product_id'), '无') AS value
UNION ALL SELECT '唯一索引是否就位（应为 1）',
       (SELECT count(*)::text FROM pg_indexes WHERE indexname = 'uk_product_sku_erp_product')
UNION ALL SELECT 'SKU 总数 / 已关联 / 未关联',
       (SELECT count(*) || ' / ' || count(erp_product_id) || ' / ' || (count(*) - count(erp_product_id))
          FROM product_sku WHERE deleted = 0)
UNION ALL SELECT '条码重复的 SKU（会阻断回填，需人工处理）',
       COALESCE((SELECT string_agg(bar_code || '×' || c, ', ') FROM (
                   SELECT bar_code, count(*) c FROM product_sku
                    WHERE deleted = 0 AND bar_code IS NOT NULL AND bar_code <> ''
                    GROUP BY bar_code HAVING count(*) > 1) t), '无');

COMMIT;
