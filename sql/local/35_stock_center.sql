-- =============================================================================
-- S2 库存中心（切片一）：多状态 + 批次/效期 + FIFO 成本（PostgreSQL）
--
-- 背景与口径（用户 2026-09-28 拍板，见 docs/stock-center.md、docs/supply-chain-rebuild-plan.md §6）：
--   · 库存主键维度 = 仓库 × 物料 × 批次（sku_id 预留，本切片恒为 0 = 按物料记账）；
--   · 状态四态：在仓 / 在途 / 占用 / 待检；可用量 = 在仓 − 占用 + 在途；
--   · 批次 + 效期，出库按批次先进先出（FIFO）：先入库先出，同入库日期时先到期先出；
--   · 成本：批次级 unit_cost / total_cost，出库时按批次成本结转。
--
-- 状态口径为什么用「数量分列」而不是 stock_state 单列（设计取舍）：
--   批次本身就是 FIFO 的发出单元，也是成本的载体（unit_cost 属于批次，不属于状态）。
--   若把状态做进主键（仓库×物料×批次×状态），同一批次的成本/效期要在 4 行里各存一份，
--   必然出现行间漂移；且「可用量」要跨 4 行聚合。数量分列后：
--     可用量 = count − occupied_count + transit_count —— 单行计算，SQL 直白、好断言、好建索引；
--   四态之外再扩状态只加列即可（本切片不加）。
--
-- 本脚本只加表 / 加列 / 加索引 / 加序列 + 回填，**不删改任何既有列、不删任何数据**：
--   1) 新表 erp_stock_batch（批次库存，含主键与唯一索引）；
--   2) 新序列 erp_stock_batch_seq；
--   3) erp_stock_in_item 加 batch_no / production_date / expiry_date（入库按批次录）；
--   4) erp_stock_record  加 batch_no / stock_state / unit_cost / total_cost / sku_id（流水带批次与成本）；
--   5) 回填：把 erp_stock 的既有余额落成「期初批次」，使批次表从第一天起与老口径对齐。
--
-- 幂等：CREATE TABLE/INDEX/SEQUENCE IF NOT EXISTS、ADD COLUMN IF NOT EXISTS、
--       ON CONFLICT DO NOTHING、WHERE 条件回填，可重复执行。
-- 执行：docker exec -i postgres psql -U root -d yate -f - < sql/local/35_stock_center.sql
--       （或 psql -U root -d yate -f sql/local/35_stock_center.sql）
-- =============================================================================

-- ---------- 1) 序列 ----------
CREATE SEQUENCE IF NOT EXISTS erp_stock_batch_seq START 1;

-- ---------- 2) 批次库存表 ----------
CREATE TABLE IF NOT EXISTS erp_stock_batch (
    id                 bigint        NOT NULL,
    tenant_id          bigint        NOT NULL DEFAULT 0,
    warehouse_id       bigint        NOT NULL,
    product_id         bigint        NOT NULL,
    sku_id             bigint        NOT NULL DEFAULT 0,
    batch_no           varchar(64)   NOT NULL,
    production_date    date,
    expiry_date        date,
    in_date            date          NOT NULL,
    count              numeric(24, 6) NOT NULL DEFAULT 0,
    transit_count      numeric(24, 6) NOT NULL DEFAULT 0,
    occupied_count     numeric(24, 6) NOT NULL DEFAULT 0,
    inspecting_count   numeric(24, 6) NOT NULL DEFAULT 0,
    unit_cost          numeric(24, 6) NOT NULL DEFAULT 0,
    total_cost         numeric(24, 6) NOT NULL DEFAULT 0,
    source_biz_type    integer,
    source_biz_id      bigint,
    source_biz_item_id bigint,
    source_biz_no      varchar(64),
    source_reversed    smallint      NOT NULL DEFAULT 0,
    remark             varchar(255),
    creator            varchar(64)   DEFAULT ''::character varying,
    create_time        timestamp     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updater            varchar(64)   DEFAULT ''::character varying,
    update_time        timestamp     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted            smallint      NOT NULL DEFAULT 0,
    PRIMARY KEY (id)
);

