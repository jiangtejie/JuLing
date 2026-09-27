-- =============================================================================
-- 补齐缺失的主键（PostgreSQL）
--
-- 背景：
--   yate 库由 juling 库复制/转换而来，业务模块的表大量丢失了主键约束。
--   2026-09-27 实测：public schema 552 张普通表中有 453 张没有主键，
--   而这 453 张表的 id 列本身「无 NULL、无重复」，说明是转换时丢的约束，不是数据问题。
--
--   由此引发的问题（同一根因）：
--     1) 关联查询 + GROUP BY 主键时，PostgreSQL 无法做主键函数依赖推断，直接报
--        column "t.xxx" must appear in the GROUP BY clause（MySQL 宽松模式不报）。
--        实例：采购订单列表按「商品」筛选，见 2026-09-20 日志
--        （ErpPurchaseOrderMapper#selectPage 里的 groupBy(ErpPurchaseOrderDO::getId)）。
--     2) 依赖主键存在的其它能力（MP 批量操作、逻辑复制、CDC 同步）同样受影响。
--
-- 行为：
--   遍历 public schema 所有普通表，对「缺主键 + 有 id 列 + id 无 NULL 且唯一」的表
--   补 PRIMARY KEY (id)；不满足的表跳过并打印 NOTICE。可重复执行（幂等）。
--
-- 执行：
--   psql -U root -d yate -f sql/local/15_add_missing_primary_keys.sql
--   干跑（只统计不修改）：把下面 EXECUTE ... ADD PRIMARY KEY 那一行注释掉再执行。
-- =============================================================================
DO $$
DECLARE
    r record;
    null_cnt bigint;
    dup_cnt bigint;
    added int := 0;
    skipped int := 0;
BEGIN
    FOR r IN
        SELECT c.relname
        FROM pg_class c
        JOIN pg_namespace n ON n.oid = c.relnamespace
        WHERE c.relkind = 'r'
          AND n.nspname = 'public'
          AND NOT EXISTS (SELECT 1 FROM pg_constraint k
                          WHERE k.conrelid = c.oid AND k.contype = 'p')
        ORDER BY c.relname
    LOOP
        -- 关联表等没有 id 列的表不动
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns col
                       WHERE col.table_schema = 'public'
                         AND col.table_name = r.relname
                         AND col.column_name = 'id') THEN
            RAISE NOTICE 'skip % : 无 id 列', r.relname;
            skipped := skipped + 1;
            CONTINUE;
        END IF;

        -- id 为空或重复的表交人工处理，不冒险加约束
        EXECUTE format('SELECT count(*) FROM public.%I WHERE id IS NULL', r.relname) INTO null_cnt;
        EXECUTE format('SELECT count(*) - count(DISTINCT id) FROM public.%I', r.relname) INTO dup_cnt;
        IF null_cnt > 0 OR dup_cnt > 0 THEN
            RAISE NOTICE 'skip % : id 存在 NULL(%) 或重复(%)，需人工处理', r.relname, null_cnt, dup_cnt;
            skipped := skipped + 1;
            CONTINUE;
        END IF;

        EXECUTE format('ALTER TABLE public.%I ADD PRIMARY KEY (id)', r.relname);
        added := added + 1;
    END LOOP;
    RAISE NOTICE '补主键完成：新增 % 张，跳过 % 张', added, skipped;
END $$;
