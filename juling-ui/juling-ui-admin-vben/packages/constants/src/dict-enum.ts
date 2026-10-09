/** ========== COMMON - 通用模块 ========== */
const COMMON_DICT = {
  USER_TYPE: 'user_type',
  COMMON_STATUS: 'common_status',
  TERMINAL: 'terminal', // 终端
  DATE_INTERVAL: 'date_interval', // 数据间隔
} as const;

/** ========== SYSTEM - 系统模块 ========== */
const SYSTEM_DICT = {
  SYSTEM_USER_SEX: 'system_user_sex',
  SYSTEM_DEPT_TYPE: 'system_dept_type', // 组织架构节点类型（组织 / 门店）
  SYSTEM_DEPT_BUSINESS_STATUS: 'system_dept_business_status', // 门店营业状态（营业 / 已闭店）
  SYSTEM_MENU_TYPE: 'system_menu_type',
  SYSTEM_ROLE_TYPE: 'system_role_type',
  SYSTEM_DATA_SCOPE: 'system_data_scope',
  SYSTEM_NOTICE_TYPE: 'system_notice_type',
  SYSTEM_LOGIN_TYPE: 'system_login_type',
  SYSTEM_LOGIN_RESULT: 'system_login_result',
  SYSTEM_SMS_CHANNEL_CODE: 'system_sms_channel_code',
  SYSTEM_SMS_TEMPLATE_TYPE: 'system_sms_template_type',
  SYSTEM_SMS_SEND_STATUS: 'system_sms_send_status',
  SYSTEM_SMS_RECEIVE_STATUS: 'system_sms_receive_status',
  SYSTEM_OAUTH2_GRANT_TYPE: 'system_oauth2_grant_type',
  SYSTEM_MAIL_SEND_STATUS: 'system_mail_send_status',
  SYSTEM_NOTIFY_TEMPLATE_TYPE: 'system_notify_template_type',
  SYSTEM_SOCIAL_TYPE: 'system_social_type',
} as const;

/** ========== INFRA - 基础设施模块 ========== */
const INFRA_DICT = {
  INFRA_BOOLEAN_STRING: 'infra_boolean_string',
  INFRA_JOB_STATUS: 'infra_job_status',
  INFRA_JOB_LOG_STATUS: 'infra_job_log_status',
  INFRA_API_ERROR_LOG_PROCESS_STATUS: 'infra_api_error_log_process_status',
  INFRA_CONFIG_TYPE: 'infra_config_type',
  INFRA_CODEGEN_TEMPLATE_TYPE: 'infra_codegen_template_type',
  INFRA_CODEGEN_FRONT_TYPE: 'infra_codegen_front_type',
  INFRA_CODEGEN_SCENE: 'infra_codegen_scene',
  INFRA_FILE_STORAGE: 'infra_file_storage',
  INFRA_OPERATE_TYPE: 'infra_operate_type',
} as const;

/** ========== BPM - 工作流模块 ========== */
const BPM_DICT = {
  BPM_MODEL_FORM_TYPE: 'bpm_model_form_type', // BPM 模型表单类型
  BPM_MODEL_TYPE: 'bpm_model_type', // BPM 模型类型
  BPM_OA_LEAVE_TYPE: 'bpm_oa_leave_type', // BPM OA 请假类型
  BPM_PROCESS_INSTANCE_STATUS: 'bpm_process_instance_status', // BPM 流程实例状态
  BPM_PROCESS_LISTENER_TYPE: 'bpm_process_listener_type', // BPM 流程监听器类型
  BPM_PROCESS_LISTENER_VALUE_TYPE: 'bpm_process_listener_value_type', // BPM 流程监听器值类型
  BPM_COMMENT_TYPE: 'bpm_comment_type', // BPM 评论类型
  BPM_TASK_CANDIDATE_STRATEGY: 'bpm_task_candidate_strategy', // BPM 任务候选人策略
  BPM_TASK_STATUS: 'bpm_task_status', // BPM 任务状态
} as const;