COMMENT ON TABLE erp_stock_batch IS 'ERP 批次库存：维度 = 仓库 × 物料 × 批次（sku_id 预留，0 = 按物料记账）；状态数量分列';
COMMENT ON COLUMN erp_stock_batch.warehouse_id       IS '仓库编号，关联 erp_warehouse.id';
COMMENT ON COLUMN erp_stock_batch.product_id         IS '物料编号，关联 erp_product.id（SKU 统一是后续工作）';
COMMENT ON COLUMN erp_stock_batch.sku_id             IS 'SKU 编号预留位：0 = 未细分 SKU（本切片一律 0）';
COMMENT ON COLUMN erp_stock_batch.batch_no           IS '批次号：来源单据录入；未录入时由服务生成 IN{yyyyMMdd}-{入库单项id}';
COMMENT ON COLUMN erp_stock_batch.production_date    IS '生产日期（可空）';
COMMENT ON COLUMN erp_stock_batch.expiry_date        IS '到期日期（可空）：效期预警口径，FIFO 的次级排序键';
COMMENT ON COLUMN erp_stock_batch.in_date            IS '入库日期：FIFO 主排序键（先入库先出）';
COMMENT ON COLUMN erp_stock_batch.count              IS '在仓数量（含被占用的部分，与 erp_stock.count 同一口径）';
COMMENT ON COLUMN erp_stock_batch.transit_count      IS '在途数量（可用量 = 在仓 − 占用 + 在途）';
COMMENT ON COLUMN erp_stock_batch.occupied_count     IS '占用数量（已被单据锁定、尚未出库），是在仓数量的子集';
COMMENT ON COLUMN erp_stock_batch.inspecting_count   IS '待检数量（已到货、质检未放行），不计入可用量';
COMMENT ON COLUMN erp_stock_batch.unit_cost          IS '批次单位成本（= 入库单价）';
COMMENT ON COLUMN erp_stock_batch.total_cost         IS '批次在仓成本 = count × unit_cost（出库按此结转）';
COMMENT ON COLUMN erp_stock_batch.source_biz_type    IS '来源业务类型，取值同 erp_stock_record.biz_type（ErpStockRecordBizTypeEnum）';
COMMENT ON COLUMN erp_stock_batch.source_biz_id      IS '来源单据编号，例如 erp_stock_in.id';
COMMENT ON COLUMN erp_stock_batch.source_biz_item_id IS '来源单据项编号，例如 erp_stock_in_item.id；与 source_biz_type 一起作为幂等键';
COMMENT ON COLUMN erp_stock_batch.source_biz_no      IS '来源单号，例如 QTRK20260928000001';
COMMENT ON COLUMN erp_stock_batch.source_reversed    IS '来源是否已反审核冲销：0 否 / 1 是（反审核可逆，重新审核会复位）';
COMMENT ON COLUMN erp_stock_batch.deleted            IS '逻辑删除：0 未删除 / 1 已删除（smallint，与本库既有口径一致）';

-- 唯一索引：仓库 × 物料 × SKU × 批次（同租户）。
-- 为什么把 tenant_id 也放进唯一键：多租户下不同租户可以有同名批次；
-- 为什么带 WHERE deleted = 0 的部分索引：逻辑删除后允许重建同批次行。
CREATE UNIQUE INDEX IF NOT EXISTS uk_erp_stock_batch
    ON erp_stock_batch (warehouse_id, product_id, sku_id, batch_no, tenant_id)
    WHERE deleted = 0;

-- 可用量查询：按 仓库 + 物料 取在仓批次
CREATE INDEX IF NOT EXISTS idx_erp_stock_batch_wh_product
    ON erp_stock_batch (warehouse_id, product_id, deleted);
-- FIFO 排序：入库日期 → 到期日期
CREATE INDEX IF NOT EXISTS idx_erp_stock_batch_fifo
    ON erp_stock_batch (warehouse_id, product_id, in_date, expiry_date);
-- 效期预警：临期 / 过期批次
CREATE INDEX IF NOT EXISTS idx_erp_stock_batch_expiry
    ON erp_stock_batch (expiry_date)
    WHERE deleted = 0;
-- 按来源反查（幂等与反审核冲销）
CREATE INDEX IF NOT EXISTS idx_erp_stock_batch_source
    ON erp_stock_batch (source_biz_type, source_biz_item_id)
    WHERE deleted = 0;

-- ---------- 3) 其它入库单项：批次与效期 ----------
ALTER TABLE erp_stock_in_item ADD COLUMN IF NOT EXISTS batch_no        varchar(64);
ALTER TABLE erp_stock_in_item ADD COLUMN IF NOT EXISTS production_date date;
ALTER TABLE erp_stock_in_item ADD COLUMN IF NOT EXISTS expiry_date     date;

