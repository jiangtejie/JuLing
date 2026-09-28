-- ============================================================================
-- 交易配置（trade_config）初始化
--
-- 背景：「商城系统 → 订单中心 → 交易配置」这一页读的是 trade_config 表里唯一的一行配置。
--       库里若从未保存过配置，该表是空的，接口 /trade/config/get 返回 null，
--       老版前端遇到 null 直接 return —— 页面就一片空白（不报错，容易让人以为坏了）。
--       本脚本补一行合理的默认配置；前端也已加默认值兜底（见 web-antd 的 config/index.vue）。
--
-- 说明：
--   1. 仅当表里没有任何未删除的配置时才插入（幂等），已配置过的库不会被动到；
--   2. id 走 trade_config_seq（与 MyBatis-Plus @KeySequence 一致）；
--   3. 亚特的业务只走快递发货，故这里只有包邮开关/满额包邮金额，以及售后理由清单。
-- ============================================================================

INSERT INTO trade_config (id, after_sale_refund_reasons, after_sale_return_reasons,
                          delivery_express_free_enabled, delivery_express_free_price,
                          tenant_id, creator, create_time, updater, update_time, deleted)
SELECT nextval('trade_config_seq'),
       '["商品质量问题","货物与描述不符","多拍 / 拍错","不想要了"]',
       '["商品质量问题","货物与描述不符","规格 / 尺寸不合适","少发 / 错发"]',
       false, 0, 1, '1', now(), '1', now(), 0
WHERE NOT EXISTS (SELECT 1 FROM trade_config WHERE deleted = 0);

-- 校验
SELECT id, delivery_express_free_enabled, delivery_express_free_price, after_sale_refund_reasons FROM trade_config ORDER BY id;
