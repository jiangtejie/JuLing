-- ============================================================================
-- 58 全库测试数据物理清理（备份 → 删除）
--
-- 目的：把库里的测试/演示数据清干净，为真实数据进场做准备。
--
-- 安全设计：**先整表备份到 bak_testdata_20261007，再删除** —— 本次删除可回退
--   （回退 = 从备份 schema 把行插回）。脚本在单个事务内执行，失败整体回滚。
--
-- 清理范围：
--   A 测试业务数据 49 张表：库存/批次/流水、采购销售单据、收付款、门店往来台账、
--     购物车/浏览/收藏/统计、售后日志、记账凭证、单据流水号
--   B 演示主数据 12 张表：客户（14 行全部 remark='demo-seed'）、物料、商品、分类、
--     供应商、演示会员账号与其授权
--   C 运行时数据 7 张表：登录令牌、登录日志、操作日志、API 错误日志、短信码、上传文件记录
--   D system_dept 的 13 个门店节点（dept_type = 'STORE'）
--   E erp_warehouse 的 13 个门店仓（store_customer_id IS NOT NULL）+ 1 个门店虚拟仓（命名规则不同、未设 store_customer_id）
--
-- 明确**不动**：system_menu / dict / role / post / user（含真实员工贺玲等）、system_dept 组织节点、
--   erp_product_unit（通用单位）、bill_type（单据类型定义）、fms_subject(+template)、fms_closing（结转方案）、
--   ai_model / ai_api_key、infra_config / infra_job、bpm 的真实流程定义（trade-order-store-audit）、
--   qrtz_*、以及 act_* 引擎表（引擎表由 Flowable 管理，删测试流程请走「流程管理」界面）。
--
-- 幂等：可重复执行（备份表已存在时不覆盖；删除对空表安全）。
-- ============================================================================

BEGIN;

-- ---------------------------------------------------------------------------
-- 1) 备份（整表快照，含已软删行）
-- ---------------------------------------------------------------------------
CREATE SCHEMA IF NOT EXISTS bak_testdata_20261007;

