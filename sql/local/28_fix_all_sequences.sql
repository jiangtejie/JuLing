-- =============================================================================
-- 全库序列体检与修复（PostgreSQL）
--
-- 背景：
--   本项目的补丁脚本大量使用「显式指定 id」插入（菜单/字典/定时任务/角色等），
--   这类插入**不会推进序列**，于是序列落后于 max(id)。表现是随后在界面上新增数据时报
--   duplicate key value violates unique constraint "pk_xxx"（「新增部门」这么踩过，
--   2026-09-28 登录也因 system_oauth2_refresh_token 序列落后而撞主键）。
--
-- 【铁律】任何"手工指定 id"的插入之后，都必须跑本脚本（或在同一批脚本末尾跑一次）。
--   手工指定 id 的写法（错误示范，序列不会动）：
--     INSERT INTO system_menu (id, ...) VALUES (11540, ...);
--     INSERT INTO erp_xxx (id, ...) VALUES ((SELECT COALESCE(MAX(id), 0) + 1 FROM erp_xxx), ...);
--   正确写法（让序列自己发号，与 @KeySequence / IdType.INPUT 的约定一致）：
--     INSERT INTO system_menu (id, ...) VALUES (nextval('system_menu_seq'), ...);
--     INSERT INTO erp_xxx (id, ...) SELECT nextval('erp_xxx_seq'), ... FROM ...;
--   —— 用 (SELECT COALESCE(MAX(id),0)+1 ...) 造 token/菜单/字典是历史踩坑写法：
--      既绕过了序列（下一次 nextval 仍会撞已占用 id），又有并发重复取号问题。请统一改 nextval。
--
-- 内容：
--   1) 体检：遍历 public 下所有"序列名 = 表名_seq 且表有 id 列"的对象，打印落后的表；
--   2) 修复：把序列推进到 max(id)（is_called = true，故下一次 nextval = max(id)+1）。
--
-- 2026-09-28 修复的缺陷：
--   修复段原先写的是 PERFORM setval(s.sequencename, mx, true)：pg_sequences.sequencename 的类型是
--   name，PostgreSQL 只提供 setval(regclass, bigint[, boolean])，没有 name/text 版本，
--   函数解析直接报 "function setval(name, bigint, boolean) does not exist"，
--   于是修复段在第一个落后序列上整体中断——体检能报"落后 N 张"，修复却一行"已修复"都不打印。
--   现在改为显式类型转换 setval(quote_ident(<name>)::regclass, mx, true)（实测通过）。
--   同时补上 is_called 判定：序列若从未被 nextval 调用过（is_called = false），
--   其 last_value 只是 START 值，此时 last_value = max(id) 也必须推进，否则下一次 nextval 仍会撞号。
--
-- 幂等：可重复执行；已一致的序列不会被改动（第二遍应显示"落后 0 张"）。
-- 执行：psql -U root -d yate -f sql/local/28_fix_all_sequences.sql
-- =============================================================================

-- ---------- 1) 体检 ----------
DO $$
DECLARE s record; seq_last bigint; seq_called boolean; mx bigint; tbl text; cnt int := 0; bad int := 0;
BEGIN
  FOR s IN SELECT sequencename FROM pg_sequences WHERE schemaname = 'public' LOOP
    tbl := regexp_replace(s.sequencename, '_seq$', '');
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = tbl)
       AND EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = tbl AND column_name = 'id') THEN
      EXECUTE format('SELECT last_value, is_called FROM %I', s.sequencename) INTO seq_last, seq_called;
      EXECUTE format('SELECT max(id) FROM %I', tbl) INTO mx;
      cnt := cnt + 1;
      IF seq_last IS NOT NULL
         AND (COALESCE(mx, 0) > seq_last OR (NOT seq_called AND COALESCE(mx, 0) >= seq_last)) THEN
        bad := bad + 1;
        RAISE NOTICE '序列落后: %  seq=% (is_called=%)  max(id)=%', tbl, seq_last, seq_called, COALESCE(mx, 0);
      END IF;
    END IF;
  END LOOP;
  RAISE NOTICE '体检完成: 扫描 % 张带序列的表, 落后 % 张', cnt, bad;
END $$;

-- ---------- 2) 修复 ----------
-- 关键点：setval 只接受 regclass，必须显式转换，否则报 function setval(name, bigint, boolean) does not exist
DO $$
DECLARE s record; seq_last bigint; seq_called boolean; mx bigint; tbl text; fixed int := 0;
BEGIN
  FOR s IN SELECT sequencename FROM pg_sequences WHERE schemaname = 'public' LOOP
    tbl := regexp_replace(s.sequencename, '_seq$', '');
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = tbl)
       AND EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = tbl AND column_name = 'id') THEN
      EXECUTE format('SELECT last_value, is_called FROM %I', s.sequencename) INTO seq_last, seq_called;
      EXECUTE format('SELECT max(id) FROM %I', tbl) INTO mx;
      IF seq_last IS NOT NULL
         AND (COALESCE(mx, 0) > seq_last OR (NOT seq_called AND COALESCE(mx, 0) >= seq_last)) THEN
        PERFORM setval(quote_ident(s.sequencename)::regclass, mx, true);
        fixed := fixed + 1;
        RAISE NOTICE '已修复 % : % -> %', tbl, seq_last, mx;
      END IF;
    END IF;
  END LOOP;
  RAISE NOTICE '修复完成: 共修复 % 张表', fixed;
END $$;