/** ========== PAY - 支付模块 ========== */
const PAY_DICT = {
  PAY_CHANNEL_CODE: 'pay_channel_code', // 支付渠道编码类型
  PAY_ORDER_STATUS: 'pay_order_status', // 商户支付订单状态
  PAY_REFUND_STATUS: 'pay_refund_status', // 退款订单状态
  PAY_NOTIFY_STATUS: 'pay_notify_status', // 商户支付回调状态
  PAY_NOTIFY_TYPE: 'pay_notify_type', // 商户支付回调状态
  PAY_TRANSFER_STATUS: 'pay_transfer_status', // 转账订单状态
  PAY_TRANSFER_TYPE: 'pay_transfer_type', // 转账类型
} as const;

/** ========== MALL - 商城模块 ========== */
const MALL_DICT = {
  /** ========== MALL - 商品模块 ========== */
  PRODUCT_SPU_STATUS: 'product_spu_status', // 商品状态

  /** ========== MALL - 交易模块 ========== */
  EXPRESS_CHARGE_MODE: 'trade_delivery_express_charge_mode', // 快递的计费方式
  TRADE_AFTER_SALE_STATUS: 'trade_after_sale_status', // 售后 - 状态
  TRADE_AFTER_SALE_TYPE: 'trade_after_sale_type', // 售后 - 类型
  TRADE_AFTER_SALE_WAY: 'trade_after_sale_way', // 售后 - 方式
  TRADE_DELIVERY_TYPE: 'trade_delivery_type', // 配送方式
  TRADE_ORDER_ITEM_AFTER_SALE_STATUS: 'trade_order_item_after_sale_status', // 订单项 - 售后状态
  TRADE_ORDER_STATUS: 'trade_order_status', // 订单 - 状态
  TRADE_PAYMENT_PROOF_STATUS: 'trade_payment_proof_status', // 订单 - 收款状态（线下收款）
  TRADE_ORDER_TYPE: 'trade_order_type', // 订单 - 类型
  TRADE_ORDER_AUDIT_STATUS: 'trade_order_audit_status', // 交易订单 - 门店要货审核状态
  TRADE_ORDER_ITEM_ALLOC_MODE: 'trade_order_item_alloc_mode', // 交易订单行 - 分料方式（统配/直拨）
  TRADE_SETTLEMENT_MODE: 'trade_settlement_mode', // 门店 - 结算模式

  /** ========== MALL - 营销模块 ========== */

  PROMOTION_BANNER_POSITION: 'promotion_banner_position', // banner 定位
  PROMOTION_BARGAIN_RECORD_STATUS: 'promotion_bargain_record_status', // 砍价记录的状态
  PROMOTION_COMBINATION_RECORD_STATUS: 'promotion_combination_record_status', // 拼团记录的状态
  PROMOTION_CONDITION_TYPE: 'promotion_condition_type', // 营销的条件类型枚举
  PROMOTION_COUPON_STATUS: 'promotion_coupon_status', // 优惠劵的状态
  PROMOTION_COUPON_TAKE_TYPE: 'promotion_coupon_take_type', // 优惠劵的领取方式
  PROMOTION_COUPON_TEMPLATE_VALIDITY_TYPE:
    'promotion_coupon_template_validity_type', // 优惠劵模板的有限期类型
  PROMOTION_DISCOUNT_TYPE: 'promotion_discount_type', // 优惠类型
  PROMOTION_PRODUCT_SCOPE: 'promotion_product_scope', // 营销的商品范围
} as const;

/** ========== ERP - 企业资源计划模块 ========== */
const ERP_DICT = {
  ERP_AUDIT_STATUS: 'erp_audit_status', // ERP 审批状态
  ERP_STOCK_RECORD_BIZ_TYPE: 'erp_stock_record_biz_type', // 库存明细的业务类型
  ERP_STORE_TYPE: 'erp_store_type', // ERP 客户/门店 - 店型
  ERP_SUPPLIER_SETTLEMENT_TYPE: 'erp_supplier_settlement_type', // ERP 供应商 - 结账方式（月结 / 半月结 / 次结）
  ERP_SUPPLIER_INVOICE_MODE: 'erp_supplier_invoice_mode', // ERP 供应商 - 开票情况（全额 / 按比例 / 需加税点 / 不开）
  ERP_SUPPLIER_INVOICE_TYPE: 'erp_supplier_invoice_type', // ERP 供应商 - 开票类型（普票 / 专票）
} as const;

