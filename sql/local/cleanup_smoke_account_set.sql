-- Cleanup smoke-test account set (id = 2) and every row that references it.
-- Run inside the container to avoid host shell encoding issues:
--   docker cp script/local/cleanup_smoke_account_set.sql postgres:/tmp/cleanup.sql
--   docker exec postgres psql -U root -d juling -f /tmp/cleanup.sql

UPDATE fms_account_set SET currency_id = NULL WHERE id = 2;

DO $$
DECLARE
    r RECORD;
BEGIN
    FOR r IN
        SELECT table_name
        FROM information_schema.columns
        WHERE table_schema = 'public' AND column_name = 'account_set_id'
        ORDER BY table_name
    LOOP
        EXECUTE format('DELETE FROM public.%I WHERE account_set_id = 2', r.table_name);
        IF (SELECT count(*) FROM information_schema.tables WHERE table_name = r.table_name) > 0 THEN
            RAISE NOTICE 'cleaned table: %', r.table_name;
        END IF;
    END LOOP;
END $$;

DELETE FROM fms_account_set WHERE id = 2;

SELECT count(*) AS remain_subject_rows FROM fms_subject WHERE account_set_id = 2;
SELECT count(*) AS remain_account_users FROM fms_account_user WHERE account_set_id = 2;
SELECT id, company_name, initialized FROM fms_account_set ORDER BY id;
