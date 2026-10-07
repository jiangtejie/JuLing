-- ============================================================================
-- 67 采购价目表：吸纳金蝶的常用字段
--
-- 用户提供金蝶「采购价目表 - 查看」界面，要求把常用字段吸纳过来。逐项对照后的取舍：
--
-- 【吸纳 3 项】
--   1) 含税 price_includes_tax —— 供应商报价习惯直接报含税价（「13 个点」），
--      整张表统一口径比逐行按计算器更贴合实际。
--      **注意**：行上的 price 仍然**永远是不含税**（权威、无歧义），
--      这个标记表示的是「报价方的口径」，只影响录入方向（见 ErpPurchasePriceItemDO 的说明）。
--   2) 定价员 pricer_user_id —— 价格由谁定的。与 BaseDO 的 creator 不同：
--      常见是采购经理定价、文员录入，责任人不等于录入人。也是二期「变更留痕」的基础。
--   3) 规格型号（明细展示）—— **不落库**，从物料的 erp_product.standard 带出，
--      与「计价单位」同理（见 sql/local/65 的设计说明）。
--
-- 【不吸纳 5 项，理由】
--   · 币别：本系统没有汇率表，erp_purchase_order 也没有币别，加了就是一个永远显示 CNY 的
--     摆设，反而让人以为支持外币。真要进口采购，需要的是**先建汇率与多币别结算**，不是加一个字段。
--   · 采购组织：组织维度一旦加上，就必须回答「取价时按哪个组织过滤」，而组织模型
--     （品牌/门店/仓库怎么挂）**至今未定**（见 organization-architecture-design）。
--     现在加会做出一个半成品的组织隔离，比不加更危险。
--   · 单据状态（草稿/已审核）：一期不做审批流，用 status（启用/停用）+ 生效·失效日期控制，
--     与本仓库其它 ERP 主数据（客户/供应商/物料）一致。
--   · 价格类型（采购）：本表就是采购价目表，类型恒定，字段冗余。
--   · 价目表对象（按物料/按分类）：一期只支持按物料定价；按分类批量定价是独立特性。
--   · 价外税：本系统本来就是「不含税单价 + 税率」模型，等同于价外税，无需字段。
--
-- 幂等：可重复执行。
-- ============================================================================

BEGIN;

ALTER TABLE erp_purchase_price ADD COLUMN IF NOT EXISTS price_includes_tax boolean NOT NULL DEFAULT false;
ALTER TABLE erp_purchase_price ADD COLUMN IF NOT EXISTS pricer_user_id bigint;

COMMENT ON COLUMN erp_purchase_price.price_includes_tax IS '报价口径：true 表示供应商报的是含税价（仅影响录入方向）。行上的 price 恒为不含税';
COMMENT ON COLUMN erp_purchase_price.pricer_user_id     IS '定价员（system_users.id）；与 creator 区分，责任人不等于录入人';

-- 自检
SELECT '两列是否就位' AS item,
       COALESCE((SELECT string_agg(column_name || ':' || data_type, ' | ' ORDER BY ordinal_position)
                   FROM information_schema.columns
                  WHERE table_schema = 'public' AND table_name = 'erp_purchase_price'
                    AND column_name IN ('price_includes_tax', 'pricer_user_id')), '无') AS value
UNION ALL SELECT '价目表全部列',
       COALESCE((SELECT string_agg(column_name, ', ' ORDER BY ordinal_position)
                   FROM information_schema.columns
                  WHERE table_schema = 'public' AND table_name = 'erp_purchase_price'), '无');

COMMIT;