COMMENT ON COLUMN erp_stock_in_item.batch_no        IS '批次号：为空时审核入库按 IN{yyyyMMdd}-{项id} 自动生成';
COMMENT ON COLUMN erp_stock_in_item.production_date IS '生产日期（可空）';
COMMENT ON COLUMN erp_stock_in_item.expiry_date     IS '到期日期（可空）：用于效期预警与 FIFO 次级排序';

-- ---------- 4) 库存流水：批次 / 状态 / 成本 ----------
ALTER TABLE erp_stock_record ADD COLUMN IF NOT EXISTS batch_no    varchar(64);
ALTER TABLE erp_stock_record ADD COLUMN IF NOT EXISTS stock_state varchar(16);
ALTER TABLE erp_stock_record ADD COLUMN IF NOT EXISTS unit_cost   numeric(24, 6);
ALTER TABLE erp_stock_record ADD COLUMN IF NOT EXISTS total_cost  numeric(24, 6);
ALTER TABLE erp_stock_record ADD COLUMN IF NOT EXISTS sku_id      bigint;

COMMENT ON COLUMN erp_stock_record.batch_no    IS '批次号：出库按 FIFO 拆批后，一行流水对应一个批次';
COMMENT ON COLUMN erp_stock_record.stock_state IS '状态：IN_STOCK 在仓 / IN_TRANSIT 在途 / OCCUPIED 占用 / INSPECTING 待检';
COMMENT ON COLUMN erp_stock_record.unit_cost   IS '本行批次单位成本；为空表示老流水（未启用批次前）';
COMMENT ON COLUMN erp_stock_record.total_cost  IS '本行成本金额 = count × unit_cost（出库为负，即结转成本）';
COMMENT ON COLUMN erp_stock_record.sku_id      IS 'SKU 编号预留位：NULL/0 = 按物料记账（本切片）';

-- ---------- 5) 回填：erp_stock 既有余额 → 期初批次 ----------
-- 口径：每一条 count <> 0 的 erp_stock 余额落成一个批次号 OPENING 的期初批次，
--       入库日期取该库存行的创建日期；成本未知（历史无成本字段）故记 0，见 docs/stock-center.md「未做项」。
INSERT INTO erp_stock_batch (id, tenant_id, warehouse_id, product_id, sku_id, batch_no, in_date,
                             count, transit_count, occupied_count, inspecting_count,
                             unit_cost, total_cost, remark,
                             creator, create_time, updater, update_time, deleted)
SELECT nextval('erp_stock_batch_seq'), s.tenant_id, s.warehouse_id, s.product_id, 0, 'OPENING',
       COALESCE(s.create_time::date, CURRENT_DATE), s.count, 0, 0, 0, 0, 0,
       '期初批次：由 erp_stock 既有余额回填（历史无成本字段，unit_cost 暂记 0）',
       '1', now(), '1', now(), 0
  FROM erp_stock s
 WHERE s.deleted = 0
   AND s.count <> 0
ON CONFLICT (warehouse_id, product_id, sku_id, batch_no, tenant_id) WHERE deleted = 0 DO NOTHING;

-- 序列与表内 max(id) 对齐（本仓库踩过「序列落后于 max(id)」的坑）
DO $$
DECLARE
    mx bigint;
BEGIN
    SELECT COALESCE(MAX(id), 0) INTO mx FROM erp_stock_batch;
    IF mx > 0 THEN
        PERFORM setval('erp_stock_batch_seq', mx, true);
    END IF;
END $$;

-- ---------- 6) 核对查询 ----------
-- select count(*), sum(count) from erp_stock_batch where deleted = 0;
-- select b.warehouse_id, b.product_id, b.batch_no, b.count, b.unit_cost, b.total_cost, b.expiry_date
--   from erp_stock_batch b where b.deleted = 0 order by b.warehouse_id, b.product_id, b.in_date, b.expiry_date;
-- 可用量 = 在仓 − 占用 + 在途
-- select product_id, warehouse_id,
--        sum(count) - sum(occupied_count) + sum(transit_count) as available_count
--   from erp_stock_batch where deleted = 0 and warehouse_id = 2 group by product_id, warehouse_id order by product_id;
