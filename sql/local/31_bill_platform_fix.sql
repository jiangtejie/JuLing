-- =============================================================================
-- 单据基座修复（2026-09-28 复核后）
--
-- 背景与修法：
--   1) 单号位数未与旧生成器对齐：旧格式为 {前缀}+yyyyMMdd+6 位流水（ErpNoRedisDAO），
--      平台初版配的是 4 位 → 统一改成 6 位；
--   2) 前缀双真相：ERP 已有单据的前缀以 ErpNoRedisDAO 为准，平台配置与之对齐
--      （避免同一单据出现两种前缀）；蓝图新增单据保留新前缀；
--   3) 切换生成器必须先"接上当天已有流水"，否则同一天会出现"单号已存在"
--      → 本脚本按当天已发单号的最大流水回填 bill_no_seq（GREATEST 保护，幂等）；
--   4) 补注册 ERP 原生但漏登记的两类：销售订单(XSDD)、销售退货(XSTH)；
--   5) 注册单据平台查询权限 bill:platform:query（超管天然可用，其它角色可在菜单里勾选）。
--
-- 幂等：可重复执行。
-- 执行：psql -U root -d yate -f sql/local/31_bill_platform_fix.sql
-- =============================================================================

-- ---------- 1) 流水位数统一 6 位（与旧格式一致） ----------
UPDATE bill_type SET no_seq_length = 6, updater = '1', update_time = now() WHERE no_seq_length <> 6;

-- ---------- 2) 补注册 ERP 原生单据类型 ----------
INSERT INTO bill_type (id, code, name, module, no_prefix, no_date_format, no_reset, no_seq_length, need_audit, bpm_process_key, affect_stock, affect_finance, status, sort, remark, tenant_id, creator, create_time, updater, update_time, deleted) VALUES
 (27, 'SALE_ORDER',  '销售订单', 'erp', 'XSDD', 'yyyyMMdd', 'D', 6, TRUE, '', FALSE, FALSE, 0, 27, 'ERP 原生（门店要货下推的销售订单）', 1, '1', now(), '1', now(), 0),
 (28, 'SALE_RETURN', '销售退货', 'erp', 'XSTH', 'yyyyMMdd', 'D', 6, TRUE, '', TRUE,  TRUE,  0, 28, 'ERP 原生', 1, '1', now(), '1', now(), 0)
ON CONFLICT (id) DO NOTHING;

-- ---------- 3) 前缀与 ERP 既有口径对齐 ----------
UPDATE bill_type SET no_prefix = v.prefix, updater = '1', update_time = now()
FROM (VALUES
    ('DELIVERY_OUT',    'XSCK'),   -- 配送出库 = ERP 销售出库（同一张单，避免双前缀）
    ('STOCK_TRANSFER',  'QCDB'),
    ('STOCK_CHECK',     'QCPD'),
    ('OTHER_OUT',       'QCKD'),
    ('FINANCE_PAYMENT', 'FKD'),
    ('FINANCE_RECEIPT', 'SKD')
) AS v(code, prefix)
WHERE bill_type.code = v.code AND bill_type.no_prefix <> v.prefix;

-- ---------- 4) 按当天已有单号回填流水起点（防止切换日"单号已存在"） ----------
DO $$
DECLARE
    m record;
    mx bigint;
    today text := to_char(now(), 'YYYYMMDD');
    total int := 0;
BEGIN
    FOR m IN
        SELECT * FROM (VALUES
            ('PURCHASE_ORDER',   'erp_purchase_order',   'CGDD'),
            ('PURCHASE_IN',      'erp_purchase_in',      'CGRK'),
            ('PURCHASE_RETURN',  'erp_purchase_return',  'CGTH'),
            ('SALE_ORDER',       'erp_sale_order',       'XSDD'),
            ('SALE_OUT',         'erp_sale_out',         'XSCK'),
            ('SALE_RETURN',      'erp_sale_return',      'XSTH'),
            ('OTHER_IN',         'erp_stock_in',         'QTRK'),
            ('OTHER_OUT',        'erp_stock_out',        'QCKD'),
            ('STOCK_TRANSFER',   'erp_stock_move',       'QCDB'),
            ('STOCK_CHECK',      'erp_stock_check',      'QCPD'),
            ('FINANCE_PAYMENT',  'erp_finance_payment',  'FKD'),
            ('FINANCE_RECEIPT',  'erp_finance_receipt',  'SKD')
        ) AS t(bill_type, tbl, prefix)
    LOOP
        IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = m.tbl)
           AND EXISTS (SELECT 1 FROM bill_type WHERE code = m.bill_type) THEN
            EXECUTE format(
                'SELECT COALESCE(MAX(RIGHT(no, 6)::bigint), 0) FROM %I WHERE no LIKE %L AND length(no) = %s',
                m.tbl, m.prefix || today || '%', length(m.prefix) + 14) INTO mx;
            IF mx > 0 THEN
                EXECUTE format(
                    'INSERT INTO bill_no_seq (id, bill_type, org_id, period, last_no, tenant_id, creator, create_time, updater, update_time, deleted)
                     VALUES (nextval(''bill_no_seq_seq''), %L, 0, %L, %s, 1, ''1'', now(), ''1'', now(), 0)
                     ON CONFLICT (bill_type, org_id, period, tenant_id) WHERE deleted = 0
                     DO UPDATE SET last_no = GREATEST(bill_no_seq.last_no, EXCLUDED.last_no), update_time = now()',
                    m.bill_type, today, mx);
                total := total + 1;
                RAISE NOTICE '回填 % 今天流水起点 = %', m.bill_type, mx;
            END IF;
        END IF;
    END LOOP;
    RAISE NOTICE '回填完成，共 % 类', total;
END $$;

-- ---------- 5) 单据平台查询权限（按钮权限；超管天然可用） ----------
INSERT INTO system_menu (id, name, permission, type, sort, parent_id, path, icon, component, component_name, status, visible, keep_alive, always_show, creator, create_time, updater, update_time, deleted)
VALUES (11540, '单据平台查询', 'bill:platform:query', 3, 13, 2076, '', '', '', '', 0, TRUE, TRUE, FALSE, '1', now(), '1', now(), 0)
ON CONFLICT (id) DO NOTHING;