CREATE TABLE IF NOT EXISTS bak_testdata_20261007.erp_stock AS SELECT * FROM public.erp_stock;
CREATE TABLE IF NOT EXISTS bak_testdata_20261007.erp_stock_batch AS SELECT * FROM public.erp_stock_batch;
CREATE TABLE IF NOT EXISTS bak_testdata_20261007.erp_stock_record AS SELECT * FROM public.erp_stock_record;
CREATE TABLE IF NOT EXISTS bak_testdata_20261007.erp_stock_move AS SELECT * FROM public.erp_stock_move;
CREATE TABLE IF NOT EXISTS bak_testdata_20261007.erp_stock_move_item AS SELECT * FROM public.erp_stock_move_item;
CREATE TABLE IF NOT EXISTS bak_testdata_20261007.erp_stock_in AS SELECT * FROM public.erp_stock_in;
CREATE TABLE IF NOT EXISTS bak_testdata_20261007.erp_stock_in_item AS SELECT * FROM public.erp_stock_in_item;
CREATE TABLE IF NOT EXISTS bak_testdata_20261007.erp_stock_out AS SELECT * FROM public.erp_stock_out;
CREATE TABLE IF NOT EXISTS bak_testdata_20261007.erp_stock_out_item AS SELECT * FROM public.erp_stock_out_item;
CREATE TABLE IF NOT EXISTS bak_testdata_20261007.erp_stock_check AS SELECT * FROM public.erp_stock_check;
CREATE TABLE IF NOT EXISTS bak_testdata_20261007.erp_stock_check_item AS SELECT * FROM public.erp_stock_check_item;
CREATE TABLE IF NOT EXISTS bak_testdata_20261007.erp_purchase_order AS SELECT * FROM public.erp_purchase_order;
CREATE TABLE IF NOT EXISTS bak_testdata_20261007.erp_purchase_order_items AS SELECT * FROM public.erp_purchase_order_items;
CREATE TABLE IF NOT EXISTS bak_testdata_20261007.erp_purchase_in AS SELECT * FROM public.erp_purchase_in;
CREATE TABLE IF NOT EXISTS bak_testdata_20261007.erp_purchase_in_items AS SELECT * FROM public.erp_purchase_in_items;
CREATE TABLE IF NOT EXISTS bak_testdata_20261007.erp_purchase_return AS SELECT * FROM public.erp_purchase_return;
CREATE TABLE IF NOT EXISTS bak_testdata_20261007.erp_purchase_return_items AS SELECT * FROM public.erp_purchase_return_items;
CREATE TABLE IF NOT EXISTS bak_testdata_20261007.erp_sale_order AS SELECT * FROM public.erp_sale_order;
CREATE TABLE IF NOT EXISTS bak_testdata_20261007.erp_sale_order_items AS SELECT * FROM public.erp_sale_order_items;
CREATE TABLE IF NOT EXISTS bak_testdata_20261007.erp_sale_out AS SELECT * FROM public.erp_sale_out;
CREATE TABLE IF NOT EXISTS bak_testdata_20261007.erp_sale_out_items AS SELECT * FROM public.erp_sale_out_items;
CREATE TABLE IF NOT EXISTS bak_testdata_20261007.erp_sale_return AS SELECT * FROM public.erp_sale_return;
CREATE TABLE IF NOT EXISTS bak_testdata_20261007.erp_sale_return_items AS SELECT * FROM public.erp_sale_return_items;
CREATE TABLE IF NOT EXISTS bak_testdata_20261007.erp_finance_receipt AS SELECT * FROM public.erp_finance_receipt;
CREATE TABLE IF NOT EXISTS bak_testdata_20261007.erp_finance_receipt_item AS SELECT * FROM public.erp_finance_receipt_item;
CREATE TABLE IF NOT EXISTS bak_testdata_20261007.erp_finance_payment AS SELECT * FROM public.erp_finance_payment;
CREATE TABLE IF NOT EXISTS bak_testdata_20261007.erp_finance_payment_item AS SELECT * FROM public.erp_finance_payment_item;
CREATE TABLE IF NOT EXISTS bak_testdata_20261007.erp_account AS SELECT * FROM public.erp_account;
CREATE TABLE IF NOT EXISTS bak_testdata_20261007.erp_customer_account AS SELECT * FROM public.erp_customer_account;
CREATE TABLE IF NOT EXISTS bak_testdata_20261007.trade_cart AS SELECT * FROM public.trade_cart;
CREATE TABLE IF NOT EXISTS bak_testdata_20261007.trade_order AS SELECT * FROM public.trade_order;
CREATE TABLE IF NOT EXISTS bak_testdata_20261007.trade_order_item AS SELECT * FROM public.trade_order_item;
CREATE TABLE IF NOT EXISTS bak_testdata_20261007.trade_order_log AS SELECT * FROM public.trade_order_log;
CREATE TABLE IF NOT EXISTS bak_testdata_20261007.trade_after_sale AS SELECT * FROM public.trade_after_sale;
CREATE TABLE IF NOT EXISTS bak_testdata_20261007.trade_after_sale_log AS SELECT * FROM public.trade_after_sale_log;
CREATE TABLE IF NOT EXISTS bak_testdata_20261007.trade_statistics AS SELECT * FROM public.trade_statistics;
CREATE TABLE IF NOT EXISTS bak_testdata_20261007.product_browse_history AS SELECT * FROM public.product_browse_history;
CREATE TABLE IF NOT EXISTS bak_testdata_20261007.product_favorite AS SELECT * FROM public.product_favorite;
CREATE TABLE IF NOT EXISTS bak_testdata_20261007.product_statistics AS SELECT * FROM public.product_statistics;
CREATE TABLE IF NOT EXISTS bak_testdata_20261007.bill_log AS SELECT * FROM public.bill_log;
CREATE TABLE IF NOT EXISTS bak_testdata_20261007.bill_relation AS SELECT * FROM public.bill_relation;
CREATE TABLE IF NOT EXISTS bak_testdata_20261007.bill_no_seq AS SELECT * FROM public.bill_no_seq;
CREATE TABLE IF NOT EXISTS bak_testdata_20261007.fms_voucher AS SELECT * FROM public.fms_voucher;
CREATE TABLE IF NOT EXISTS bak_testdata_20261007.fms_voucher_entry AS SELECT * FROM public.fms_voucher_entry;
CREATE TABLE IF NOT EXISTS bak_testdata_20261007.fms_initial_balance AS SELECT * FROM public.fms_initial_balance;
CREATE TABLE IF NOT EXISTS bak_testdata_20261007.fms_balance_sheet_report AS SELECT * FROM public.fms_balance_sheet_report;
CREATE TABLE IF NOT EXISTS bak_testdata_20261007.fms_income_statement_report AS SELECT * FROM public.fms_income_statement_report;
CREATE TABLE IF NOT EXISTS bak_testdata_20261007.fms_cash_flow_extend_data AS SELECT * FROM public.fms_cash_flow_extend_data;
CREATE TABLE IF NOT EXISTS bak_testdata_20261007.fms_cash_flow_statement_report AS SELECT * FROM public.fms_cash_flow_statement_report;
CREATE TABLE IF NOT EXISTS bak_testdata_20261007.erp_customer AS SELECT * FROM public.erp_customer;
CREATE TABLE IF NOT EXISTS bak_testdata_20261007.erp_product AS SELECT * FROM public.erp_product;
CREATE TABLE IF NOT EXISTS bak_testdata_20261007.erp_product_category AS SELECT * FROM public.erp_product_category;
CREATE TABLE IF NOT EXISTS bak_testdata_20261007.erp_supplier AS SELECT * FROM public.erp_supplier;
CREATE TABLE IF NOT EXISTS bak_testdata_20261007.product_spu AS SELECT * FROM public.product_spu;
CREATE TABLE IF NOT EXISTS bak_testdata_20261007.product_sku AS SELECT * FROM public.product_sku;
CREATE TABLE IF NOT EXISTS bak_testdata_20261007.product_category AS SELECT * FROM public.product_category;
CREATE TABLE IF NOT EXISTS bak_testdata_20261007.product_property AS SELECT * FROM public.product_property;
CREATE TABLE IF NOT EXISTS bak_testdata_20261007.product_property_value AS SELECT * FROM public.product_property_value;
CREATE TABLE IF NOT EXISTS bak_testdata_20261007.product_brand AS SELECT * FROM public.product_brand;
CREATE TABLE IF NOT EXISTS bak_testdata_20261007.member_user AS SELECT * FROM public.member_user;
CREATE TABLE IF NOT EXISTS bak_testdata_20261007.member_user_store AS SELECT * FROM public.member_user_store;
CREATE TABLE IF NOT EXISTS bak_testdata_20261007.system_oauth2_access_token AS SELECT * FROM public.system_oauth2_access_token;
CREATE TABLE IF NOT EXISTS bak_testdata_20261007.system_oauth2_refresh_token AS SELECT * FROM public.system_oauth2_refresh_token;
CREATE TABLE IF NOT EXISTS bak_testdata_20261007.system_login_log AS SELECT * FROM public.system_login_log;
CREATE TABLE IF NOT EXISTS bak_testdata_20261007.system_operate_log AS SELECT * FROM public.system_operate_log;
CREATE TABLE IF NOT EXISTS bak_testdata_20261007.infra_api_error_log AS SELECT * FROM public.infra_api_error_log;
CREATE TABLE IF NOT EXISTS bak_testdata_20261007.system_sms_code AS SELECT * FROM public.system_sms_code;
CREATE TABLE IF NOT EXISTS bak_testdata_20261007.infra_file AS SELECT * FROM public.infra_file;
CREATE TABLE IF NOT EXISTS bak_testdata_20261007.erp_warehouse_store AS SELECT * FROM public.erp_warehouse WHERE store_customer_id IS NOT NULL;
CREATE TABLE IF NOT EXISTS bak_testdata_20261007.erp_warehouse_virtual AS SELECT * FROM public.erp_warehouse WHERE name LIKE '门店虚拟仓%';
CREATE TABLE IF NOT EXISTS bak_testdata_20261007.system_dept_store AS SELECT * FROM public.system_dept WHERE dept_type = 'STORE';

