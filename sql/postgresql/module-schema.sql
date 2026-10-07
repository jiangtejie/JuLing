-- ============================================================================
-- 业务模块建表脚本（erp / fms / wms / ai / product / trade / bpm / member）
--
-- 背景：本仓库此前**只有** system + infra 的基线（sql/postgresql/juling-baseline.sql），
--   业务模块的 123 张表只存在于开发机的数据库里 —— 按仓库脚本重建环境会整块缺失。
--   本文件由数据库元数据还原（information_schema + pg_get_indexdef + pg_description），
--   对齐当前库结构，供全新环境重建使用。
--
-- 不含：
--   · act_* / flw_*（Flowable 引擎表）—— 由 flowable.database-schema-update: true 自动创建；
--   · qrtz_*（Quartz 表）—— 见 sql/postgresql/quartz.sql；
--   · system_* / infra_* —— 见 sql/postgresql/juling-baseline.sql。
--
-- 序列：本项目的 id 由 MyBatis-Plus @KeySequence 显式取 nextval 赋值（列上没有 DEFAULT nextval），
--   所以序列必须单独建 —— 少了它们业务表的新增会直接失败。
--
-- 与 sql/local/ 的关系：本文件是**当前库结构快照**，已包含各补丁脚本的加列/加表结果；
--   sql/local/ 下的脚本全部以 IF NOT EXISTS / IF EXISTS 写成，在本文件之后重放是安全的。
--
-- 幂等：可重复执行。
-- ============================================================================

-- 表数：123；序列：122；非主键索引：9；列注释：41

-- ---------------------------------------------------------------------------
-- 序列（@KeySequence 使用；命名约定 <表名>_seq）
-- ---------------------------------------------------------------------------
CREATE SEQUENCE IF NOT EXISTS ai_api_key_seq;
CREATE SEQUENCE IF NOT EXISTS ai_chat_conversation_seq;
CREATE SEQUENCE IF NOT EXISTS ai_chat_message_seq;
CREATE SEQUENCE IF NOT EXISTS ai_chat_role_seq;
CREATE SEQUENCE IF NOT EXISTS ai_image_seq;
CREATE SEQUENCE IF NOT EXISTS ai_knowledge_seq;
CREATE SEQUENCE IF NOT EXISTS ai_knowledge_document_seq;
CREATE SEQUENCE IF NOT EXISTS ai_knowledge_segment_seq;
CREATE SEQUENCE IF NOT EXISTS ai_mind_map_seq;
CREATE SEQUENCE IF NOT EXISTS ai_model_seq;
CREATE SEQUENCE IF NOT EXISTS ai_music_seq;
CREATE SEQUENCE IF NOT EXISTS ai_tool_seq;
CREATE SEQUENCE IF NOT EXISTS ai_write_seq;
CREATE SEQUENCE IF NOT EXISTS bpm_category_seq;
CREATE SEQUENCE IF NOT EXISTS bpm_form_seq;
CREATE SEQUENCE IF NOT EXISTS bpm_oa_leave_seq;
CREATE SEQUENCE IF NOT EXISTS bpm_process_definition_info_seq;
CREATE SEQUENCE IF NOT EXISTS bpm_process_expression_seq;
CREATE SEQUENCE IF NOT EXISTS bpm_process_instance_copy_seq;
CREATE SEQUENCE IF NOT EXISTS bpm_process_listener_seq;
CREATE SEQUENCE IF NOT EXISTS bpm_user_group_seq;
CREATE SEQUENCE IF NOT EXISTS erp_account_seq;
CREATE SEQUENCE IF NOT EXISTS erp_customer_seq;
CREATE SEQUENCE IF NOT EXISTS erp_finance_payment_seq;
CREATE SEQUENCE IF NOT EXISTS erp_finance_payment_item_seq;
CREATE SEQUENCE IF NOT EXISTS erp_finance_receipt_seq;
CREATE SEQUENCE IF NOT EXISTS erp_finance_receipt_item_seq;
CREATE SEQUENCE IF NOT EXISTS erp_product_seq;
CREATE SEQUENCE IF NOT EXISTS erp_product_category_seq;
CREATE SEQUENCE IF NOT EXISTS erp_product_unit_seq;
CREATE SEQUENCE IF NOT EXISTS erp_purchase_in_seq;
CREATE SEQUENCE IF NOT EXISTS erp_purchase_in_items_seq;
CREATE SEQUENCE IF NOT EXISTS erp_purchase_order_seq;
CREATE SEQUENCE IF NOT EXISTS erp_purchase_order_items_seq;
CREATE SEQUENCE IF NOT EXISTS erp_purchase_return_seq;
CREATE SEQUENCE IF NOT EXISTS erp_purchase_return_items_seq;
CREATE SEQUENCE IF NOT EXISTS erp_sale_order_seq;
CREATE SEQUENCE IF NOT EXISTS erp_sale_order_items_seq;
CREATE SEQUENCE IF NOT EXISTS erp_sale_out_seq;
CREATE SEQUENCE IF NOT EXISTS erp_sale_out_items_seq;
CREATE SEQUENCE IF NOT EXISTS erp_sale_return_seq;
CREATE SEQUENCE IF NOT EXISTS erp_sale_return_items_seq;
CREATE SEQUENCE IF NOT EXISTS erp_stock_seq;
CREATE SEQUENCE IF NOT EXISTS erp_stock_check_seq;
CREATE SEQUENCE IF NOT EXISTS erp_stock_check_item_seq;
CREATE SEQUENCE IF NOT EXISTS erp_stock_in_seq;
CREATE SEQUENCE IF NOT EXISTS erp_stock_in_item_seq;
CREATE SEQUENCE IF NOT EXISTS erp_stock_move_seq;
CREATE SEQUENCE IF NOT EXISTS erp_stock_move_item_seq;
CREATE SEQUENCE IF NOT EXISTS erp_stock_out_seq;
CREATE SEQUENCE IF NOT EXISTS erp_stock_out_item_seq;
CREATE SEQUENCE IF NOT EXISTS erp_stock_record_seq;
CREATE SEQUENCE IF NOT EXISTS erp_supplier_seq;
CREATE SEQUENCE IF NOT EXISTS erp_warehouse_seq;
CREATE SEQUENCE IF NOT EXISTS fms_account_set_seq;
CREATE SEQUENCE IF NOT EXISTS fms_account_user_seq;
CREATE SEQUENCE IF NOT EXISTS fms_assist_combination_seq;
CREATE SEQUENCE IF NOT EXISTS fms_auxiliary_item_seq;
CREATE SEQUENCE IF NOT EXISTS fms_auxiliary_type_seq;
CREATE SEQUENCE IF NOT EXISTS fms_balance_sheet_config_seq;
CREATE SEQUENCE IF NOT EXISTS fms_balance_sheet_report_seq;
CREATE SEQUENCE IF NOT EXISTS fms_cash_flow_extend_config_seq;
CREATE SEQUENCE IF NOT EXISTS fms_cash_flow_extend_data_seq;
CREATE SEQUENCE IF NOT EXISTS fms_cash_flow_statement_config_seq;
CREATE SEQUENCE IF NOT EXISTS fms_cash_flow_statement_report_seq;
CREATE SEQUENCE IF NOT EXISTS fms_closing_seq;
CREATE SEQUENCE IF NOT EXISTS fms_closing_period_seq;
CREATE SEQUENCE IF NOT EXISTS fms_closing_template_seq;
CREATE SEQUENCE IF NOT EXISTS fms_closing_voucher_seq;
CREATE SEQUENCE IF NOT EXISTS fms_currency_seq;
CREATE SEQUENCE IF NOT EXISTS fms_digest_seq;
CREATE SEQUENCE IF NOT EXISTS fms_finance_indicator_seq;
CREATE SEQUENCE IF NOT EXISTS fms_finance_parameter_seq;
CREATE SEQUENCE IF NOT EXISTS fms_income_statement_config_seq;
CREATE SEQUENCE IF NOT EXISTS fms_income_statement_report_seq;
CREATE SEQUENCE IF NOT EXISTS fms_initial_balance_seq;
CREATE SEQUENCE IF NOT EXISTS fms_report_template_seq;
CREATE SEQUENCE IF NOT EXISTS fms_subject_seq;
CREATE SEQUENCE IF NOT EXISTS fms_subject_template_seq;
CREATE SEQUENCE IF NOT EXISTS fms_voucher_seq;
CREATE SEQUENCE IF NOT EXISTS fms_voucher_entry_seq;
CREATE SEQUENCE IF NOT EXISTS fms_voucher_template_seq;
CREATE SEQUENCE IF NOT EXISTS fms_voucher_template_category_seq;
CREATE SEQUENCE IF NOT EXISTS fms_voucher_word_seq;
CREATE SEQUENCE IF NOT EXISTS member_user_seq;
CREATE SEQUENCE IF NOT EXISTS product_brand_seq;
CREATE SEQUENCE IF NOT EXISTS product_browse_history_seq;
CREATE SEQUENCE IF NOT EXISTS product_category_seq;
CREATE SEQUENCE IF NOT EXISTS product_favorite_seq;
CREATE SEQUENCE IF NOT EXISTS product_property_seq;
CREATE SEQUENCE IF NOT EXISTS product_property_value_seq;
CREATE SEQUENCE IF NOT EXISTS product_sku_seq;
CREATE SEQUENCE IF NOT EXISTS product_spu_seq;
CREATE SEQUENCE IF NOT EXISTS product_statistics_seq;
CREATE SEQUENCE IF NOT EXISTS trade_after_sale_seq;
CREATE SEQUENCE IF NOT EXISTS trade_after_sale_log_seq;
CREATE SEQUENCE IF NOT EXISTS trade_cart_seq;
CREATE SEQUENCE IF NOT EXISTS trade_config_seq;
CREATE SEQUENCE IF NOT EXISTS trade_delivery_express_seq;
CREATE SEQUENCE IF NOT EXISTS trade_delivery_express_template_seq;
CREATE SEQUENCE IF NOT EXISTS trade_delivery_express_template_charge_seq;
CREATE SEQUENCE IF NOT EXISTS trade_delivery_express_template_free_seq;
CREATE SEQUENCE IF NOT EXISTS trade_order_seq;
CREATE SEQUENCE IF NOT EXISTS trade_order_item_seq;
CREATE SEQUENCE IF NOT EXISTS trade_order_log_seq;
CREATE SEQUENCE IF NOT EXISTS trade_statistics_seq;
CREATE SEQUENCE IF NOT EXISTS wms_check_order_seq;
CREATE SEQUENCE IF NOT EXISTS wms_check_order_detail_seq;
CREATE SEQUENCE IF NOT EXISTS wms_inventory_seq;
CREATE SEQUENCE IF NOT EXISTS wms_inventory_history_seq;
CREATE SEQUENCE IF NOT EXISTS wms_item_seq;
CREATE SEQUENCE IF NOT EXISTS wms_item_brand_seq;
CREATE SEQUENCE IF NOT EXISTS wms_item_category_seq;
CREATE SEQUENCE IF NOT EXISTS wms_item_sku_seq;
CREATE SEQUENCE IF NOT EXISTS wms_merchant_seq;
CREATE SEQUENCE IF NOT EXISTS wms_movement_order_seq;
CREATE SEQUENCE IF NOT EXISTS wms_movement_order_detail_seq;
CREATE SEQUENCE IF NOT EXISTS wms_receipt_order_seq;
CREATE SEQUENCE IF NOT EXISTS wms_receipt_order_detail_seq;
CREATE SEQUENCE IF NOT EXISTS wms_shipment_order_seq;
CREATE SEQUENCE IF NOT EXISTS wms_shipment_order_detail_seq;
CREATE SEQUENCE IF NOT EXISTS wms_warehouse_seq;