/** ========== FMS - 财务管理模块 ========== */
const FMS_DICT = {
  FMS_ACCOUNT_USER_LEVEL: 'fms_account_user_level', // FMS 账套用户权限级别
  FMS_SUBJECT_CATEGORY: 'fms_subject_category', // FMS 科目类别
  FMS_DEBIT_CREDIT_DIRECTION: 'fms_debit_credit_direction', // FMS 借贷方向
  FMS_FINANCE_INDICATOR_TYPE: 'fms_finance_indicator_type', // FMS 财务指标取数报表类型
  FMS_SUBJECT_TYPE: 'fms_subject_type', // FMS 科目类型
  FMS_AUXILIARY_TYPE: 'fms_auxiliary_type', // FMS 辅助核算类别
  FMS_VOUCHER_STATUS: 'fms_voucher_status', // FMS 凭证状态
  FMS_VOUCHER_TIDY_TYPE: 'fms_voucher_tidy_type', // FMS 凭证整理方式
  FMS_FORMULA_RULE: 'fms_formula_rule', // FMS 报表公式取数规则
  FMS_REPORT_TYPE: 'fms_report_type', // FMS 财务报表类型
  FMS_REPORT_PERIOD_TYPE: 'fms_report_period_type', // FMS 财务报表期间类型
  FMS_LEDGER_BALANCE_MODE: 'fms_ledger_balance_mode', // FMS 账簿余额方向模式
  FMS_ACCOUNTING_STANDARD: 'fms_accounting_standard', // FMS 会计制度
  FMS_CLOSING_TYPE: 'fms_closing_type', // FMS 结账方案类型
  FMS_CLOSING_TIME_TYPE: 'fms_closing_time_type', // FMS 结账取数期间
  FMS_CLOSING_VOUCHER_TYPE: 'fms_closing_voucher_type', // FMS 结账凭证类型
  FMS_CLOSING_TEMPLATE_CATEGORY: 'fms_closing_template_category', // FMS 结账模板分类
} as const;

/** ========== AI - 人工智能模块 ========== */
const AI_DICT = {
  AI_GENERATE_MODE: 'ai_generate_mode', // AI 生成模式
  AI_IMAGE_STATUS: 'ai_image_status', // AI 图片状态
  AI_MODEL_TYPE: 'ai_model_type', // AI 模型类型
  AI_MUSIC_STATUS: 'ai_music_status', // AI 音乐状态
  AI_PLATFORM: 'ai_platform', // AI 平台
  AI_WRITE_FORMAT: 'ai_write_format', // AI 写作格式
  AI_WRITE_LANGUAGE: 'ai_write_language', // AI 写作语言
  AI_WRITE_LENGTH: 'ai_write_length', // AI 写作长度
  AI_WRITE_TONE: 'ai_write_tone', // AI 写作语气
  AI_WRITE_TYPE: 'ai_write_type', // AI 写作类型
  AI_MCP_CLIENT_NAME: 'ai_mcp_client_name', // AI MCP Client 名字
} as const;

/** ========== WMS - 仓储管理模块 ========== */
const WMS_DICT = {
  WMS_MERCHANT_TYPE: 'merchant_type', // WMS 往来企业类型
  WMS_ORDER_TYPE: 'wms_order_type', // WMS 单据类型
  WMS_ORDER_STATUS: 'wms_order_status', // WMS 单据状态
  WMS_RECEIPT_ORDER_TYPE: 'wms_receipt_order_type', // WMS 入库单类型
  WMS_SHIPMENT_ORDER_TYPE: 'wms_shipment_order_type', // WMS 出库单类型
} as const;

/** 字典类型枚举 - 统一导出 */
const DICT_TYPE = {
  ...AI_DICT,
  ...BPM_DICT,
  ...ERP_DICT,
  ...FMS_DICT,
  ...INFRA_DICT,
  ...WMS_DICT,
  ...PAY_DICT,
  ...MALL_DICT,
  ...SYSTEM_DICT,
  ...COMMON_DICT,
} as const;

export { DICT_TYPE };