-- ---------------------------------------------------------------------------
-- 2) 删除
-- ---------------------------------------------------------------------------
-- A 测试业务数据
DELETE FROM public.erp_stock;
DELETE FROM public.erp_stock_batch;
DELETE FROM public.erp_stock_record;
DELETE FROM public.erp_stock_move;
DELETE FROM public.erp_stock_move_item;
DELETE FROM public.erp_stock_in;
DELETE FROM public.erp_stock_in_item;
DELETE FROM public.erp_stock_out;
DELETE FROM public.erp_stock_out_item;
DELETE FROM public.erp_stock_check;
DELETE FROM public.erp_stock_check_item;
DELETE FROM public.erp_purchase_order;
DELETE FROM public.erp_purchase_order_items;
DELETE FROM public.erp_purchase_in;
DELETE FROM public.erp_purchase_in_items;
DELETE FROM public.erp_purchase_return;
DELETE FROM public.erp_purchase_return_items;
DELETE FROM public.erp_sale_order;
DELETE FROM public.erp_sale_order_items;
DELETE FROM public.erp_sale_out;
DELETE FROM public.erp_sale_out_items;
DELETE FROM public.erp_sale_return;
DELETE FROM public.erp_sale_return_items;
DELETE FROM public.erp_finance_receipt;
DELETE FROM public.erp_finance_receipt_item;
DELETE FROM public.erp_finance_payment;
DELETE FROM public.erp_finance_payment_item;
DELETE FROM public.erp_account;
DELETE FROM public.erp_customer_account;
DELETE FROM public.trade_cart;
DELETE FROM public.trade_order;
DELETE FROM public.trade_order_item;
DELETE FROM public.trade_order_log;
DELETE FROM public.trade_after_sale;
DELETE FROM public.trade_after_sale_log;
DELETE FROM public.trade_statistics;
DELETE FROM public.product_browse_history;
DELETE FROM public.product_favorite;
DELETE FROM public.product_statistics;
DELETE FROM public.bill_log;
DELETE FROM public.bill_relation;
DELETE FROM public.bill_no_seq;
DELETE FROM public.fms_voucher;
DELETE FROM public.fms_voucher_entry;
DELETE FROM public.fms_initial_balance;
DELETE FROM public.fms_balance_sheet_report;
DELETE FROM public.fms_income_statement_report;
DELETE FROM public.fms_cash_flow_extend_data;
DELETE FROM public.fms_cash_flow_statement_report;