-- ---------------------------------------------------------------------------
-- 建表
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS ai_api_key (
    id                           bigint NOT NULL,
    name                         text,
    api_key                      text,
    platform                     text,
    url                          text,
    status                       integer,
    tenant_id                    bigint DEFAULT 0 NOT NULL,
    creator                      varchar(64) DEFAULT ''::character varying,
    create_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater                      varchar(64) DEFAULT ''::character varying,
    update_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted                      smallint DEFAULT 0 NOT NULL,
    CONSTRAINT ai_api_key_pkey PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS ai_chat_conversation (
    id                           bigint NOT NULL,
    user_id                      bigint,
    title                        text,
    pinned                       boolean,
    pinned_time                  timestamp,
    role_id                      bigint,
    model_id                     bigint,
    model                        text,
    system_message               text,
    temperature                  double precision,
    max_tokens                   integer,
    max_contexts                 integer,
    tenant_id                    bigint DEFAULT 0 NOT NULL,
    creator                      varchar(64) DEFAULT ''::character varying,
    create_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater                      varchar(64) DEFAULT ''::character varying,
    update_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted                      smallint DEFAULT 0 NOT NULL,
    CONSTRAINT ai_chat_conversation_pkey PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS ai_chat_message (
    id                           bigint NOT NULL,
    conversation_id              bigint,
    reply_id                     bigint,
    type                         text,
    user_id                      bigint,
    role_id                      bigint,
    model                        text,
    model_id                     bigint,
    content                      text,
    reasoning_content            text,
    use_context                  boolean,
    segment_ids                  text,
    web_search_pages             text,
    attachment_urls              text,
    tenant_id                    bigint DEFAULT 0 NOT NULL,
    creator                      varchar(64) DEFAULT ''::character varying,
    create_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater                      varchar(64) DEFAULT ''::character varying,
    update_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted                      smallint DEFAULT 0 NOT NULL,
    CONSTRAINT ai_chat_message_pkey PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS ai_chat_role (
    id                           bigint NOT NULL,
    name                         text,
    avatar                       text,
    category                     text,
    description                  text,
    system_message               text,
    user_id                      bigint,
    model_id                     bigint,
    knowledge_ids                text,
    tool_ids                     text,
    mcp_client_names             text,
    public_status                boolean,
    sort                         integer,
    status                       integer,
    tenant_id                    bigint DEFAULT 0 NOT NULL,
    creator                      varchar(64) DEFAULT ''::character varying,
    create_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater                      varchar(64) DEFAULT ''::character varying,
    update_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted                      smallint DEFAULT 0 NOT NULL,
    CONSTRAINT ai_chat_role_pkey PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS ai_image (
    id                           bigint NOT NULL,
    user_id                      bigint,
    prompt                       text,
    platform                     text,
    model_id                     bigint,
    model                        text,
    width                        integer,
    height                       integer,
    status                       integer,
    finish_time                  timestamp,
    error_message                text,
    pic_url                      text,
    public_status                boolean,
    options                      text,
    buttons                      text,
    task_id                      text,
    tenant_id                    bigint DEFAULT 0 NOT NULL,
    creator                      varchar(64) DEFAULT ''::character varying,
    create_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater                      varchar(64) DEFAULT ''::character varying,
    update_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted                      smallint DEFAULT 0 NOT NULL,
    CONSTRAINT ai_image_pkey PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS ai_knowledge (
    id                           bigint NOT NULL,
    name                         text,
    description                  text,
    embedding_model_id           bigint,
    embedding_model              text,
    top_k                        integer,
    similarity_threshold         double precision,
    status                       integer,
    tenant_id                    bigint DEFAULT 0 NOT NULL,
    creator                      varchar(64) DEFAULT ''::character varying,
    create_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater                      varchar(64) DEFAULT ''::character varying,
    update_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted                      smallint DEFAULT 0 NOT NULL,
    CONSTRAINT ai_knowledge_pkey PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS ai_knowledge_document (
    id                           bigint NOT NULL,
    knowledge_id                 bigint,
    name                         text,
    url                          text,
    content                      text,
    content_length               integer,
    tokens                       integer,
    segment_max_tokens           integer,
    retrieval_count              integer,
    status                       integer,
    tenant_id                    bigint DEFAULT 0 NOT NULL,
    creator                      varchar(64) DEFAULT ''::character varying,
    create_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater                      varchar(64) DEFAULT ''::character varying,
    update_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted                      smallint DEFAULT 0 NOT NULL,
    CONSTRAINT ai_knowledge_document_pkey PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS ai_knowledge_segment (
    id                           bigint NOT NULL,
    knowledge_id                 bigint,
    document_id                  bigint,
    content                      text,
    content_length               integer,
    vector_id                    text,
    tokens                       integer,
    retrieval_count              integer,
    status                       integer,
    tenant_id                    bigint DEFAULT 0 NOT NULL,
    creator                      varchar(64) DEFAULT ''::character varying,
    create_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater                      varchar(64) DEFAULT ''::character varying,
    update_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted                      smallint DEFAULT 0 NOT NULL,
    CONSTRAINT ai_knowledge_segment_pkey PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS ai_mind_map (
    id                           bigint NOT NULL,
    user_id                      bigint,
    platform                     text,
    model_id                     bigint,
    model                        text,
    prompt                       text,
    generated_content            text,
    error_message                text,
    tenant_id                    bigint DEFAULT 0 NOT NULL,
    creator                      varchar(64) DEFAULT ''::character varying,
    create_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater                      varchar(64) DEFAULT ''::character varying,
    update_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted                      smallint DEFAULT 0 NOT NULL,
    CONSTRAINT ai_mind_map_pkey PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS ai_model (
    id                           bigint NOT NULL,
    key_id                       bigint,
    name                         text,
    model                        text,
    platform                     text,
    type                         integer,
    sort                         integer,
    status                       integer,
    temperature                  double precision,
    max_tokens                   integer,
    max_contexts                 integer,
    tenant_id                    bigint DEFAULT 0 NOT NULL,
    creator                      varchar(64) DEFAULT ''::character varying,
    create_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater                      varchar(64) DEFAULT ''::character varying,
    update_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted                      smallint DEFAULT 0 NOT NULL,
    CONSTRAINT ai_model_pkey PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS ai_music (
    id                           bigint NOT NULL,
    user_id                      bigint,
    title                        text,
    lyric                        text,
    image_url                    text,
    audio_url                    text,
    video_url                    text,
    status                       integer,
    generate_mode                integer,
    description                  text,
    platform                     text,
    model                        text,
    tags                         text,
    duration                     double precision,
    public_status                boolean,
    task_id                      text,
    error_message                text,
    tenant_id                    bigint DEFAULT 0 NOT NULL,
    creator                      varchar(64) DEFAULT ''::character varying,
    create_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater                      varchar(64) DEFAULT ''::character varying,
    update_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted                      smallint DEFAULT 0 NOT NULL,
    CONSTRAINT ai_music_pkey PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS ai_tool (
    id                           bigint NOT NULL,
    name                         text,
    description                  text,
    status                       integer,
    tenant_id                    bigint DEFAULT 0 NOT NULL,
    creator                      varchar(64) DEFAULT ''::character varying,
    create_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater                      varchar(64) DEFAULT ''::character varying,
    update_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted                      smallint DEFAULT 0 NOT NULL,
    CONSTRAINT ai_tool_pkey PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS ai_workflow (
    id                           bigint NOT NULL,
    name                         text,
    code                         text,
    graph                        text,
    remark                       text,
    status                       integer,
    tenant_id                    bigint DEFAULT 0 NOT NULL,
    creator                      varchar(64) DEFAULT ''::character varying,
    create_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater                      varchar(64) DEFAULT ''::character varying,
    update_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted                      smallint DEFAULT 0 NOT NULL,
    CONSTRAINT ai_workflow_pkey PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS ai_write (
    id                           bigint NOT NULL,
    user_id                      bigint,
    type                         integer,
    platform                     text,
    model_id                     bigint,
    model                        text,
    prompt                       text,
    generated_content            text,
    original_content             text,
    length                       integer,
    format                       integer,
    tone                         integer,
    language                     integer,
    error_message                text,
    tenant_id                    bigint DEFAULT 0 NOT NULL,
    creator                      varchar(64) DEFAULT ''::character varying,
    create_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater                      varchar(64) DEFAULT ''::character varying,
    update_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted                      smallint DEFAULT 0 NOT NULL,
    CONSTRAINT ai_write_pkey PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS bpm_category (
    id                           bigint NOT NULL,
    name                         text,
    code                         text,
    description                  text,
    status                       integer,
    sort                         integer,
    tenant_id                    bigint DEFAULT 0 NOT NULL,
    creator                      varchar(64) DEFAULT ''::character varying,
    create_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater                      varchar(64) DEFAULT ''::character varying,
    update_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted                      smallint DEFAULT 0 NOT NULL,
    CONSTRAINT bpm_category_pkey PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS bpm_form (
    id                           bigint NOT NULL,
    name                         text,
    status                       integer,
    conf                         text,
    fields                       text,
    remark                       text,
    tenant_id                    bigint DEFAULT 0 NOT NULL,
    creator                      varchar(64) DEFAULT ''::character varying,
    create_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater                      varchar(64) DEFAULT ''::character varying,
    update_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted                      smallint DEFAULT 0 NOT NULL,
    CONSTRAINT bpm_form_pkey PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS bpm_oa_leave (
    id                           bigint NOT NULL,
    user_id                      bigint,
    type                         integer,
    reason                       text,
    start_time                   timestamp,
    end_time                     timestamp,
    day                          bigint,
    status                       integer,
    process_instance_id          text,
    tenant_id                    bigint DEFAULT 0 NOT NULL,
    creator                      varchar(64) DEFAULT ''::character varying,
    create_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater                      varchar(64) DEFAULT ''::character varying,
    update_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted                      smallint DEFAULT 0 NOT NULL,
    CONSTRAINT bpm_oa_leave_pkey PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS bpm_process_definition_info (
    id                           bigint NOT NULL,
    process_definition_id        text,
    model_id                     text,
    model_type                   integer,
    category                     text,
    icon                         text,
    description                  text,
    form_type                    integer,
    form_id                      bigint,
    form_conf                    text,
    form_fields                  text,
    form_custom_create_path      text,
    form_custom_view_path        text,
    simple_model                 text,
    visible                      boolean,
    sort                         bigint,
    start_user_ids               text,
    start_dept_ids               text,
    manager_user_ids             text,
    allow_cancel_running_process boolean,
    allow_withdraw_task          boolean,
    process_id_rule              text,
    auto_approval_type           integer,
    title_setting                text,
    summary_setting              text,
    process_before_trigger_setting text,
    process_after_trigger_setting text,
    task_before_trigger_setting  text,
    task_after_trigger_setting   text,
    print_template_setting       text,
    tenant_id                    bigint DEFAULT 0 NOT NULL,
    creator                      varchar(64) DEFAULT ''::character varying,
    create_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater                      varchar(64) DEFAULT ''::character varying,
    update_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted                      smallint DEFAULT 0 NOT NULL,
    CONSTRAINT bpm_process_definition_info_pkey PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS bpm_process_expression (
    id                           bigint NOT NULL,
    name                         text,
    status                       integer,
    expression                   text,
    tenant_id                    bigint DEFAULT 0 NOT NULL,
    creator                      varchar(64) DEFAULT ''::character varying,
    create_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater                      varchar(64) DEFAULT ''::character varying,
    update_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted                      smallint DEFAULT 0 NOT NULL,
    CONSTRAINT bpm_process_expression_pkey PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS bpm_process_instance_copy (
    id                           bigint NOT NULL,
    start_user_id                bigint,
    process_instance_name        text,
    process_instance_id          text,
    process_definition_id        text,
    category                     text,
    activity_id                  text,
    activity_name                text,
    task_id                      text,
    user_id                      bigint,
    reason                       text,
    tenant_id                    bigint DEFAULT 0 NOT NULL,
    creator                      varchar(64) DEFAULT ''::character varying,
    create_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater                      varchar(64) DEFAULT ''::character varying,
    update_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted                      smallint DEFAULT 0 NOT NULL,
    CONSTRAINT bpm_process_instance_copy_pkey PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS bpm_process_listener (
    id                           bigint NOT NULL,
    name                         text,
    status                       integer,
    type                         text,
    event                        text,
    value_type                   text,
    value                        text,
    tenant_id                    bigint DEFAULT 0 NOT NULL,
    creator                      varchar(64) DEFAULT ''::character varying,
    create_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater                      varchar(64) DEFAULT ''::character varying,
    update_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted                      smallint DEFAULT 0 NOT NULL,
    CONSTRAINT bpm_process_listener_pkey PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS bpm_user_group (
    id                           bigint NOT NULL,
    name                         text,
    description                  text,
    status                       integer,
    user_ids                     text,
    tenant_id                    bigint DEFAULT 0 NOT NULL,
    creator                      varchar(64) DEFAULT ''::character varying,
    create_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater                      varchar(64) DEFAULT ''::character varying,
    update_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted                      smallint DEFAULT 0 NOT NULL,
    CONSTRAINT bpm_user_group_pkey PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS erp_account (
    id                           bigint NOT NULL,
    name                         text,
    no                           text,
    remark                       text,
    status                       integer,
    sort                         integer,
    default_status               boolean,
    tenant_id                    bigint DEFAULT 0 NOT NULL,
    creator                      varchar(64) DEFAULT ''::character varying,
    create_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater                      varchar(64) DEFAULT ''::character varying,
    update_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted                      smallint DEFAULT 0 NOT NULL,
    CONSTRAINT erp_account_pkey PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS erp_customer (
    id                           bigint NOT NULL,
    name                         text,
    contact                      text,
    mobile                       text,
    telephone                    text,
    email                        text,
    fax                          text,
    remark                       text,
    status                       integer,
    sort                         integer,
    tax_no                       text,
    tax_percent                  numeric(24,6),
    bank_name                    text,
    bank_account                 text,
    bank_address                 text,
    tenant_id                    bigint DEFAULT 0 NOT NULL,
    creator                      varchar(64) DEFAULT ''::character varying,
    create_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater                      varchar(64) DEFAULT ''::character varying,
    update_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted                      smallint DEFAULT 0 NOT NULL,
    dept_id                      bigint,
    parent_customer_id           bigint,
    store_type                   varchar(20),
    settlement_mode              varchar(20),
    credit_days                  integer,
    credit_limit                 numeric(24,6),
    CONSTRAINT erp_customer_pkey PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS erp_finance_payment (
    id                           bigint NOT NULL,
    no                           text,
    status                       integer,
    payment_time                 timestamp,
    finance_user_id              bigint,
    supplier_id                  bigint,
    account_id                   bigint,
    total_price                  numeric(24,6),
    discount_price               numeric(24,6),
    payment_price                numeric(24,6),
    remark                       text,
    tenant_id                    bigint DEFAULT 0 NOT NULL,
    creator                      varchar(64) DEFAULT ''::character varying,
    create_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater                      varchar(64) DEFAULT ''::character varying,
    update_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted                      smallint DEFAULT 0 NOT NULL,
    CONSTRAINT erp_finance_payment_pkey PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS erp_finance_payment_item (
    id                           bigint NOT NULL,
    payment_id                   bigint,
    biz_type                     integer,
    biz_id                       bigint,
    biz_no                       text,
    total_price                  numeric(24,6),
    paid_price                   numeric(24,6),
    payment_price                numeric(24,6),
    remark                       text,
    tenant_id                    bigint DEFAULT 0 NOT NULL,
    creator                      varchar(64) DEFAULT ''::character varying,
    create_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater                      varchar(64) DEFAULT ''::character varying,
    update_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted                      smallint DEFAULT 0 NOT NULL,
    CONSTRAINT erp_finance_payment_item_pkey PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS erp_finance_receipt (
    id                           bigint NOT NULL,
    no                           text,
    status                       integer,
    receipt_time                 timestamp,
    finance_user_id              bigint,
    customer_id                  bigint,
    account_id                   bigint,
    total_price                  numeric(24,6),
    discount_price               numeric(24,6),
    receipt_price                numeric(24,6),
    remark                       text,
    tenant_id                    bigint DEFAULT 0 NOT NULL,
    creator                      varchar(64) DEFAULT ''::character varying,
    create_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater                      varchar(64) DEFAULT ''::character varying,
    update_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted                      smallint DEFAULT 0 NOT NULL,
    CONSTRAINT erp_finance_receipt_pkey PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS erp_finance_receipt_item (
    id                           bigint NOT NULL,
    receipt_id                   bigint,
    biz_type                     integer,
    biz_id                       bigint,
    biz_no                       text,
    total_price                  numeric(24,6),
    receipted_price              numeric(24,6),
    receipt_price                numeric(24,6),
    remark                       text,
    tenant_id                    bigint DEFAULT 0 NOT NULL,
    creator                      varchar(64) DEFAULT ''::character varying,
    create_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater                      varchar(64) DEFAULT ''::character varying,
    update_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted                      smallint DEFAULT 0 NOT NULL,
    CONSTRAINT erp_finance_receipt_item_pkey PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS erp_product (
    id                           bigint NOT NULL,
    name                         text,
    bar_code                     text,
    category_id                  bigint,
    unit_id                      bigint,
    status                       integer,
    standard                     text,
    remark                       text,
    expiry_day                   integer,
    weight                       numeric(24,6),
    purchase_price               numeric(24,6),
    sale_price                   numeric(24,6),
    min_price                    numeric(24,6),
    tenant_id                    bigint DEFAULT 0 NOT NULL,
    creator                      varchar(64) DEFAULT ''::character varying,
    create_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater                      varchar(64) DEFAULT ''::character varying,
    update_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted                      smallint DEFAULT 0 NOT NULL,
    allow_central                boolean DEFAULT true NOT NULL,
    allow_direct                 boolean DEFAULT true NOT NULL,
    CONSTRAINT erp_product_pkey PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS erp_product_category (
    id                           bigint NOT NULL,
    parent_id                    bigint,
    name                         text,
    code                         text,
    sort                         integer,
    status                       integer,
    tenant_id                    bigint DEFAULT 0 NOT NULL,
    creator                      varchar(64) DEFAULT ''::character varying,
    create_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater                      varchar(64) DEFAULT ''::character varying,
    update_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted                      smallint DEFAULT 0 NOT NULL,
    CONSTRAINT erp_product_category_pkey PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS erp_product_unit (
    id                           bigint NOT NULL,
    name                         text,
    status                       integer,
    tenant_id                    bigint DEFAULT 0 NOT NULL,
    creator                      varchar(64) DEFAULT ''::character varying,
    create_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater                      varchar(64) DEFAULT ''::character varying,
    update_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted                      smallint DEFAULT 0 NOT NULL,
    CONSTRAINT erp_product_unit_pkey PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS erp_purchase_in (
    id                           bigint NOT NULL,
    no                           text,
    status                       integer,
    supplier_id                  bigint,
    account_id                   bigint,
    in_time                      timestamp,
    order_id                     bigint,
    order_no                     text,
    total_count                  numeric(24,6),
    total_price                  numeric(24,6),
    payment_price                numeric(24,6) DEFAULT 0,
    total_product_price          numeric(24,6),
    total_tax_price              numeric(24,6),
    discount_percent             numeric(24,6),
    discount_price               numeric(24,6),
    other_price                  numeric(24,6),
    file_url                     text,
    remark                       text,
    tenant_id                    bigint DEFAULT 0 NOT NULL,
    creator                      varchar(64) DEFAULT ''::character varying,
    create_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater                      varchar(64) DEFAULT ''::character varying,
    update_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted                      smallint DEFAULT 0 NOT NULL,
    CONSTRAINT erp_purchase_in_pkey PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS erp_purchase_in_items (
    id                           bigint NOT NULL,
    in_id                        bigint,
    order_item_id                bigint,
    warehouse_id                 bigint,
    product_id                   bigint,
    product_unit_id              bigint,
    product_price                numeric(24,6),
    count                        numeric(24,6),
    total_price                  numeric(24,6),
    tax_percent                  numeric(24,6),
    tax_price                    numeric(24,6),
    remark                       text,
    tenant_id                    bigint DEFAULT 0 NOT NULL,
    creator                      varchar(64) DEFAULT ''::character varying,
    create_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater                      varchar(64) DEFAULT ''::character varying,
    update_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted                      smallint DEFAULT 0 NOT NULL,
    batch_no                     varchar(64),
    production_date              date,
    expiry_date                  date,
    CONSTRAINT erp_purchase_in_items_pkey PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS erp_purchase_order (
    id                           bigint NOT NULL,
    no                           text,
    status                       integer,
    supplier_id                  bigint,
    account_id                   bigint,
    order_time                   timestamp,
    total_count                  numeric(24,6),
    total_price                  numeric(24,6),
    total_product_price          numeric(24,6),
    total_tax_price              numeric(24,6),
    discount_percent             numeric(24,6),
    discount_price               numeric(24,6),
    deposit_price                numeric(24,6),
    file_url                     text,
    remark                       text,
    in_count                     numeric(24,6) DEFAULT 0,
    return_count                 numeric(24,6) DEFAULT 0,
    tenant_id                    bigint DEFAULT 0 NOT NULL,
    creator                      varchar(64) DEFAULT ''::character varying,
    create_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater                      varchar(64) DEFAULT ''::character varying,
    update_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted                      smallint DEFAULT 0 NOT NULL,
    CONSTRAINT erp_purchase_order_pkey PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS erp_purchase_order_items (
    id                           bigint NOT NULL,
    order_id                     bigint,
    product_id                   bigint,
    product_unit_id              bigint,
    product_price                numeric(24,6),
    count                        numeric(24,6),
    total_price                  numeric(24,6),
    tax_percent                  numeric(24,6),
    tax_price                    numeric(24,6),
    remark                       text,
    in_count                     numeric(24,6) DEFAULT 0,
    return_count                 numeric(24,6) DEFAULT 0,
    tenant_id                    bigint DEFAULT 0 NOT NULL,
    creator                      varchar(64) DEFAULT ''::character varying,
    create_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater                      varchar(64) DEFAULT ''::character varying,
    update_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted                      smallint DEFAULT 0 NOT NULL,
    CONSTRAINT erp_purchase_order_items_pkey PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS erp_purchase_return (
    id                           bigint NOT NULL,
    no                           text,
    status                       integer,
    supplier_id                  bigint,
    account_id                   bigint,
    return_time                  timestamp,
    order_id                     bigint,
    order_no                     text,
    total_count                  numeric(24,6),
    total_price                  numeric(24,6),
    refund_price                 numeric(24,6) DEFAULT 0,
    total_product_price          numeric(24,6),
    total_tax_price              numeric(24,6),
    discount_percent             numeric(24,6),
    discount_price               numeric(24,6),
    other_price                  numeric(24,6),
    file_url                     text,
    remark                       text,
    tenant_id                    bigint DEFAULT 0 NOT NULL,
    creator                      varchar(64) DEFAULT ''::character varying,
    create_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater                      varchar(64) DEFAULT ''::character varying,
    update_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted                      smallint DEFAULT 0 NOT NULL,
    CONSTRAINT erp_purchase_return_pkey PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS erp_purchase_return_items (
    id                           bigint NOT NULL,
    return_id                    bigint,
    order_item_id                bigint,
    warehouse_id                 bigint,
    product_id                   bigint,
    product_unit_id              bigint,
    product_price                numeric(24,6),
    count                        numeric(24,6),
    total_price                  numeric(24,6),
    tax_percent                  numeric(24,6),
    tax_price                    numeric(24,6),
    remark                       text,
    tenant_id                    bigint DEFAULT 0 NOT NULL,
    creator                      varchar(64) DEFAULT ''::character varying,
    create_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater                      varchar(64) DEFAULT ''::character varying,
    update_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted                      smallint DEFAULT 0 NOT NULL,
    CONSTRAINT erp_purchase_return_items_pkey PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS erp_sale_order (
    id                           bigint NOT NULL,
    no                           text,
    status                       integer,
    customer_id                  bigint,
    account_id                   bigint,
    sale_user_id                 bigint,
    order_time                   timestamp,
    total_count                  numeric(24,6),
    total_price                  numeric(24,6),
    total_product_price          numeric(24,6),
    total_tax_price              numeric(24,6),
    discount_percent             numeric(24,6),
    discount_price               numeric(24,6),
    deposit_price                numeric(24,6),
    file_url                     text,
    remark                       text,
    out_count                    numeric(24,6) DEFAULT 0,
    return_count                 numeric(24,6) DEFAULT 0,
    tenant_id                    bigint DEFAULT 0 NOT NULL,
    creator                      varchar(64) DEFAULT ''::character varying,
    create_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater                      varchar(64) DEFAULT ''::character varying,
    update_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted                      smallint DEFAULT 0 NOT NULL,
    CONSTRAINT erp_sale_order_pkey PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS erp_sale_order_items (
    id                           bigint NOT NULL,
    order_id                     bigint,
    product_id                   bigint,
    product_unit_id              bigint,
    product_price                numeric(24,6),
    count                        numeric(24,6),
    total_price                  numeric(24,6),
    tax_percent                  numeric(24,6),
    tax_price                    numeric(24,6),
    remark                       text,
    out_count                    numeric(24,6) DEFAULT 0,
    return_count                 numeric(24,6) DEFAULT 0,
    tenant_id                    bigint DEFAULT 0 NOT NULL,
    creator                      varchar(64) DEFAULT ''::character varying,
    create_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater                      varchar(64) DEFAULT ''::character varying,
    update_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted                      smallint DEFAULT 0 NOT NULL,
    CONSTRAINT erp_sale_order_items_pkey PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS erp_sale_out (
    id                           bigint NOT NULL,
    no                           text,
    status                       integer,
    customer_id                  bigint,
    account_id                   bigint,
    sale_user_id                 bigint,
    out_time                     timestamp,
    order_id                     bigint,
    order_no                     text,
    total_count                  numeric(24,6),
    total_price                  numeric(24,6),
    receipt_price                numeric(24,6) DEFAULT 0,
    total_product_price          numeric(24,6),
    total_tax_price              numeric(24,6),
    discount_percent             numeric(24,6),
    discount_price               numeric(24,6),
    other_price                  numeric(24,6),
    file_url                     text,
    remark                       text,
    tenant_id                    bigint DEFAULT 0 NOT NULL,
    creator                      varchar(64) DEFAULT ''::character varying,
    create_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater                      varchar(64) DEFAULT ''::character varying,
    update_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted                      smallint DEFAULT 0 NOT NULL,
    CONSTRAINT erp_sale_out_pkey PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS erp_sale_out_items (
    id                           bigint NOT NULL,
    out_id                       bigint,
    order_item_id                bigint,
    warehouse_id                 bigint,
    product_id                   bigint,
    product_unit_id              bigint,
    product_price                numeric(24,6),
    count                        numeric(24,6),
    total_price                  numeric(24,6),
    tax_percent                  numeric(24,6),
    tax_price                    numeric(24,6),
    remark                       text,
    tenant_id                    bigint DEFAULT 0 NOT NULL,
    creator                      varchar(64) DEFAULT ''::character varying,
    create_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater                      varchar(64) DEFAULT ''::character varying,
    update_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted                      smallint DEFAULT 0 NOT NULL,
    source_item_id               bigint,
    CONSTRAINT erp_sale_out_items_pkey PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS erp_sale_return (
    id                           bigint NOT NULL,
    no                           text,
    status                       integer,
    customer_id                  bigint,
    account_id                   bigint,
    sale_user_id                 bigint,
    return_time                  timestamp,
    order_id                     bigint,
    order_no                     text,
    total_count                  numeric(24,6),
    total_price                  numeric(24,6),
    refund_price                 numeric(24,6) DEFAULT 0,
    total_product_price          numeric(24,6),
    total_tax_price              numeric(24,6),
    discount_percent             numeric(24,6),
    discount_price               numeric(24,6),
    other_price                  numeric(24,6),
    file_url                     text,
    remark                       text,
    tenant_id                    bigint DEFAULT 0 NOT NULL,
    creator                      varchar(64) DEFAULT ''::character varying,
    create_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater                      varchar(64) DEFAULT ''::character varying,
    update_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted                      smallint DEFAULT 0 NOT NULL,
    CONSTRAINT erp_sale_return_pkey PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS erp_sale_return_items (
    id                           bigint NOT NULL,
    return_id                    bigint,
    order_item_id                bigint,
    warehouse_id                 bigint,
    product_id                   bigint,
    product_unit_id              bigint,
    product_price                numeric(24,6),
    count                        numeric(24,6),
    total_price                  numeric(24,6),
    tax_percent                  numeric(24,6),
    tax_price                    numeric(24,6),
    remark                       text,
    tenant_id                    bigint DEFAULT 0 NOT NULL,
    creator                      varchar(64) DEFAULT ''::character varying,
    create_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater                      varchar(64) DEFAULT ''::character varying,
    update_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted                      smallint DEFAULT 0 NOT NULL,
    CONSTRAINT erp_sale_return_items_pkey PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS erp_stock (
    id                           bigint NOT NULL,
    product_id                   bigint,
    warehouse_id                 bigint,
    count                        numeric(24,6),
    tenant_id                    bigint DEFAULT 0 NOT NULL,
    creator                      varchar(64) DEFAULT ''::character varying,
    create_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater                      varchar(64) DEFAULT ''::character varying,
    update_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted                      smallint DEFAULT 0 NOT NULL,
    CONSTRAINT erp_stock_pkey PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS erp_stock_check (
    id                           bigint NOT NULL,
    no                           text,
    check_time                   timestamp,
    total_count                  numeric(24,6),
    total_price                  numeric(24,6),
    status                       integer,
    remark                       text,
    file_url                     text,
    tenant_id                    bigint DEFAULT 0 NOT NULL,
    creator                      varchar(64) DEFAULT ''::character varying,
    create_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater                      varchar(64) DEFAULT ''::character varying,
    update_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted                      smallint DEFAULT 0 NOT NULL,
    CONSTRAINT erp_stock_check_pkey PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS erp_stock_check_item (
    id                           bigint NOT NULL,
    check_id                     bigint,
    warehouse_id                 bigint,
    product_id                   bigint,
    product_unit_id              bigint,
    product_price                numeric(24,6),
    stock_count                  numeric(24,6),
    actual_count                 numeric(24,6),
    count                        numeric(24,6),
    total_price                  numeric(24,6),
    remark                       text,
    tenant_id                    bigint DEFAULT 0 NOT NULL,
    creator                      varchar(64) DEFAULT ''::character varying,
    create_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater                      varchar(64) DEFAULT ''::character varying,
    update_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted                      smallint DEFAULT 0 NOT NULL,
    CONSTRAINT erp_stock_check_item_pkey PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS erp_stock_in (
    id                           bigint NOT NULL,
    no                           text,
    supplier_id                  bigint,
    in_time                      timestamp,
    total_count                  numeric(24,6),
    total_price                  numeric(24,6),
    status                       integer,
    remark                       text,
    file_url                     text,
    tenant_id                    bigint DEFAULT 0 NOT NULL,
    creator                      varchar(64) DEFAULT ''::character varying,
    create_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater                      varchar(64) DEFAULT ''::character varying,
    update_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted                      smallint DEFAULT 0 NOT NULL,
    CONSTRAINT erp_stock_in_pkey PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS erp_stock_in_item (
    id                           bigint NOT NULL,
    in_id                        bigint,
    warehouse_id                 bigint,
    product_id                   bigint,
    product_unit_id              bigint,
    product_price                numeric(24,6),
    count                        numeric(24,6),
    total_price                  numeric(24,6),
    remark                       text,
    tenant_id                    bigint DEFAULT 0 NOT NULL,
    creator                      varchar(64) DEFAULT ''::character varying,
    create_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater                      varchar(64) DEFAULT ''::character varying,
    update_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted                      smallint DEFAULT 0 NOT NULL,
    batch_no                     varchar(64),
    production_date              date,
    expiry_date                  date,
    CONSTRAINT erp_stock_in_item_pkey PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS erp_stock_move (
    id                           bigint NOT NULL,
    no                           text,
    move_time                    timestamp,
    total_count                  numeric(24,6),
    total_price                  numeric(24,6),
    status                       integer,
    remark                       text,
    file_url                     text,
    tenant_id                    bigint DEFAULT 0 NOT NULL,
    creator                      varchar(64) DEFAULT ''::character varying,
    create_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater                      varchar(64) DEFAULT ''::character varying,
    update_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted                      smallint DEFAULT 0 NOT NULL,
    CONSTRAINT erp_stock_move_pkey PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS erp_stock_move_item (
    id                           bigint NOT NULL,
    move_id                      bigint,
    from_warehouse_id            bigint,
    to_warehouse_id              bigint,
    product_id                   bigint,
    product_unit_id              bigint,
    product_price                numeric(24,6),
    count                        numeric(24,6),
    total_price                  numeric(24,6),
    remark                       text,
    tenant_id                    bigint DEFAULT 0 NOT NULL,
    creator                      varchar(64) DEFAULT ''::character varying,
    create_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater                      varchar(64) DEFAULT ''::character varying,
    update_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted                      smallint DEFAULT 0 NOT NULL,
    CONSTRAINT erp_stock_move_item_pkey PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS erp_stock_out (
    id                           bigint NOT NULL,
    no                           text,
    customer_id                  bigint,
    out_time                     timestamp,
    total_count                  numeric(24,6),
    total_price                  numeric(24,6),
    status                       integer,
    remark                       text,
    file_url                     text,
    tenant_id                    bigint DEFAULT 0 NOT NULL,
    creator                      varchar(64) DEFAULT ''::character varying,
    create_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater                      varchar(64) DEFAULT ''::character varying,
    update_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted                      smallint DEFAULT 0 NOT NULL,
    CONSTRAINT erp_stock_out_pkey PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS erp_stock_out_item (
    id                           bigint NOT NULL,
    out_id                       bigint,
    warehouse_id                 bigint,
    product_id                   bigint,
    product_unit_id              bigint,
    product_price                numeric(24,6),
    count                        numeric(24,6),
    total_price                  numeric(24,6),
    remark                       text,
    tenant_id                    bigint DEFAULT 0 NOT NULL,
    creator                      varchar(64) DEFAULT ''::character varying,
    create_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater                      varchar(64) DEFAULT ''::character varying,
    update_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted                      smallint DEFAULT 0 NOT NULL,
    CONSTRAINT erp_stock_out_item_pkey PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS erp_stock_record (
    id                           bigint NOT NULL,
    product_id                   bigint,
    warehouse_id                 bigint,
    count                        numeric(24,6),
    total_count                  numeric(24,6),
    biz_type                     integer,
    biz_id                       bigint,
    biz_item_id                  bigint,
    biz_no                       text,
    tenant_id                    bigint DEFAULT 0 NOT NULL,
    creator                      varchar(64) DEFAULT ''::character varying,
    create_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater                      varchar(64) DEFAULT ''::character varying,
    update_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted                      smallint DEFAULT 0 NOT NULL,
    batch_no                     varchar(64),
    stock_state                  varchar(16),
    unit_cost                    numeric(24,6),
    total_cost                   numeric(24,6),
    sku_id                       bigint,
    CONSTRAINT erp_stock_record_pkey PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS erp_supplier (
    id                           bigint NOT NULL,
    name                         text,
    contact                      text,
    mobile                       text,
    telephone                    text,
    email                        text,
    fax                          text,
    remark                       text,
    status                       integer,
    sort                         integer,
    tax_no                       text,
    tax_percent                  numeric(24,6),
    bank_name                    text,
    bank_account                 text,
    bank_address                 text,
    tenant_id                    bigint DEFAULT 0 NOT NULL,
    creator                      varchar(64) DEFAULT ''::character varying,
    create_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater                      varchar(64) DEFAULT ''::character varying,
    update_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted                      smallint DEFAULT 0 NOT NULL,
    CONSTRAINT erp_supplier_pkey PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS erp_warehouse (
    id                           bigint NOT NULL,
    name                         text,
    address                      text,
    sort                         bigint,
    remark                       text,
    principal                    text,
    warehouse_price              numeric(24,6),
    truckage_price               numeric(24,6),
    status                       integer,
    default_status               boolean,
    tenant_id                    bigint DEFAULT 0 NOT NULL,
    creator                      varchar(64) DEFAULT ''::character varying,
    create_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater                      varchar(64) DEFAULT ''::character varying,
    update_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted                      smallint DEFAULT 0 NOT NULL,
    warehouse_type               varchar(16) DEFAULT 'CENTER'::character varying NOT NULL,
    store_customer_id            bigint,
    dept_id                      bigint,
    CONSTRAINT erp_warehouse_pkey PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS fms_account_set (
    id                           bigint NOT NULL,
    company_code                 text,
    company_name                 text,
    company_profile              text,
    industry                     text,
    location                     text,
    legal_representative         text,
    legal_representative_id_number text,
    business_license_number      text,
    organization_code            text,
    remark                       text,
    contact_name                 text,
    office_telephone             text,
    mobile                       text,
    fax_number                   text,
    qq_number                    text,
    email                        text,
    other_contact                text,
    address                      text,
    currency_id                  bigint,
    start_time                   timestamp,
    standard                     integer,
    initialized                  boolean,
    tenant_id                    bigint DEFAULT 0 NOT NULL,
    creator                      varchar(64) DEFAULT ''::character varying,
    create_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater                      varchar(64) DEFAULT ''::character varying,
    update_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted                      smallint DEFAULT 0 NOT NULL,
    CONSTRAINT fms_account_set_pkey PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS fms_account_user (
    id                           bigint NOT NULL,
    account_set_id               bigint,
    user_id                      bigint,
    default_status               boolean,
    founder                      boolean,
    level                        integer,
    tenant_id                    bigint DEFAULT 0 NOT NULL,
    creator                      varchar(64) DEFAULT ''::character varying,
    create_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater                      varchar(64) DEFAULT ''::character varying,
    update_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted                      smallint DEFAULT 0 NOT NULL,
    CONSTRAINT fms_account_user_pkey PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS fms_assist_combination (
    id                           bigint NOT NULL,
    subject_id                   bigint,
    account_set_id               bigint,
    items                        text,
    tenant_id                    bigint DEFAULT 0 NOT NULL,
    creator                      varchar(64) DEFAULT ''::character varying,
    create_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater                      varchar(64) DEFAULT ''::character varying,
    update_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted                      smallint DEFAULT 0 NOT NULL,
    CONSTRAINT fms_assist_combination_pkey PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS fms_auxiliary_item (
    id                           bigint NOT NULL,
    code                         text,
    name                         text,
    auxiliary_type_id            bigint,
    status                       integer,
    account_set_id               bigint,
    remark                       text,
    specification                text,
    unit                         text,
    tenant_id                    bigint DEFAULT 0 NOT NULL,
    creator                      varchar(64) DEFAULT ''::character varying,
    create_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater                      varchar(64) DEFAULT ''::character varying,
    update_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted                      smallint DEFAULT 0 NOT NULL,
    CONSTRAINT fms_auxiliary_item_pkey PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS fms_auxiliary_type (
    id                           bigint NOT NULL,
    name                         text,
    system_preset                boolean,
    account_set_id               bigint,
    type                         integer,
    tenant_id                    bigint DEFAULT 0 NOT NULL,
    creator                      varchar(64) DEFAULT ''::character varying,
    create_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater                      varchar(64) DEFAULT ''::character varying,
    update_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted                      smallint DEFAULT 0 NOT NULL,
    CONSTRAINT fms_auxiliary_type_pkey PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS fms_balance_sheet_config (
    id                           bigint NOT NULL,
    name                         text,
    row_no                       integer,
    formula                      text,
    remark                       text,
    editable                     boolean,
    sort                         integer,
    account_set_id               bigint,
    level                        integer,
    row_id                       integer,
    tenant_id                    bigint DEFAULT 0 NOT NULL,
    creator                      varchar(64) DEFAULT ''::character varying,
    create_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater                      varchar(64) DEFAULT ''::character varying,
    update_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted                      smallint DEFAULT 0 NOT NULL,
    CONSTRAINT fms_balance_sheet_config_pkey PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS fms_balance_sheet_report (
    id                           bigint NOT NULL,
    from_period                  integer,
    to_period                    integer,
    type                         integer,
    level                        integer,
    name                         text,
    row_no                       integer,
    formula                      text,
    remark                       text,
    editable                     boolean,
    sort                         integer,
    opening_amount               numeric(24,6),
    closing_amount               numeric(24,6),
    account_set_id               bigint,
    settled                      boolean,
    row_id                       integer,
    tenant_id                    bigint DEFAULT 0 NOT NULL,
    creator                      varchar(64) DEFAULT ''::character varying,
    create_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater                      varchar(64) DEFAULT ''::character varying,
    update_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted                      smallint DEFAULT 0 NOT NULL,
    CONSTRAINT fms_balance_sheet_report_pkey PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS fms_cash_flow_extend_config (
    id                           bigint NOT NULL,
    name                         text,
    row_no                       integer,
    formula                      text,
    remark                       text,
    category                     integer,
    type                         integer,
    current_amount               numeric(24,6),
    year_amount                  numeric(24,6),
    editable                     boolean,
    account_set_id               bigint,
    sort                         integer,
    level                        integer,
    tenant_id                    bigint DEFAULT 0 NOT NULL,
    creator                      varchar(64) DEFAULT ''::character varying,
    create_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater                      varchar(64) DEFAULT ''::character varying,
    update_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted                      smallint DEFAULT 0 NOT NULL,
    CONSTRAINT fms_cash_flow_extend_config_pkey PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS fms_cash_flow_extend_data (
    id                           bigint NOT NULL,
    name                         text,
    row_no                       integer,
    formula                      text,
    remark                       text,
    category                     integer,
    current_amount               numeric(24,6),
    year_amount                  numeric(24,6),
    from_period                  integer,
    editable                     boolean,
    account_set_id               bigint,
    sort                         integer,
    to_period                    integer,
    type                         integer,
    level                        integer,
    tenant_id                    bigint DEFAULT 0 NOT NULL,
    creator                      varchar(64) DEFAULT ''::character varying,
    create_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater                      varchar(64) DEFAULT ''::character varying,
    update_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted                      smallint DEFAULT 0 NOT NULL,
    CONSTRAINT fms_cash_flow_extend_data_pkey PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS fms_cash_flow_statement_config (
    id                           bigint NOT NULL,
    name                         text,
    row_no                       integer,
    formula                      text,
    remark                       text,
    editable                     boolean,
    sort                         integer,
    category                     integer,
    account_set_id               bigint,
    level                        integer,
    tenant_id                    bigint DEFAULT 0 NOT NULL,
    creator                      varchar(64) DEFAULT ''::character varying,
    create_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater                      varchar(64) DEFAULT ''::character varying,
    update_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted                      smallint DEFAULT 0 NOT NULL,
    CONSTRAINT fms_cash_flow_statement_config_pkey PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS fms_cash_flow_statement_report (
    id                           bigint NOT NULL,
    from_period                  integer,
    name                         text,
    row_no                       integer,
    formula                      text,
    remark                       text,
    editable                     boolean,
    current_amount               numeric(24,6),
    year_amount                  numeric(24,6),
    sort                         integer,
    category                     integer,
    account_set_id               bigint,
    to_period                    integer,
    type                         integer,
    level                        integer,
    tenant_id                    bigint DEFAULT 0 NOT NULL,
    creator                      varchar(64) DEFAULT ''::character varying,
    create_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater                      varchar(64) DEFAULT ''::character varying,
    update_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted                      smallint DEFAULT 0 NOT NULL,
    CONSTRAINT fms_cash_flow_statement_report_pkey PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS fms_closing (
    id                           bigint NOT NULL,
    name                         text,
    period_end                   boolean,
    subject_id                   bigint,
    formula_rule                 integer,
    time_type                    integer,
    voucher_word_id              bigint,
    digest                       text,
    voucher_type                 integer,
    prior_year_adjustment_subject_id bigint,
    adjustment_closing_subject_id bigint,
    other_closing_subject_id     bigint,
    reverse_balance              boolean,
    type                         integer,
    account_set_id               bigint,
    closing_day                  integer,
    subject_rules                text,
    tenant_id                    bigint DEFAULT 0 NOT NULL,
    creator                      varchar(64) DEFAULT ''::character varying,
    create_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater                      varchar(64) DEFAULT ''::character varying,
    update_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted                      smallint DEFAULT 0 NOT NULL,
    CONSTRAINT fms_closing_pkey PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS fms_closing_period (
    id                           bigint NOT NULL,
    closing_time                 timestamp,
    account_set_id               bigint,
    tenant_id                    bigint DEFAULT 0 NOT NULL,
    creator                      varchar(64) DEFAULT ''::character varying,
    create_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater                      varchar(64) DEFAULT ''::character varying,
    update_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted                      smallint DEFAULT 0 NOT NULL,
    CONSTRAINT fms_closing_period_pkey PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS fms_closing_template (
    id                           bigint NOT NULL,
    account_set_id               bigint,
    preset_code                  text,
    name                         text,
    category                     integer,
    period_end                   boolean,
    subject_id                   bigint,
    formula_rule                 integer,
    time_type                    integer,
    subject_rules                text,
    sort                         integer,
    tenant_id                    bigint DEFAULT 0 NOT NULL,
    creator                      varchar(64) DEFAULT ''::character varying,
    create_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater                      varchar(64) DEFAULT ''::character varying,
    update_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted                      smallint DEFAULT 0 NOT NULL,
    CONSTRAINT fms_closing_template_pkey PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS fms_closing_voucher (
    id                           bigint NOT NULL,
    closing_id                   bigint,
    voucher_id                   bigint,
    voucher_time                 timestamp,
    amount                       numeric(24,6),
    closed                       boolean,
    account_set_id               bigint,
    tenant_id                    bigint DEFAULT 0 NOT NULL,
    creator                      varchar(64) DEFAULT ''::character varying,
    create_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater                      varchar(64) DEFAULT ''::character varying,
    update_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted                      smallint DEFAULT 0 NOT NULL,
    CONSTRAINT fms_closing_voucher_pkey PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS fms_currency (
    id                           bigint NOT NULL,
    code                         text,
    name                         text,
    exchange_rate                numeric(24,6),
    standard                     boolean,
    account_set_id               bigint,
    tenant_id                    bigint DEFAULT 0 NOT NULL,
    creator                      varchar(64) DEFAULT ''::character varying,
    create_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater                      varchar(64) DEFAULT ''::character varying,
    update_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted                      smallint DEFAULT 0 NOT NULL,
    CONSTRAINT fms_currency_pkey PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS fms_digest (
    id                           bigint NOT NULL,
    content                      text,
    account_set_id               bigint,
    tenant_id                    bigint DEFAULT 0 NOT NULL,
    creator                      varchar(64) DEFAULT ''::character varying,
    create_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater                      varchar(64) DEFAULT ''::character varying,
    update_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted                      smallint DEFAULT 0 NOT NULL,
    CONSTRAINT fms_digest_pkey PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS fms_finance_indicator (
    id                           bigint NOT NULL,
    account_set_id               bigint,
    name                         text,
    code                         text,
    type                         integer,
    formula                      text,
    sort                         integer,
    status                       integer,
    tenant_id                    bigint DEFAULT 0 NOT NULL,
    creator                      varchar(64) DEFAULT ''::character varying,
    create_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater                      varchar(64) DEFAULT ''::character varying,
    update_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted                      smallint DEFAULT 0 NOT NULL,
    CONSTRAINT fms_finance_indicator_pkey PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS fms_finance_parameter (
    id                           bigint NOT NULL,
    account_set_id               bigint,
    level                        integer,
    subject_code_rule            text,
    ledger_balance_mode          integer,
    deficit_check                boolean,
    voucher_review_required      boolean,
    asset_period_locked          boolean,
    taxpayer_name                text,
    taxpayer_number              text,
    tenant_id                    bigint DEFAULT 0 NOT NULL,
    creator                      varchar(64) DEFAULT ''::character varying,
    create_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater                      varchar(64) DEFAULT ''::character varying,
    update_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted                      smallint DEFAULT 0 NOT NULL,
    CONSTRAINT fms_finance_parameter_pkey PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS fms_income_statement_config (
    id                           bigint NOT NULL,
    name                         text,
    row_no                       integer,
    formula                      text,
    sort                         integer,
    editable                     boolean,
    account_set_id               bigint,
    level                        integer,
    tenant_id                    bigint DEFAULT 0 NOT NULL,
    creator                      varchar(64) DEFAULT ''::character varying,
    create_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater                      varchar(64) DEFAULT ''::character varying,
    update_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted                      smallint DEFAULT 0 NOT NULL,
    CONSTRAINT fms_income_statement_config_pkey PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS fms_income_statement_report (
    id                           bigint NOT NULL,
    type                         integer,
    from_period                  integer,
    to_period                    integer,
    name                         text,
    row_no                       integer,
    formula                      text,
    sort                         integer,
    editable                     boolean,
    current_amount               numeric(24,6),
    year_amount                  numeric(24,6),
    account_set_id               bigint,
    level                        integer,
    settled                      boolean,
    tenant_id                    bigint DEFAULT 0 NOT NULL,
    creator                      varchar(64) DEFAULT ''::character varying,
    create_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater                      varchar(64) DEFAULT ''::character varying,
    update_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted                      smallint DEFAULT 0 NOT NULL,
    CONSTRAINT fms_income_statement_report_pkey PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS fms_initial_balance (
    id                           bigint NOT NULL,
    subject_id                   bigint,
    auxiliary_accounting         boolean,
    opening_amount               numeric(24,6),
    opening_quantity             numeric(24,6),
    year_debit_amount            numeric(24,6),
    year_debit_quantity          numeric(24,6),
    year_credit_amount           numeric(24,6),
    year_credit_quantity         numeric(24,6),
    year_opening_amount          numeric(24,6),
    year_opening_quantity        numeric(24,6),
    profit_loss_amount           numeric(24,6),
    profit_loss_quantity         numeric(24,6),
    account_set_id               bigint,
    assist_balances              text,
    tenant_id                    bigint DEFAULT 0 NOT NULL,
    creator                      varchar(64) DEFAULT ''::character varying,
    create_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater                      varchar(64) DEFAULT ''::character varying,
    update_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted                      smallint DEFAULT 0 NOT NULL,
    CONSTRAINT fms_initial_balance_pkey PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS fms_report_template (
    id                           bigint NOT NULL,
    name                         text,
    row_no                       integer,
    formula                      text,
    remark                       text,
    editable                     boolean,
    sort                         integer,
    row_id                       integer,
    type                         integer,
    category                     integer,
    level                        integer,
    tenant_id                    bigint DEFAULT 0 NOT NULL,
    creator                      varchar(64) DEFAULT ''::character varying,
    create_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater                      varchar(64) DEFAULT ''::character varying,
    update_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted                      smallint DEFAULT 0 NOT NULL,
    CONSTRAINT fms_report_template_pkey PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS fms_subject (
    id                           bigint NOT NULL,
    code                         text,
    name                         text,
    parent_id                    bigint,
    type                         integer,
    category                     integer,
    balance_direction            integer,
    quantity_unit                text,
    cash                         boolean,
    status                       integer,
    level                        integer,
    quantity_accounting          boolean,
    account_set_id               bigint,
    auxiliary_type_ids           text,
    currency_ids                 text,
    tenant_id                    bigint DEFAULT 0 NOT NULL,
    creator                      varchar(64) DEFAULT ''::character varying,
    create_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater                      varchar(64) DEFAULT ''::character varying,
    update_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted                      smallint DEFAULT 0 NOT NULL,
    CONSTRAINT fms_subject_pkey PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS fms_subject_template (
    id                           bigint NOT NULL,
    code                         text,
    name                         text,
    parent_id                    bigint,
    type                         integer,
    category                     integer,
    balance_direction            integer,
    quantity_unit                text,
    cash                         boolean,
    status                       integer,
    level                        integer,
    quantity_accounting          boolean,
    tenant_id                    bigint DEFAULT 0 NOT NULL,
    creator                      varchar(64) DEFAULT ''::character varying,
    create_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater                      varchar(64) DEFAULT ''::character varying,
    update_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted                      smallint DEFAULT 0 NOT NULL,
    CONSTRAINT fms_subject_template_pkey PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS fms_voucher (
    id                           bigint NOT NULL,
    voucher_word_id              bigint,
    voucher_number               integer,
    voucher_time                 timestamp,
    attachment_urls              text,
    attachment_count             integer,
    debit_amount                 numeric(24,6),
    credit_amount                numeric(24,6),
    total                        numeric(24,6),
    status                       integer,
    reviewer_user_id             bigint,
    account_set_id               bigint,
    tenant_id                    bigint DEFAULT 0 NOT NULL,
    creator                      varchar(64) DEFAULT ''::character varying,
    create_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater                      varchar(64) DEFAULT ''::character varying,
    update_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted                      smallint DEFAULT 0 NOT NULL,
    CONSTRAINT fms_voucher_pkey PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS fms_voucher_entry (
    id                           bigint NOT NULL,
    digest                       text,
    subject_name                 text,
    quantity                     numeric(24,6),
    debit_amount                 numeric(24,6),
    credit_amount                numeric(24,6),
    voucher_id                   bigint,
    subject_code                 text,
    sort                         integer,
    subject_id                   bigint,
    account_set_id               bigint,
    unit_price                   numeric(24,6),
    assist_combination_id        bigint,
    auxiliaries                  text,
    tenant_id                    bigint DEFAULT 0 NOT NULL,
    creator                      varchar(64) DEFAULT ''::character varying,
    create_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater                      varchar(64) DEFAULT ''::character varying,
    update_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted                      smallint DEFAULT 0 NOT NULL,
    CONSTRAINT fms_voucher_entry_pkey PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS fms_voucher_template (
    id                           bigint NOT NULL,
    name                         text,
    category_id                  bigint,
    entries                      text,
    account_set_id               bigint,
    tenant_id                    bigint DEFAULT 0 NOT NULL,
    creator                      varchar(64) DEFAULT ''::character varying,
    create_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater                      varchar(64) DEFAULT ''::character varying,
    update_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted                      smallint DEFAULT 0 NOT NULL,
    CONSTRAINT fms_voucher_template_pkey PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS fms_voucher_template_category (
    id                           bigint NOT NULL,
    name                         text,
    account_set_id               bigint,
    tenant_id                    bigint DEFAULT 0 NOT NULL,
    creator                      varchar(64) DEFAULT ''::character varying,
    create_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater                      varchar(64) DEFAULT ''::character varying,
    update_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted                      smallint DEFAULT 0 NOT NULL,
    CONSTRAINT fms_voucher_template_category_pkey PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS fms_voucher_word (
    id                           bigint NOT NULL,
    name                         text,
    print_title                  text,
    default_status               boolean,
    sort                         integer,
    account_set_id               bigint,
    tenant_id                    bigint DEFAULT 0 NOT NULL,
    creator                      varchar(64) DEFAULT ''::character varying,
    create_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater                      varchar(64) DEFAULT ''::character varying,
    update_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted                      smallint DEFAULT 0 NOT NULL,
    CONSTRAINT fms_voucher_word_pkey PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS member_user (
    id                           bigint NOT NULL,
    mobile                       text,
    email                        text,
    password                     text,
    status                       integer,
    register_ip                  text,
    register_terminal            integer,
    login_ip                     text,
    login_date                   timestamp,
    nickname                     text,
    avatar                       text,
    name                         text,
    sex                          integer,
    birthday                     timestamp,
    area_id                      integer,
    mark                         text,
    tenant_id                    bigint DEFAULT 0 NOT NULL,
    creator                      varchar(64) DEFAULT ''::character varying,
    create_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater                      varchar(64) DEFAULT ''::character varying,
    update_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted                      smallint DEFAULT 0 NOT NULL,
    dept_id                      bigint,
    customer_id                  bigint,
    username                     varchar(64),
    CONSTRAINT member_user_pkey PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS product_brand (
    id                           bigint NOT NULL,
    name                         text,
    pic_url                      text,
    sort                         integer,
    description                  text,
    status                       integer,
    tenant_id                    bigint DEFAULT 0 NOT NULL,
    creator                      varchar(64) DEFAULT ''::character varying,
    create_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater                      varchar(64) DEFAULT ''::character varying,
    update_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted                      smallint DEFAULT 0 NOT NULL,
    CONSTRAINT product_brand_pkey PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS product_browse_history (
    id                           bigint NOT NULL,
    spu_id                       bigint,
    user_id                      bigint,
    user_deleted                 boolean,
    tenant_id                    bigint DEFAULT 0 NOT NULL,
    creator                      varchar(64) DEFAULT ''::character varying,
    create_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater                      varchar(64) DEFAULT ''::character varying,
    update_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted                      smallint DEFAULT 0 NOT NULL,
    CONSTRAINT product_browse_history_pkey PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS product_category (
    id                           bigint NOT NULL,
    parent_id                    bigint,
    name                         text,
    pic_url                      text,
    sort                         integer,
    status                       integer,
    tenant_id                    bigint DEFAULT 0 NOT NULL,
    creator                      varchar(64) DEFAULT ''::character varying,
    create_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater                      varchar(64) DEFAULT ''::character varying,
    update_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted                      smallint DEFAULT 0 NOT NULL,
    CONSTRAINT product_category_pkey PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS product_favorite (
    id                           bigint NOT NULL,
    user_id                      bigint,
    spu_id                       bigint,
    tenant_id                    bigint DEFAULT 0 NOT NULL,
    creator                      varchar(64) DEFAULT ''::character varying,
    create_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater                      varchar(64) DEFAULT ''::character varying,
    update_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted                      smallint DEFAULT 0 NOT NULL,
    CONSTRAINT product_favorite_pkey PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS product_property (
    id                           bigint NOT NULL,
    name                         text,
    remark                       text,
    tenant_id                    bigint DEFAULT 0 NOT NULL,
    creator                      varchar(64) DEFAULT ''::character varying,
    create_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater                      varchar(64) DEFAULT ''::character varying,
    update_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted                      smallint DEFAULT 0 NOT NULL,
    CONSTRAINT product_property_pkey PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS product_property_value (
    id                           bigint NOT NULL,
    property_id                  bigint,
    name                         text,
    remark                       text,
    tenant_id                    bigint DEFAULT 0 NOT NULL,
    creator                      varchar(64) DEFAULT ''::character varying,
    create_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater                      varchar(64) DEFAULT ''::character varying,
    update_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted                      smallint DEFAULT 0 NOT NULL,
    CONSTRAINT product_property_value_pkey PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS product_sku (
    id                           bigint NOT NULL,
    spu_id                       bigint,
    properties                   text,
    price                        integer,
    market_price                 integer,
    cost_price                   integer,
    bar_code                     text,
    pic_url                      text,
    stock                        integer,
    weight                       double precision,
    volume                       double precision,
    sales_count                  integer,
    tenant_id                    bigint DEFAULT 0 NOT NULL,
    creator                      varchar(64) DEFAULT ''::character varying,
    create_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater                      varchar(64) DEFAULT ''::character varying,
    update_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted                      smallint DEFAULT 0 NOT NULL,
    CONSTRAINT product_sku_pkey PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS product_spu (
    id                           bigint NOT NULL,
    name                         text,
    keyword                      text,
    introduction                 text,
    description                  text,
    category_id                  bigint,
    brand_id                     bigint,
    pic_url                      text,
    slider_pic_urls              text,
    sort                         integer,
    status                       integer,
    spec_type                    boolean,
    price                        integer,
    market_price                 integer,
    cost_price                   integer,
    stock                        integer,
    delivery_template_id         bigint,
    give_integral                integer,
    sub_commission_type          boolean,
    sales_count                  integer,
    virtual_sales_count          integer,
    browse_count                 integer,
    tenant_id                    bigint DEFAULT 0 NOT NULL,
    creator                      varchar(64) DEFAULT ''::character varying,
    create_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater                      varchar(64) DEFAULT ''::character varying,
    update_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted                      smallint DEFAULT 0 NOT NULL,
    CONSTRAINT product_spu_pkey PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS product_statistics (
    id                           bigint NOT NULL,
    time                         date,
    spu_id                       bigint,
    browse_count                 integer,
    browse_user_count            integer,
    favorite_count               integer,
    cart_count                   integer,
    order_count                  integer,
    order_pay_count              integer,
    order_pay_price              integer,
    after_sale_count             integer,
    after_sale_refund_price      integer,
    browse_convert_percent       integer,
    tenant_id                    bigint DEFAULT 0 NOT NULL,
    creator                      varchar(64) DEFAULT ''::character varying,
    create_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater                      varchar(64) DEFAULT ''::character varying,
    update_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted                      smallint DEFAULT 0 NOT NULL,
    CONSTRAINT product_statistics_pkey PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS trade_after_sale (
    id                           bigint NOT NULL,
    no                           text,
    status                       integer,
    way                          integer,
    type                         integer,
    user_id                      bigint,
    apply_reason                 text,
    apply_description            text,
    apply_pic_urls               text,
    order_id                     bigint,
    order_no                     text,
    order_item_id                bigint,
    spu_id                       bigint,
    spu_name                     text,
    sku_id                       bigint,
    properties                   text,
    pic_url                      text,
    count                        integer,
    audit_time                   timestamp,
    audit_user_id                bigint,
    audit_reason                 text,
    refund_price                 integer,
    pay_refund_id                bigint,
    refund_time                  timestamp,
    logistics_id                 bigint,
    logistics_no                 text,
    delivery_time                timestamp,
    receive_time                 timestamp,
    receive_reason               text,
    tenant_id                    bigint DEFAULT 0 NOT NULL,
    creator                      varchar(64) DEFAULT ''::character varying,
    create_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater                      varchar(64) DEFAULT ''::character varying,
    update_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted                      smallint DEFAULT 0 NOT NULL,
    refund_channel_code          varchar(32),
    refund_proof_urls            text,
    refund_remark                varchar(255),
    CONSTRAINT trade_after_sale_pkey PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS trade_after_sale_log (
    id                           bigint NOT NULL,
    user_id                      bigint,
    user_type                    integer,
    after_sale_id                bigint,
    before_status                integer,
    after_status                 integer,
    operate_type                 integer,
    content                      text,
    tenant_id                    bigint DEFAULT 0 NOT NULL,
    creator                      varchar(64) DEFAULT ''::character varying,
    create_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater                      varchar(64) DEFAULT ''::character varying,
    update_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted                      smallint DEFAULT 0 NOT NULL,
    CONSTRAINT trade_after_sale_log_pkey PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS trade_cart (
    id                           bigint NOT NULL,
    user_id                      bigint,
    spu_id                       bigint,
    sku_id                       bigint,
    count                        integer,
    selected                     boolean,
    tenant_id                    bigint DEFAULT 0 NOT NULL,
    creator                      varchar(64) DEFAULT ''::character varying,
    create_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater                      varchar(64) DEFAULT ''::character varying,
    update_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted                      smallint DEFAULT 0 NOT NULL,
    CONSTRAINT trade_cart_pkey PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS trade_config (
    id                           bigint NOT NULL,
    after_sale_refund_reasons    text,
    after_sale_return_reasons    text,
    delivery_express_free_enabled boolean,
    delivery_express_free_price  integer,
    tenant_id                    bigint DEFAULT 0 NOT NULL,
    creator                      varchar(64) DEFAULT ''::character varying,
    create_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater                      varchar(64) DEFAULT ''::character varying,
    update_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted                      smallint DEFAULT 0 NOT NULL,
    CONSTRAINT trade_config_pkey PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS trade_delivery_express (
    id                           bigint NOT NULL,
    code                         text,
    name                         text,
    logo                         text,
    sort                         integer,
    status                       integer,
    tenant_id                    bigint DEFAULT 0 NOT NULL,
    creator                      varchar(64) DEFAULT ''::character varying,
    create_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater                      varchar(64) DEFAULT ''::character varying,
    update_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted                      smallint DEFAULT 0 NOT NULL,
    CONSTRAINT trade_delivery_express_pkey PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS trade_delivery_express_template (
    id                           bigint NOT NULL,
    name                         text,
    charge_mode                  integer,
    sort                         integer,
    tenant_id                    bigint DEFAULT 0 NOT NULL,
    creator                      varchar(64) DEFAULT ''::character varying,
    create_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater                      varchar(64) DEFAULT ''::character varying,
    update_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted                      smallint DEFAULT 0 NOT NULL,
    CONSTRAINT trade_delivery_express_template_pkey PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS trade_delivery_express_template_charge (
    id                           bigint NOT NULL,
    template_id                  bigint,
    area_ids                     text,
    charge_mode                  integer,
    start_count                  double precision,
    start_price                  integer,
    extra_count                  double precision,
    extra_price                  integer,
    tenant_id                    bigint DEFAULT 0 NOT NULL,
    creator                      varchar(64) DEFAULT ''::character varying,
    create_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater                      varchar(64) DEFAULT ''::character varying,
    update_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted                      smallint DEFAULT 0 NOT NULL,
    CONSTRAINT trade_delivery_express_template_charge_pkey PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS trade_delivery_express_template_free (
    id                           bigint NOT NULL,
    template_id                  bigint,
    area_ids                     text,
    free_price                   integer,
    free_count                   integer,
    tenant_id                    bigint DEFAULT 0 NOT NULL,
    creator                      varchar(64) DEFAULT ''::character varying,
    create_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater                      varchar(64) DEFAULT ''::character varying,
    update_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted                      smallint DEFAULT 0 NOT NULL,
    CONSTRAINT trade_delivery_express_template_free_pkey PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS trade_order (
    id                           bigint NOT NULL,
    no                           text,
    type                         integer,
    terminal                     integer,
    user_id                      bigint,
    user_ip                      text,
    user_remark                  text,
    status                       integer,
    product_count                integer,
    finish_time                  timestamp,
    cancel_time                  timestamp,
    cancel_type                  integer,
    remark                       text,
    pay_order_id                 bigint,
    pay_status                   boolean,
    pay_time                     timestamp,
    pay_channel_code             text,
    total_price                  integer,
    discount_price               integer,
    delivery_price               integer,
    adjust_price                 integer DEFAULT 0,
    pay_price                    integer,
    delivery_type                integer,
    logistics_id                 bigint,
    logistics_no                 text,
    delivery_time                timestamp,
    receive_time                 timestamp,
    receiver_name                text,
    receiver_mobile              text,
    receiver_area_id             integer,
    receiver_detail_address      text,
    refund_status                integer,
    refund_price                 integer,
    tenant_id                    bigint DEFAULT 0 NOT NULL,
    creator                      varchar(64) DEFAULT ''::character varying,
    create_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater                      varchar(64) DEFAULT ''::character varying,
    update_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted                      smallint DEFAULT 0 NOT NULL,
    paid_amount                  integer DEFAULT 0 NOT NULL,
    payment_proof_status         smallint DEFAULT 0 NOT NULL,
    dept_id                      bigint,
    customer_id                  bigint,
    agent_customer_id            bigint,
    settlement_mode              varchar(20),
    audit_status                 smallint DEFAULT 0 NOT NULL,
    audit_user_id                bigint,
    audit_time                   timestamp,
    audit_remark                 varchar(500) DEFAULT ''::character varying,
    process_instance_id          varchar(64) DEFAULT ''::character varying,
    store_type                   varchar(20),
    receipt_status               smallint DEFAULT 0 NOT NULL,
    CONSTRAINT trade_order_pkey PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS trade_order_item (
    id                           bigint NOT NULL,
    user_id                      bigint,
    order_id                     bigint,
    cart_id                      bigint,
    spu_id                       bigint,
    spu_name                     text,
    sku_id                       bigint,
    properties                   text,
    pic_url                      text,
    count                        integer,
    price                        integer,
    discount_price               integer,
    delivery_price               integer,
    adjust_price                 integer DEFAULT 0,
    pay_price                    integer,
    after_sale_id                bigint,
    after_sale_status            integer,
    tenant_id                    bigint DEFAULT 0 NOT NULL,
    creator                      varchar(64) DEFAULT ''::character varying,
    create_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater                      varchar(64) DEFAULT ''::character varying,
    update_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted                      smallint DEFAULT 0 NOT NULL,
    alloc_mode                   varchar(16),
    alloc_count                  numeric(24,6),
    delivered_count              numeric(24,6) DEFAULT 0 NOT NULL,
    receipt_count                numeric(24,6) DEFAULT 0 NOT NULL,
    CONSTRAINT trade_order_item_pkey PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS trade_order_log (
    id                           bigint NOT NULL,
    user_id                      bigint,
    user_type                    integer,
    order_id                     bigint,
    before_status                integer,
    after_status                 integer,
    operate_type                 integer,
    content                      text,
    tenant_id                    bigint DEFAULT 0 NOT NULL,
    creator                      varchar(64) DEFAULT ''::character varying,
    create_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater                      varchar(64) DEFAULT ''::character varying,
    update_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted                      smallint DEFAULT 0 NOT NULL,
    CONSTRAINT trade_order_log_pkey PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS trade_statistics (
    id                           bigint NOT NULL,
    time                         timestamp,
    order_create_count           integer,
    order_pay_count              integer,
    order_pay_price              integer,
    after_sale_count             integer,
    after_sale_refund_price      integer,
    wallet_pay_price             integer,
    recharge_pay_count           integer,
    recharge_pay_price           integer,
    recharge_refund_count        integer,
    recharge_refund_price        integer,
    tenant_id                    bigint DEFAULT 0 NOT NULL,
    creator                      varchar(64) DEFAULT ''::character varying,
    create_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater                      varchar(64) DEFAULT ''::character varying,
    update_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted                      smallint DEFAULT 0 NOT NULL,
    CONSTRAINT trade_statistics_pkey PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS wms_check_order (
    id                           bigint NOT NULL,
    no                           text,
    order_time                   timestamp,
    status                       integer,
    remark                       text,
    warehouse_id                 bigint,
    total_quantity               numeric(24,6),
    total_price                  numeric(24,6),
    actual_price                 numeric(24,6),
    tenant_id                    bigint DEFAULT 0 NOT NULL,
    creator                      varchar(64) DEFAULT ''::character varying,
    create_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater                      varchar(64) DEFAULT ''::character varying,
    update_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted                      smallint DEFAULT 0 NOT NULL,
    CONSTRAINT wms_check_order_pkey PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS wms_check_order_detail (
    id                           bigint NOT NULL,
    order_id                     bigint,
    sku_id                       bigint,
    warehouse_id                 bigint,
    inventory_id                 bigint,
    receipt_time                 timestamp,
    quantity                     numeric(24,6),
    check_quantity               numeric(24,6),
    price                        numeric(24,6),
    tenant_id                    bigint DEFAULT 0 NOT NULL,
    creator                      varchar(64) DEFAULT ''::character varying,
    create_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater                      varchar(64) DEFAULT ''::character varying,
    update_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted                      smallint DEFAULT 0 NOT NULL,
    CONSTRAINT wms_check_order_detail_pkey PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS wms_inventory (
    id                           bigint NOT NULL,
    sku_id                       bigint,
    warehouse_id                 bigint,
    quantity                     numeric(24,6),
    remark                       text,
    tenant_id                    bigint DEFAULT 0 NOT NULL,
    creator                      varchar(64) DEFAULT ''::character varying,
    create_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater                      varchar(64) DEFAULT ''::character varying,
    update_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted                      smallint DEFAULT 0 NOT NULL,
    CONSTRAINT wms_inventory_pkey PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS wms_inventory_history (
    id                           bigint NOT NULL,
    warehouse_id                 bigint,
    sku_id                       bigint,
    quantity                     numeric(24,6),
    before_quantity              numeric(24,6),
    after_quantity               numeric(24,6),
    price                        numeric(24,6),
    total_price                  numeric(24,6),
    remark                       text,
    order_id                     bigint,
    order_no                     text,
    order_type                   integer,
    tenant_id                    bigint DEFAULT 0 NOT NULL,
    creator                      varchar(64) DEFAULT ''::character varying,
    create_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater                      varchar(64) DEFAULT ''::character varying,
    update_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted                      smallint DEFAULT 0 NOT NULL,
    CONSTRAINT wms_inventory_history_pkey PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS wms_item (
    id                           bigint NOT NULL,
    code                         text,
    name                         text,
    unit                         text,
    category_id                  bigint,
    brand_id                     bigint,
    remark                       text,
    tenant_id                    bigint DEFAULT 0 NOT NULL,
    creator                      varchar(64) DEFAULT ''::character varying,
    create_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater                      varchar(64) DEFAULT ''::character varying,
    update_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted                      smallint DEFAULT 0 NOT NULL,
    CONSTRAINT wms_item_pkey PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS wms_item_brand (
    id                           bigint NOT NULL,
    code                         text,
    name                         text,
    tenant_id                    bigint DEFAULT 0 NOT NULL,
    creator                      varchar(64) DEFAULT ''::character varying,
    create_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater                      varchar(64) DEFAULT ''::character varying,
    update_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted                      smallint DEFAULT 0 NOT NULL,
    CONSTRAINT wms_item_brand_pkey PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS wms_item_category (
    id                           bigint NOT NULL,
    parent_id                    bigint,
    code                         text,
    name                         text,
    sort                         integer,
    status                       integer,
    tenant_id                    bigint DEFAULT 0 NOT NULL,
    creator                      varchar(64) DEFAULT ''::character varying,
    create_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater                      varchar(64) DEFAULT ''::character varying,
    update_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted                      smallint DEFAULT 0 NOT NULL,
    CONSTRAINT wms_item_category_pkey PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS wms_item_sku (
    id                           bigint NOT NULL,
    name                         text,
    item_id                      bigint,
    bar_code                     text,
    code                         text,
    length                       numeric(24,6),
    width                        numeric(24,6),
    height                       numeric(24,6),
    gross_weight                 numeric(24,6),
    net_weight                   numeric(24,6),
    cost_price                   numeric(24,6),
    selling_price                numeric(24,6),
    tenant_id                    bigint DEFAULT 0 NOT NULL,
    creator                      varchar(64) DEFAULT ''::character varying,
    create_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater                      varchar(64) DEFAULT ''::character varying,
    update_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted                      smallint DEFAULT 0 NOT NULL,
    CONSTRAINT wms_item_sku_pkey PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS wms_merchant (
    id                           bigint NOT NULL,
    code                         text,
    name                         text,
    type                         integer,
    level                        text,
    bank_name                    text,
    bank_account                 text,
    address                      text,
    mobile                       text,
    telephone                    text,
    contact                      text,
    email                        text,
    remark                       text,
    tenant_id                    bigint DEFAULT 0 NOT NULL,
    creator                      varchar(64) DEFAULT ''::character varying,
    create_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater                      varchar(64) DEFAULT ''::character varying,
    update_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted                      smallint DEFAULT 0 NOT NULL,
    CONSTRAINT wms_merchant_pkey PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS wms_movement_order (
    id                           bigint NOT NULL,
    no                           text,
    order_time                   timestamp,
    status                       integer,
    remark                       text,
    source_warehouse_id          bigint,
    target_warehouse_id          bigint,
    total_quantity               numeric(24,6),
    total_price                  numeric(24,6),
    tenant_id                    bigint DEFAULT 0 NOT NULL,
    creator                      varchar(64) DEFAULT ''::character varying,
    create_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater                      varchar(64) DEFAULT ''::character varying,
    update_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted                      smallint DEFAULT 0 NOT NULL,
    CONSTRAINT wms_movement_order_pkey PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS wms_movement_order_detail (
    id                           bigint NOT NULL,
    order_id                     bigint,
    sku_id                       bigint,
    source_warehouse_id          bigint,
    target_warehouse_id          bigint,
    quantity                     numeric(24,6),
    price                        numeric(24,6),
    total_price                  numeric(24,6),
    tenant_id                    bigint DEFAULT 0 NOT NULL,
    creator                      varchar(64) DEFAULT ''::character varying,
    create_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater                      varchar(64) DEFAULT ''::character varying,
    update_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted                      smallint DEFAULT 0 NOT NULL,
    CONSTRAINT wms_movement_order_detail_pkey PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS wms_receipt_order (
    id                           bigint NOT NULL,
    no                           text,
    type                         integer,
    order_time                   timestamp,
    status                       integer,
    biz_order_no                 text,
    merchant_id                  bigint,
    remark                       text,
    warehouse_id                 bigint,
    total_quantity               numeric(24,6),
    total_price                  numeric(24,6),
    tenant_id                    bigint DEFAULT 0 NOT NULL,
    creator                      varchar(64) DEFAULT ''::character varying,
    create_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater                      varchar(64) DEFAULT ''::character varying,
    update_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted                      smallint DEFAULT 0 NOT NULL,
    CONSTRAINT wms_receipt_order_pkey PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS wms_receipt_order_detail (
    id                           bigint NOT NULL,
    order_id                     bigint,
    sku_id                       bigint,
    warehouse_id                 bigint,
    quantity                     numeric(24,6),
    price                        numeric(24,6),
    total_price                  numeric(24,6),
    tenant_id                    bigint DEFAULT 0 NOT NULL,
    creator                      varchar(64) DEFAULT ''::character varying,
    create_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater                      varchar(64) DEFAULT ''::character varying,
    update_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted                      smallint DEFAULT 0 NOT NULL,
    CONSTRAINT wms_receipt_order_detail_pkey PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS wms_shipment_order (
    id                           bigint NOT NULL,
    no                           text,
    type                         integer,
    order_time                   timestamp,
    status                       integer,
    biz_order_no                 text,
    merchant_id                  bigint,
    remark                       text,
    warehouse_id                 bigint,
    total_quantity               numeric(24,6),
    total_price                  numeric(24,6),
    tenant_id                    bigint DEFAULT 0 NOT NULL,
    creator                      varchar(64) DEFAULT ''::character varying,
    create_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater                      varchar(64) DEFAULT ''::character varying,
    update_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted                      smallint DEFAULT 0 NOT NULL,
    CONSTRAINT wms_shipment_order_pkey PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS wms_shipment_order_detail (
    id                           bigint NOT NULL,
    order_id                     bigint,
    sku_id                       bigint,
    warehouse_id                 bigint,
    quantity                     numeric(24,6),
    price                        numeric(24,6),
    total_price                  numeric(24,6),
    tenant_id                    bigint DEFAULT 0 NOT NULL,
    creator                      varchar(64) DEFAULT ''::character varying,
    create_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater                      varchar(64) DEFAULT ''::character varying,
    update_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted                      smallint DEFAULT 0 NOT NULL,
    CONSTRAINT wms_shipment_order_detail_pkey PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS wms_warehouse (
    id                           bigint NOT NULL,
    code                         text,
    name                         text,
    remark                       text,
    sort                         integer,
    tenant_id                    bigint DEFAULT 0 NOT NULL,
    creator                      varchar(64) DEFAULT ''::character varying,
    create_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updater                      varchar(64) DEFAULT ''::character varying,
    update_time                  timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted                      smallint DEFAULT 0 NOT NULL,
    CONSTRAINT wms_warehouse_pkey PRIMARY KEY (id)
);

-- ---------------------------------------------------------------------------
-- 索引（主键已内联在建表语句里）
-- ---------------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_erp_customer_dept_id ON erp_customer USING btree (dept_id);
CREATE INDEX IF NOT EXISTS idx_erp_customer_parent_id ON erp_customer USING btree (parent_customer_id);
CREATE INDEX IF NOT EXISTS idx_member_user_customer_id ON member_user USING btree (customer_id);
CREATE INDEX IF NOT EXISTS idx_trade_order_audit_status ON trade_order USING btree (audit_status);
CREATE INDEX IF NOT EXISTS idx_trade_order_customer_id ON trade_order USING btree (customer_id);
CREATE INDEX IF NOT EXISTS idx_trade_order_dept_id ON trade_order USING btree (dept_id);
CREATE INDEX IF NOT EXISTS idx_trade_order_item_alloc_mode ON trade_order_item USING btree (alloc_mode);
CREATE UNIQUE INDEX IF NOT EXISTS uk_erp_warehouse_store_customer ON erp_warehouse USING btree (store_customer_id) WHERE ((deleted = 0) AND (store_customer_id IS NOT NULL));
CREATE UNIQUE INDEX IF NOT EXISTS uk_member_user_username ON member_user USING btree (username) WHERE ((deleted = 0) AND (username IS NOT NULL));

-- ---------------------------------------------------------------------------
-- 列注释（这 123 张表当前没有表级注释，故只还原列注释）
-- ---------------------------------------------------------------------------
COMMENT ON COLUMN erp_customer.dept_id IS '所属部门（门店节点，system_dept.id）';
COMMENT ON COLUMN erp_customer.parent_customer_id IS '上级代理客户编号（代理 → 多门店）';
COMMENT ON COLUMN erp_customer.store_type IS '店型：DIRECT 直营 / FRANCHISE 加盟（字典 erp_store_type）';
COMMENT ON COLUMN erp_customer.settlement_mode IS '结算模式：PREPAID 先款后货 / MONTHLY 月结（字典 trade_settlement_mode）';
COMMENT ON COLUMN erp_customer.credit_days IS '账期天数（月结时生效）';
COMMENT ON COLUMN erp_customer.credit_limit IS '信用额度（月结时生效）';
COMMENT ON COLUMN erp_product.allow_central IS '允许统配：中心库配送出库（工作台可选统配）';
COMMENT ON COLUMN erp_product.allow_direct IS '允许直拨：中心库下采购订单、供应商直送门店（工作台可选直拨）';
COMMENT ON COLUMN erp_purchase_in_items.batch_no IS '批次号：为空时审核入库按 IN{yyyyMMdd}-{项id} 自动生成（ErpStockBatchService#receiveBatch）';
COMMENT ON COLUMN erp_purchase_in_items.production_date IS '生产日期（可空）';
COMMENT ON COLUMN erp_purchase_in_items.expiry_date IS '到期日期（可空）：效期预警口径，FIFO 的次级排序键';
COMMENT ON COLUMN erp_sale_out_items.source_item_id IS '来源业务行 id（门店要货单行 trade_order_item.id；手工出库单为空）';
COMMENT ON COLUMN erp_stock_in_item.batch_no IS '批次号：为空时审核入库按 IN{yyyyMMdd}-{项id} 自动生成';
COMMENT ON COLUMN erp_stock_in_item.production_date IS '生产日期（可空）';
COMMENT ON COLUMN erp_stock_in_item.expiry_date IS '到期日期（可空）：用于效期预警与 FIFO 次级排序';
COMMENT ON COLUMN erp_stock_record.batch_no IS '批次号：出库按 FIFO 拆批后，一行流水对应一个批次';
COMMENT ON COLUMN erp_stock_record.stock_state IS '状态：IN_STOCK 在仓 / IN_TRANSIT 在途 / OCCUPIED 占用 / INSPECTING 待检';
COMMENT ON COLUMN erp_stock_record.unit_cost IS '本行批次单位成本；为空表示老流水（未启用批次前）';
COMMENT ON COLUMN erp_stock_record.total_cost IS '本行成本金额 = count × unit_cost（出库为负，即结转成本）';
COMMENT ON COLUMN erp_stock_record.sku_id IS 'SKU 编号预留位：NULL/0 = 按物料记账（本切片）';
COMMENT ON COLUMN erp_warehouse.warehouse_type IS '仓库类型：CENTER 中心库 / STORE 门店仓';
COMMENT ON COLUMN erp_warehouse.store_customer_id IS '门店仓对应的门店客户（erp_customer.id）；中心库为空';
COMMENT ON COLUMN erp_warehouse.dept_id IS '门店仓对应的部门（erp_customer.dept_id 冗余，便于按组织过滤）';
COMMENT ON COLUMN member_user.dept_id IS '所属部门（门店节点，system_dept.id）';
COMMENT ON COLUMN member_user.customer_id IS '所属客户（门店/代理，erp_customer.id；代理账号可切门店下单）';
COMMENT ON COLUMN member_user.username IS '订货账号（订货人的登录名，就是订货人名字，如张三；唯一）';
COMMENT ON COLUMN trade_after_sale.refund_channel_code IS '线下退款渠道（字典 pay_channel_code 的线下值）';
COMMENT ON COLUMN trade_after_sale.refund_proof_urls IS '线下退款凭证图片（JSON 数组）';
COMMENT ON COLUMN trade_after_sale.refund_remark IS '线下退款备注';
COMMENT ON COLUMN trade_order.dept_id IS '下单门店所属部门（快照，system_dept.id）';
COMMENT ON COLUMN trade_order.customer_id IS '下单门店客户编号（快照，erp_customer.id）';
COMMENT ON COLUMN trade_order.agent_customer_id IS '代理客户编号（快照；代理账号切换门店下单时记录）';
COMMENT ON COLUMN trade_order.settlement_mode IS '结算模式快照：PREPAID 先款后货 / MONTHLY 月结';
COMMENT ON COLUMN trade_order.audit_status IS '审核状态：0 待提交 / 10 审核中 / 20 已通过 / 30 已驳回';
COMMENT ON COLUMN trade_order.process_instance_id IS 'BPM 审批流程实例编号';
COMMENT ON COLUMN trade_order.store_type IS '下单门店店型快照：DIRECT 直营（免审）/ FRANCHISE 加盟（需审核）';
COMMENT ON COLUMN trade_order.receipt_status IS '收货状态：0 未收货 / 10 部分收货 / 20 已收货';
COMMENT ON COLUMN trade_order_item.alloc_mode IS '分料方式：CENTRAL 统配 / DIRECT 直拨；NULL = 未分料（字典 trade_order_item_alloc_mode）';
COMMENT ON COLUMN trade_order_item.alloc_count IS '本次分料下推数量；为空表示按整行数量下推（≤ 原数量）';
COMMENT ON COLUMN trade_order_item.delivered_count IS 'ERP 已发货数量（配送出库单审核后回写）';
COMMENT ON COLUMN trade_order_item.receipt_count IS '门店已确认收货数量';

-- ---------------------------------------------------------------------------
-- 序列复位到 max(id)，避免新装环境主键从 1 开始撞上已有种子数据
-- ---------------------------------------------------------------------------
SELECT setval('ai_api_key_seq', COALESCE((SELECT max(id) FROM ai_api_key), 1), true);
SELECT setval('ai_chat_conversation_seq', COALESCE((SELECT max(id) FROM ai_chat_conversation), 1), true);
SELECT setval('ai_chat_message_seq', COALESCE((SELECT max(id) FROM ai_chat_message), 1), true);
SELECT setval('ai_chat_role_seq', COALESCE((SELECT max(id) FROM ai_chat_role), 1), true);
SELECT setval('ai_image_seq', COALESCE((SELECT max(id) FROM ai_image), 1), true);
SELECT setval('ai_knowledge_seq', COALESCE((SELECT max(id) FROM ai_knowledge), 1), true);
SELECT setval('ai_knowledge_document_seq', COALESCE((SELECT max(id) FROM ai_knowledge_document), 1), true);
SELECT setval('ai_knowledge_segment_seq', COALESCE((SELECT max(id) FROM ai_knowledge_segment), 1), true);
SELECT setval('ai_mind_map_seq', COALESCE((SELECT max(id) FROM ai_mind_map), 1), true);
SELECT setval('ai_model_seq', COALESCE((SELECT max(id) FROM ai_model), 1), true);
SELECT setval('ai_music_seq', COALESCE((SELECT max(id) FROM ai_music), 1), true);
SELECT setval('ai_tool_seq', COALESCE((SELECT max(id) FROM ai_tool), 1), true);
SELECT setval('ai_write_seq', COALESCE((SELECT max(id) FROM ai_write), 1), true);
SELECT setval('bpm_category_seq', COALESCE((SELECT max(id) FROM bpm_category), 1), true);
SELECT setval('bpm_form_seq', COALESCE((SELECT max(id) FROM bpm_form), 1), true);
SELECT setval('bpm_oa_leave_seq', COALESCE((SELECT max(id) FROM bpm_oa_leave), 1), true);
SELECT setval('bpm_process_definition_info_seq', COALESCE((SELECT max(id) FROM bpm_process_definition_info), 1), true);
SELECT setval('bpm_process_expression_seq', COALESCE((SELECT max(id) FROM bpm_process_expression), 1), true);
SELECT setval('bpm_process_instance_copy_seq', COALESCE((SELECT max(id) FROM bpm_process_instance_copy), 1), true);
SELECT setval('bpm_process_listener_seq', COALESCE((SELECT max(id) FROM bpm_process_listener), 1), true);
SELECT setval('bpm_user_group_seq', COALESCE((SELECT max(id) FROM bpm_user_group), 1), true);
SELECT setval('erp_account_seq', COALESCE((SELECT max(id) FROM erp_account), 1), true);
SELECT setval('erp_customer_seq', COALESCE((SELECT max(id) FROM erp_customer), 1), true);
SELECT setval('erp_finance_payment_seq', COALESCE((SELECT max(id) FROM erp_finance_payment), 1), true);
SELECT setval('erp_finance_payment_item_seq', COALESCE((SELECT max(id) FROM erp_finance_payment_item), 1), true);
SELECT setval('erp_finance_receipt_seq', COALESCE((SELECT max(id) FROM erp_finance_receipt), 1), true);
SELECT setval('erp_finance_receipt_item_seq', COALESCE((SELECT max(id) FROM erp_finance_receipt_item), 1), true);
SELECT setval('erp_product_seq', COALESCE((SELECT max(id) FROM erp_product), 1), true);
SELECT setval('erp_product_category_seq', COALESCE((SELECT max(id) FROM erp_product_category), 1), true);
SELECT setval('erp_product_unit_seq', COALESCE((SELECT max(id) FROM erp_product_unit), 1), true);
SELECT setval('erp_purchase_in_seq', COALESCE((SELECT max(id) FROM erp_purchase_in), 1), true);
SELECT setval('erp_purchase_in_items_seq', COALESCE((SELECT max(id) FROM erp_purchase_in_items), 1), true);
SELECT setval('erp_purchase_order_seq', COALESCE((SELECT max(id) FROM erp_purchase_order), 1), true);
SELECT setval('erp_purchase_order_items_seq', COALESCE((SELECT max(id) FROM erp_purchase_order_items), 1), true);
SELECT setval('erp_purchase_return_seq', COALESCE((SELECT max(id) FROM erp_purchase_return), 1), true);
SELECT setval('erp_purchase_return_items_seq', COALESCE((SELECT max(id) FROM erp_purchase_return_items), 1), true);
SELECT setval('erp_sale_order_seq', COALESCE((SELECT max(id) FROM erp_sale_order), 1), true);
SELECT setval('erp_sale_order_items_seq', COALESCE((SELECT max(id) FROM erp_sale_order_items), 1), true);
SELECT setval('erp_sale_out_seq', COALESCE((SELECT max(id) FROM erp_sale_out), 1), true);
SELECT setval('erp_sale_out_items_seq', COALESCE((SELECT max(id) FROM erp_sale_out_items), 1), true);
SELECT setval('erp_sale_return_seq', COALESCE((SELECT max(id) FROM erp_sale_return), 1), true);
SELECT setval('erp_sale_return_items_seq', COALESCE((SELECT max(id) FROM erp_sale_return_items), 1), true);
SELECT setval('erp_stock_seq', COALESCE((SELECT max(id) FROM erp_stock), 1), true);
SELECT setval('erp_stock_check_seq', COALESCE((SELECT max(id) FROM erp_stock_check), 1), true);
SELECT setval('erp_stock_check_item_seq', COALESCE((SELECT max(id) FROM erp_stock_check_item), 1), true);
SELECT setval('erp_stock_in_seq', COALESCE((SELECT max(id) FROM erp_stock_in), 1), true);
SELECT setval('erp_stock_in_item_seq', COALESCE((SELECT max(id) FROM erp_stock_in_item), 1), true);
SELECT setval('erp_stock_move_seq', COALESCE((SELECT max(id) FROM erp_stock_move), 1), true);
SELECT setval('erp_stock_move_item_seq', COALESCE((SELECT max(id) FROM erp_stock_move_item), 1), true);
SELECT setval('erp_stock_out_seq', COALESCE((SELECT max(id) FROM erp_stock_out), 1), true);
SELECT setval('erp_stock_out_item_seq', COALESCE((SELECT max(id) FROM erp_stock_out_item), 1), true);
SELECT setval('erp_stock_record_seq', COALESCE((SELECT max(id) FROM erp_stock_record), 1), true);
SELECT setval('erp_supplier_seq', COALESCE((SELECT max(id) FROM erp_supplier), 1), true);
SELECT setval('erp_warehouse_seq', COALESCE((SELECT max(id) FROM erp_warehouse), 1), true);
SELECT setval('fms_account_set_seq', COALESCE((SELECT max(id) FROM fms_account_set), 1), true);
SELECT setval('fms_account_user_seq', COALESCE((SELECT max(id) FROM fms_account_user), 1), true);
SELECT setval('fms_assist_combination_seq', COALESCE((SELECT max(id) FROM fms_assist_combination), 1), true);
SELECT setval('fms_auxiliary_item_seq', COALESCE((SELECT max(id) FROM fms_auxiliary_item), 1), true);
SELECT setval('fms_auxiliary_type_seq', COALESCE((SELECT max(id) FROM fms_auxiliary_type), 1), true);
SELECT setval('fms_balance_sheet_config_seq', COALESCE((SELECT max(id) FROM fms_balance_sheet_config), 1), true);
SELECT setval('fms_balance_sheet_report_seq', COALESCE((SELECT max(id) FROM fms_balance_sheet_report), 1), true);
SELECT setval('fms_cash_flow_extend_config_seq', COALESCE((SELECT max(id) FROM fms_cash_flow_extend_config), 1), true);
SELECT setval('fms_cash_flow_extend_data_seq', COALESCE((SELECT max(id) FROM fms_cash_flow_extend_data), 1), true);
SELECT setval('fms_cash_flow_statement_config_seq', COALESCE((SELECT max(id) FROM fms_cash_flow_statement_config), 1), true);
SELECT setval('fms_cash_flow_statement_report_seq', COALESCE((SELECT max(id) FROM fms_cash_flow_statement_report), 1), true);
SELECT setval('fms_closing_seq', COALESCE((SELECT max(id) FROM fms_closing), 1), true);
SELECT setval('fms_closing_period_seq', COALESCE((SELECT max(id) FROM fms_closing_period), 1), true);
SELECT setval('fms_closing_template_seq', COALESCE((SELECT max(id) FROM fms_closing_template), 1), true);
SELECT setval('fms_closing_voucher_seq', COALESCE((SELECT max(id) FROM fms_closing_voucher), 1), true);
SELECT setval('fms_currency_seq', COALESCE((SELECT max(id) FROM fms_currency), 1), true);
SELECT setval('fms_digest_seq', COALESCE((SELECT max(id) FROM fms_digest), 1), true);
SELECT setval('fms_finance_indicator_seq', COALESCE((SELECT max(id) FROM fms_finance_indicator), 1), true);
SELECT setval('fms_finance_parameter_seq', COALESCE((SELECT max(id) FROM fms_finance_parameter), 1), true);
SELECT setval('fms_income_statement_config_seq', COALESCE((SELECT max(id) FROM fms_income_statement_config), 1), true);
SELECT setval('fms_income_statement_report_seq', COALESCE((SELECT max(id) FROM fms_income_statement_report), 1), true);
SELECT setval('fms_initial_balance_seq', COALESCE((SELECT max(id) FROM fms_initial_balance), 1), true);
SELECT setval('fms_report_template_seq', COALESCE((SELECT max(id) FROM fms_report_template), 1), true);
SELECT setval('fms_subject_seq', COALESCE((SELECT max(id) FROM fms_subject), 1), true);
SELECT setval('fms_subject_template_seq', COALESCE((SELECT max(id) FROM fms_subject_template), 1), true);
SELECT setval('fms_voucher_seq', COALESCE((SELECT max(id) FROM fms_voucher), 1), true);
SELECT setval('fms_voucher_entry_seq', COALESCE((SELECT max(id) FROM fms_voucher_entry), 1), true);
SELECT setval('fms_voucher_template_seq', COALESCE((SELECT max(id) FROM fms_voucher_template), 1), true);
SELECT setval('fms_voucher_template_category_seq', COALESCE((SELECT max(id) FROM fms_voucher_template_category), 1), true);
SELECT setval('fms_voucher_word_seq', COALESCE((SELECT max(id) FROM fms_voucher_word), 1), true);
SELECT setval('member_user_seq', COALESCE((SELECT max(id) FROM member_user), 1), true);
SELECT setval('product_brand_seq', COALESCE((SELECT max(id) FROM product_brand), 1), true);
SELECT setval('product_browse_history_seq', COALESCE((SELECT max(id) FROM product_browse_history), 1), true);
SELECT setval('product_category_seq', COALESCE((SELECT max(id) FROM product_category), 1), true);
SELECT setval('product_favorite_seq', COALESCE((SELECT max(id) FROM product_favorite), 1), true);
SELECT setval('product_property_seq', COALESCE((SELECT max(id) FROM product_property), 1), true);
SELECT setval('product_property_value_seq', COALESCE((SELECT max(id) FROM product_property_value), 1), true);
SELECT setval('product_sku_seq', COALESCE((SELECT max(id) FROM product_sku), 1), true);
SELECT setval('product_spu_seq', COALESCE((SELECT max(id) FROM product_spu), 1), true);
SELECT setval('product_statistics_seq', COALESCE((SELECT max(id) FROM product_statistics), 1), true);
SELECT setval('trade_after_sale_seq', COALESCE((SELECT max(id) FROM trade_after_sale), 1), true);
SELECT setval('trade_after_sale_log_seq', COALESCE((SELECT max(id) FROM trade_after_sale_log), 1), true);
SELECT setval('trade_cart_seq', COALESCE((SELECT max(id) FROM trade_cart), 1), true);
SELECT setval('trade_config_seq', COALESCE((SELECT max(id) FROM trade_config), 1), true);
SELECT setval('trade_delivery_express_seq', COALESCE((SELECT max(id) FROM trade_delivery_express), 1), true);
SELECT setval('trade_delivery_express_template_seq', COALESCE((SELECT max(id) FROM trade_delivery_express_template), 1), true);
SELECT setval('trade_delivery_express_template_charge_seq', COALESCE((SELECT max(id) FROM trade_delivery_express_template_charge), 1), true);
SELECT setval('trade_delivery_express_template_free_seq', COALESCE((SELECT max(id) FROM trade_delivery_express_template_free), 1), true);
SELECT setval('trade_order_seq', COALESCE((SELECT max(id) FROM trade_order), 1), true);
SELECT setval('trade_order_item_seq', COALESCE((SELECT max(id) FROM trade_order_item), 1), true);
SELECT setval('trade_order_log_seq', COALESCE((SELECT max(id) FROM trade_order_log), 1), true);
SELECT setval('trade_statistics_seq', COALESCE((SELECT max(id) FROM trade_statistics), 1), true);
SELECT setval('wms_check_order_seq', COALESCE((SELECT max(id) FROM wms_check_order), 1), true);
SELECT setval('wms_check_order_detail_seq', COALESCE((SELECT max(id) FROM wms_check_order_detail), 1), true);
SELECT setval('wms_inventory_seq', COALESCE((SELECT max(id) FROM wms_inventory), 1), true);
SELECT setval('wms_inventory_history_seq', COALESCE((SELECT max(id) FROM wms_inventory_history), 1), true);
SELECT setval('wms_item_seq', COALESCE((SELECT max(id) FROM wms_item), 1), true);
SELECT setval('wms_item_brand_seq', COALESCE((SELECT max(id) FROM wms_item_brand), 1), true);
SELECT setval('wms_item_category_seq', COALESCE((SELECT max(id) FROM wms_item_category), 1), true);
SELECT setval('wms_item_sku_seq', COALESCE((SELECT max(id) FROM wms_item_sku), 1), true);
SELECT setval('wms_merchant_seq', COALESCE((SELECT max(id) FROM wms_merchant), 1), true);
SELECT setval('wms_movement_order_seq', COALESCE((SELECT max(id) FROM wms_movement_order), 1), true);
SELECT setval('wms_movement_order_detail_seq', COALESCE((SELECT max(id) FROM wms_movement_order_detail), 1), true);
SELECT setval('wms_receipt_order_seq', COALESCE((SELECT max(id) FROM wms_receipt_order), 1), true);
SELECT setval('wms_receipt_order_detail_seq', COALESCE((SELECT max(id) FROM wms_receipt_order_detail), 1), true);
SELECT setval('wms_shipment_order_seq', COALESCE((SELECT max(id) FROM wms_shipment_order), 1), true);
SELECT setval('wms_shipment_order_detail_seq', COALESCE((SELECT max(id) FROM wms_shipment_order_detail), 1), true);
SELECT setval('wms_warehouse_seq', COALESCE((SELECT max(id) FROM wms_warehouse), 1), true);
