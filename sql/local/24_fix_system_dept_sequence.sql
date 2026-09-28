-- ============================================================================
-- 修复 system_dept 主键序列落后于数据（新增部门报「系统异常」）
--
-- 现象：后台「新增部门」失败，后端日志报
--       duplicate key value violates unique constraint "pk_system_dept"
--
-- 原因：yudao 的 ID 由 MyBatis-Plus 按序列生成（@KeySequence("system_dept_seq")，
--       表列本身没有 default），而本库数据是从旧库迁移过来的：行带着既有 id 导入，
--       序列却停在迁移前的值（实测 last_value=124，而 max(id)=165），
--       于是 nextval 取到已存在的 id，插入直接撞主键。
--
-- 本脚本把序列推进到「当前最大 id + 1」，之后 nextval 从 166 开始，不再冲突。
-- 幂等：重复执行只是把序列重新对齐到 max(id)+1。
-- ============================================================================

SELECT setval('system_dept_seq', (SELECT COALESCE(max(id), 0) + 1 FROM system_dept), false);

-- 校验：last_value 应 = 表内 max(id) + 1
SELECT last_value, is_called FROM system_dept_seq;
SELECT max(id) AS max_dept_id FROM system_dept;

-- 其他环境排查同类问题（序列名以 _seq 结尾、表主键为 id 的约定）：
-- DO $$
-- DECLARE r record; mx bigint; tbl text; has_id boolean;
-- BEGIN
--   FOR r IN SELECT sequencename, last_value FROM pg_sequences
--            WHERE schemaname = 'public' AND last_value IS NOT NULL ORDER BY sequencename
--   LOOP
--     tbl := regexp_replace(r.sequencename, '_seq$', '');
--     SELECT EXISTS (SELECT 1 FROM information_schema.columns
--                    WHERE table_schema='public' AND table_name=tbl AND column_name='id') INTO has_id;
--     IF has_id THEN
--       EXECUTE format('SELECT COALESCE(max(id),0) FROM %I', tbl) INTO mx;
--       IF mx > r.last_value THEN
--         RAISE NOTICE 'MISMATCH % last_value=% max_id=%', r.sequencename, r.last_value, mx;
--       END IF;
--     END IF;
--   END LOOP;
-- END $$;