-- B 演示主数据
DELETE FROM public.erp_customer;
DELETE FROM public.erp_product;
DELETE FROM public.erp_product_category;
DELETE FROM public.erp_supplier;
DELETE FROM public.product_spu;
DELETE FROM public.product_sku;
DELETE FROM public.product_category;
DELETE FROM public.product_property;
DELETE FROM public.product_property_value;
DELETE FROM public.product_brand;
DELETE FROM public.member_user;
DELETE FROM public.member_user_store;

-- C 运行时数据
DELETE FROM public.system_oauth2_access_token;
DELETE FROM public.system_oauth2_refresh_token;
DELETE FROM public.system_login_log;
DELETE FROM public.system_operate_log;
DELETE FROM public.infra_api_error_log;
DELETE FROM public.system_sms_code;
DELETE FROM public.infra_file;

-- D 门店组织节点（13 个）
DELETE FROM public.system_dept WHERE dept_type = 'STORE';

-- E 门店仓（13 个）；公司仓库 / 中心库保留
DELETE FROM public.erp_warehouse WHERE store_customer_id IS NOT NULL OR name LIKE '门店虚拟仓%';

-- ---------------------------------------------------------------------------
-- 3) 编码规则当前值重算（删空的对象从 000001 重新开始；有保留行的按实际最大值对齐）
-- ---------------------------------------------------------------------------
UPDATE system_code_rule r SET current_value = COALESCE((SELECT max(right(t.code, r.seq_length)::bigint) FROM erp_customer t WHERE t.code IS NOT NULL), 0),
  updater = 'script58', update_time = now() WHERE r.rule_key = 'erp_customer';
UPDATE system_code_rule r SET current_value = COALESCE((SELECT max(right(t.code, r.seq_length)::bigint) FROM erp_supplier t WHERE t.code IS NOT NULL), 0),
  updater = 'script58', update_time = now() WHERE r.rule_key = 'erp_supplier';
UPDATE system_code_rule r SET current_value = COALESCE((SELECT max(right(t.code, r.seq_length)::bigint) FROM erp_warehouse t WHERE t.code IS NOT NULL), 0),
  updater = 'script58', update_time = now() WHERE r.rule_key = 'erp_warehouse';
UPDATE system_code_rule r SET current_value = COALESCE((SELECT max(right(t.code, r.seq_length)::bigint) FROM product_spu t WHERE t.code IS NOT NULL), 0),
  updater = 'script58', update_time = now() WHERE r.rule_key = 'product_spu';

-- ---------------------------------------------------------------------------
-- 4) 自检
-- ---------------------------------------------------------------------------
SELECT '客户 / 物料 / 商品SPU / 供应商 剩余（应全为 0）' AS item,
       (SELECT count(*) FROM erp_customer) || ' / ' || (SELECT count(*) FROM erp_product) || ' / ' ||
       (SELECT count(*) FROM product_spu) || ' / ' || (SELECT count(*) FROM erp_supplier) AS value
UNION ALL SELECT '库存 / 库存批次 / 单据流水号 剩余（应为 0 / 0 / 0）',
       (SELECT count(*) FROM erp_stock) || ' / ' || (SELECT count(*) FROM erp_stock_batch) || ' / ' || (SELECT count(*) FROM bill_no_seq)
UNION ALL SELECT '门店组织节点剩余（应为 0）', (SELECT count(*) FROM system_dept WHERE dept_type = 'STORE')::text
UNION ALL SELECT '门店仓 / 仓库总数（应为 0 / 2）',
       (SELECT count(*) FROM erp_warehouse WHERE store_customer_id IS NOT NULL OR name LIKE '门店虚拟仓%') || ' / ' || (SELECT count(*) FROM erp_warehouse)
UNION ALL SELECT '保留项：菜单 / 字典 / 角色 / 用户 / 单位 / 单据类型',
       (SELECT count(*) FROM system_menu) || ' / ' || (SELECT count(*) FROM system_dict_data) || ' / ' ||
       (SELECT count(*) FROM system_role) || ' / ' || (SELECT count(*) FROM system_users) || ' / ' ||
       (SELECT count(*) FROM erp_product_unit) || ' / ' || (SELECT count(*) FROM bill_type)
UNION ALL SELECT '编码规则当前值',
       (SELECT string_agg(rule_key || '=' || current_value, ' | ' ORDER BY id) FROM system_code_rule WHERE deleted = 0);

COMMIT;