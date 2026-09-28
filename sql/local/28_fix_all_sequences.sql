-- =============================================================================
-- 全库序列体检与修复（PostgreSQL）
--
-- 背景：
--   本项目的补丁脚本大量使用「显式指定 id」插入（菜单/字典/定时任务/角色等），
--   这类插入**不会推进序列**，于是序列落后于 max(id)。表现是随后在界面上新增数据时报
--   duplicate key value violates unique constraint "pk_xxx"（「新增部门」就这么踩过）。
--
-- 内容：
--   1) 体检：遍历 public 下所有"序列名 = 表名_seq 且表有 id 列"的对象，打印落后的表；
--   2) 修复：把序列推进到 max(id)（is_called = true，故下一次 nextval = max(id)+1）。
--
-- 幂等：可重复执行；已一致的序列不会被改动。
-- 执行：psql -U root -d yate -f sql/local/28_fix_all_sequences.sql
-- =============================================================================

-- ---------- 1) 体检 ----------
DO $$
DECLARE s record; seq_last bigint; mx bigint; tbl text; cnt int := 0; bad int := 0;
BEGIN
  FOR s IN SELECT sequencename FROM pg_sequences WHERE schemaname = 'public' LOOP
    tbl := regexp_replace(s.sequencename, '_seq$', '');
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = tbl)
       AND EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = tbl AND column_name = 'id') THEN
      EXECUTE format('SELECT last_value FROM %I', s.sequencename) INTO seq_last;
      EXECUTE format('SELECT max(id) FROM %I', tbl) INTO mx;
      cnt := cnt + 1;
      IF seq_last IS NOT NULL AND mx IS NOT NULL AND seq_last < mx THEN
        bad := bad + 1;
        RAISE NOTICE '序列落后: %  seq=%  max(id)=%', tbl, seq_last, mx;
      END IF;
    END IF;
  END LOOP;
  RAISE NOTICE '体检完成: 扫描 % 张带序列的表, 落后 % 张', cnt, bad;
END $$;

-- ---------- 2) 修复 ----------
DO $$
DECLARE s record; seq_last bigint; mx bigint; tbl text; fixed int := 0;
BEGIN
  FOR s IN SELECT sequencename FROM pg_sequences WHERE schemaname = 'public' LOOP
    tbl := regexp_replace(s.sequencename, '_seq$', '');
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = tbl)
       AND EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = tbl AND column_name = 'id') THEN
      EXECUTE format('SELECT last_value FROM %I', s.sequencename) INTO seq_last;
      EXECUTE format('SELECT max(id) FROM %I', tbl) INTO mx;
      IF seq_last IS NOT NULL AND mx IS NOT NULL AND seq_last < mx THEN
        PERFORM setval(s.sequencename, mx, true);
        fixed := fixed + 1;
        RAISE NOTICE '已修复 % : % -> %', tbl, seq_last, mx;
      END IF;
    END IF;
  END LOOP;
  RAISE NOTICE '修复完成: 共修复 % 张表', fixed;
END $$;
