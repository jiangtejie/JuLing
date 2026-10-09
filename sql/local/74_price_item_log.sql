-- ============================================================================
-- 74 价目表价格变更留痕
--
-- 【需求】用户明确：目的是「后期核算的时候知道价格的变动历史」。
--
-- 【为什么不能复用 bill_log】单据平台的 bill_log 记的是**状态流转**
--   （beforeStatus → afterStatus + operateType），**记不下「单价从 10 改成 12」** ——
--   两者是不同维度的事，混在一起会做错。所以价格留痕需要独立的表。
--
-- 【口径：只对「价格行」留痕，不做全字段 diff】用户确认目的是核算，那就只需要
--   「某物料在某价目表下的价格变更序列」。表头字段（名称/备注/有效期）的变更对核算**没有价值**，
--   做全字段 diff 是白花钱。
--
-- 【用户操作不变】不要求用户「改价时先点新建版本」—— 保存价目表时**系统自动 diff**，
--   把变化的价格行写进本表。这样历史是自动积累的，不依赖使用者的纪律。
--
-- 【记什么】
--   CREATE 新增行 / UPDATE 价格或税率有变化 / DELETE 删掉行
--   价格与税率的前后值都记（税率变了同样影响含税价与核算）
--   操作人与时间复用 BaseDO 的 creator / create_time，不额外加列
--
-- 幂等：可重复执行。
-- ============================================================================

BEGIN;

CREATE TABLE IF NOT EXISTS erp_price_list_item_log (
    id                 bigint        NOT NULL,
    price_id           bigint        NOT NULL,
    item_id            bigint,
    product_id         bigint        NOT NULL,
    change_type        varchar(16)   NOT NULL,
    before_price       numeric(24,6),
    after_price        numeric(24,6),
    before_tax_percent numeric(24,6),
    after_tax_percent  numeric(24,6),
    price_code         varchar(32),
    price_name         varchar(64),
    remark             varchar(255),
    tenant_id          bigint        NOT NULL DEFAULT 0,
    creator            varchar(64)   DEFAULT '',
    create_time        timestamp     NOT NULL DEFAULT now(),
    updater            varchar(64)   DEFAULT '',
    update_time        timestamp     NOT NULL DEFAULT now(),
    deleted            int2          NOT NULL DEFAULT 0,
    CONSTRAINT pk_erp_price_list_item_log PRIMARY KEY (id)
);
CREATE SEQUENCE IF NOT EXISTS erp_price_list_item_log_seq;

CREATE INDEX IF NOT EXISTS idx_price_item_log_price   ON erp_price_list_item_log (price_id);
CREATE INDEX IF NOT EXISTS idx_price_item_log_product ON erp_price_list_item_log (product_id);

COMMENT ON TABLE  erp_price_list_item_log            IS '价目表价格变更留痕：供核算追溯「某物料在某价目表下的价格变动历史」';
COMMENT ON COLUMN erp_price_list_item_log.change_type IS 'CREATE 新增行 / UPDATE 价格或税率变化 / DELETE 删行';
COMMENT ON COLUMN erp_price_list_item_log.price_code  IS '冗余价目表编码与名称：价目表改名/删除后，历史仍可读';
COMMENT ON COLUMN erp_price_list_item_log.price_name  IS '冗余价目表名称，理由同上';

SELECT '表是否就位' AS item,
       (SELECT count(*)::text FROM information_schema.tables
         WHERE table_schema='public' AND table_name='erp_price_list_item_log') AS value
UNION ALL SELECT '索引数（应为 2）',
       (SELECT count(*)::text FROM pg_indexes WHERE tablename='erp_price_list_item_log' AND indexname LIKE 'idx_%')
UNION ALL SELECT '当前留痕条数（新表应为 0）',
       (SELECT count(*)::text FROM erp_price_list_item_log);

COMMIT;
