-- =============================================================================
-- 修复 ERP 单据「数量 / 金额」计数器字段为 NULL 导致的问题
--
-- 背景（代码修复见提交 2c8f7f32 fix(erp)）：
--   建单时代码未初始化 in_count / out_count / return_count / receipt_price /
--   payment_price / refund_price，而数据库列可空且无默认值，最终落库为 NULL。
--   SQL 三值逻辑下 NULL 参与比较恒不成立（NULL < x 的结果是 NULL 而不是 TRUE），
--   导致以下「关联单据」弹窗查询结果永远为空：
--     · 采购入库  → 关联采购订单   (t.in_count     < t.total_count)
--     · 采购退货  → 关联采购订单   (t.return_count < t.in_count)
--     · 销售出库  → 关联销售订单   (t.out_count    < t.total_count)
--     · 销售退货  → 关联销售订单   (t.return_count < t.out_count)
--     · 收款单    → 选择销售出库单 (t.receipt_price  < t.total_price)
--     · 付款单    → 选择采购入库单 (t.payment_price  < t.total_price)
--     · 退款单    → 选择销售/采购退货单 (t.refund_price < t.total_price)
--   同时 Java 侧对这些字段做 compareTo / equals 会抛 NPE。
--
-- 本脚本做两件事，与代码修复配合才能根治：
--   1. 把历史 NULL 回填为 0；
--   2. 给这些列补上 DEFAULT 0，避免后续非 ORM 写入再次落 NULL。
--   代码侧已在 2c8f7f32 改为建单时显式初始化 0。
--
-- 幂等：可重复执行。回填用 WHERE ... IS NULL 收敛，SET DEFAULT 天然幂等；
--       备份快照仅在首次执行且表内有数据时生成，不会覆盖最早的快照。
--
-- 执行方式：
--   docker cp sql/local/12_fix_erp_null_counters.sql postgres:/tmp/fix_erp_null_counters.sql
--   docker exec postgres psql -U root -d juling -f /tmp/fix_erp_null_counters.sql
--   或：psql -U root -d juling -f sql/local/12_fix_erp_null_counters.sql
--
-- 说明：erp_* 业务表不在 sql/postgresql/juling-baseline.sql 中（由 ERP 模块单独建表）。
--       全新环境若尚未导入这些表，脚本会自动跳过缺失的表/列并打印 NOTICE，不会报错。
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. 备份：仅对「存在且有数据」的表生成修复前快照
--    （快照已存在则跳过，保证保留的始终是最早一次执行前的原始数据；
--      全新环境表为空时不产生备份，避免冗余）
-- -----------------------------------------------------------------------------
DO $$
DECLARE
    v_tbl  text;
    v_has  boolean;
    v_tbls text[] := ARRAY[
        'erp_purchase_order',       'erp_purchase_order_items',
        'erp_sale_order',           'erp_sale_order_items',
        'erp_purchase_in',          'erp_sale_out',
        'erp_purchase_return',      'erp_sale_return'
    ];
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.schemata WHERE schema_name = 'bak_erp_null_counters') THEN
        EXECUTE 'CREATE SCHEMA bak_erp_null_counters';
        RAISE NOTICE '[备份] 已创建 schema：bak_erp_null_counters';
    END IF;

    FOREACH v_tbl IN ARRAY v_tbls LOOP
        IF to_regclass('public.' || v_tbl) IS NULL THEN
            RAISE NOTICE '[备份] 跳过(表不存在)：public.%', v_tbl;
            CONTINUE;
        END IF;
        IF to_regclass('bak_erp_null_counters.' || v_tbl) IS NOT NULL THEN
            RAISE NOTICE '[备份] 跳过(快照已存在)：bak_erp_null_counters.%', v_tbl;
            CONTINUE;
        END IF;
        EXECUTE format('SELECT EXISTS (SELECT 1 FROM public.%I LIMIT 1)', v_tbl) INTO v_has;
        IF NOT v_has THEN
            RAISE NOTICE '[备份] 跳过(表为空)：public.%', v_tbl;
            CONTINUE;
        END IF;
        EXECUTE format('CREATE TABLE bak_erp_null_counters.%I AS SELECT * FROM public.%I', v_tbl, v_tbl);
        RAISE NOTICE '[备份] 已生成快照：bak_erp_null_counters.%', v_tbl;
    END LOOP;
END $$;

-- -----------------------------------------------------------------------------
-- 2. 回填 NULL -> 0，并补上 DEFAULT 0；逐列打印处理结果
-- -----------------------------------------------------------------------------
DO $$
DECLARE
    v_rec   record;
    v_rows  bigint;
    v_nulls bigint;
    v_def   text;
    v_done  int := 0;
    v_skip  int := 0;
BEGIN
    RAISE NOTICE '========== 开始回填 ==========';
    FOR v_rec IN
        SELECT * FROM (VALUES
            -- 数量计数器（采购 / 销售 的订单与明细）
            ('erp_purchase_order',       'in_count'),
            ('erp_purchase_order',       'return_count'),
            ('erp_purchase_order_items', 'in_count'),
            ('erp_purchase_order_items', 'return_count'),
            ('erp_sale_order',           'out_count'),
            ('erp_sale_order',           'return_count'),
            ('erp_sale_order_items',     'out_count'),
            ('erp_sale_order_items',     'return_count'),
            -- 金额计数器（入库 / 出库 / 退货）
            ('erp_purchase_in',          'payment_price'),
            ('erp_sale_out',             'receipt_price'),
            ('erp_purchase_return',      'refund_price'),
            ('erp_sale_return',          'refund_price')
        ) AS v(tbl, col)
    LOOP
        IF to_regclass('public.' || v_rec.tbl) IS NULL THEN
            RAISE NOTICE '[跳过] 表不存在：public.%', v_rec.tbl;
            v_skip := v_skip + 1;
            CONTINUE;
        END IF;
        IF NOT EXISTS (
            SELECT 1 FROM information_schema.columns
            WHERE table_schema = 'public' AND table_name = v_rec.tbl AND column_name = v_rec.col
        ) THEN
            RAISE NOTICE '[跳过] 列不存在：public.%.%', v_rec.tbl, v_rec.col;
            v_skip := v_skip + 1;
            CONTINUE;
        END IF;

        EXECUTE format('UPDATE public.%I SET %I = 0 WHERE %I IS NULL', v_rec.tbl, v_rec.col, v_rec.col);
        GET DIAGNOSTICS v_rows = ROW_COUNT;

        EXECUTE format('ALTER TABLE public.%I ALTER COLUMN %I SET DEFAULT 0', v_rec.tbl, v_rec.col);

        EXECUTE format('SELECT count(*) FROM public.%I WHERE %I IS NULL', v_rec.tbl, v_rec.col) INTO v_nulls;
        SELECT column_default INTO v_def
        FROM information_schema.columns
        WHERE table_schema = 'public' AND table_name = v_rec.tbl AND column_name = v_rec.col;

        RAISE NOTICE '[完成] public.%.% ：回填 % 行，剩余 NULL % 行，默认值 %',
            v_rec.tbl, v_rec.col, v_rows, v_nulls, COALESCE(v_def, '(未设置)');
        v_done := v_done + 1;
    END LOOP;
    RAISE NOTICE '========== 回填结束：处理 % 列，跳过 % 列 ==========', v_done, v_skip;
    RAISE NOTICE '判定标准：上方每行的「剩余 NULL」均为 0、且默认值为 0，即修复生效。';
END $$;
