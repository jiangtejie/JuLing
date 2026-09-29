/** 本地存储 key（最终会拼接 appConfig.storagePrefix 前缀） */
export const STORAGE_KEYS = {
  TOKEN: 'token',
  REFRESH_TOKEN: 'refresh-token',
  USER_INFO: 'user-info',
  CART: 'cart',
  CURRENT_STORE: 'current-store',
} as const;

/**
 * 门店要货审核状态展示配置（后端 TradeOrderAuditStatusEnum：DRAFT/PROCESS/APPROVE/REJECT）。
 *
 * 展示纪律：门店侧**只给粗粒度结论**——不展示审批人、审批节点、当前在谁手里；
 * 文案只用中性词（待提交 / 审核中 / 已通过 / 已驳回），不出现具体岗位或人名。
 * 后端未下发（null）时按「待提交」展示（后端 TradeOrderAuditStatusEnum.isDraft 同口径）。
 */
export const AUDIT_STATUS_MAP: Record<number, { text: string; color: string }> = {
  0: { text: '待提交', color: 'var(--app-text-color-secondary)' },
  10: { text: '审核中', color: 'var(--app-warning-color)' },
  20: { text: '已通过', color: 'var(--app-success-color)' },
  30: { text: '已驳回', color: 'var(--app-danger-color)' },
};

/**
 * 审核轻标记：列表卡片只给「需要门店关注」的两态，
 * 已通过 / 待提交不挂标签，避免每张卡片都多一个无信息量的角标（也不占用主状态位）。
 */
export const AUDIT_TAG_STATUSES: readonly number[] = [10, 30];

/** 店型展示配置（后端 erp_customer.store_type；直营门店免审核闸门） */
export const STORE_TYPE_MAP: Record<string, string> = {
  DIRECT: '直营',
  FRANCHISE: '加盟',
};

/** 订单收货状态展示配置（后端 receiptStatus：0 未收货 / 10 部分收货 / 20 已收货） */
export const ORDER_RECEIPT_STATUS_MAP: Record<number, { text: string; color: string }> = {
  0: { text: '未收货', color: 'var(--app-text-color-secondary)' },
  10: { text: '部分收货', color: 'var(--app-warning-color)' },
  20: { text: '已收货', color: 'var(--app-success-color)' },
};

/**
 * 订单状态展示配置（色值统一引用 CSS 变量，跟随主题换肤）。
 *
 * `UNKNOWN`：后端下发了前端未识别的状态码时的兜底，文案必须是中性词
 * （不能用「已取消」之类会误导门店的结论）。
 */
export const ORDER_STATUS_MAP = {
  UNPAID: { text: '待付款', type: 'danger', color: 'var(--app-danger-color)' },
  PAID: { text: '待发货', type: 'warning', color: 'var(--app-warning-color)' },
  SHIPPED: { text: '待收货', type: 'primary', color: 'var(--app-primary-color)' },
  COMPLETED: { text: '已完成', type: 'success', color: 'var(--app-success-color)' },
  CANCELED: { text: '已取消', type: 'default', color: 'var(--app-text-color-secondary)' },
  AFTER_SALE: { text: '售后中', type: 'default', color: 'var(--app-text-color-secondary)' },
  UNKNOWN: { text: '处理中', type: 'default', color: 'var(--app-text-color-secondary)' },
} as const;

/**
 * 订单收款状态展示配置（后端 TradeOrderReceiveStatusEnum，订单维度）。
 *
 * 门店提交付款凭证后**直接进入**供应链 / 财务两级审批（不再有后台人工核验收款，
 * 核收款的职责由财务审批节点承接）：未上传凭证 → 凭证已提交，待审核 →
 * 部分收款 / 已收齐（审批驳回后可重新上传，后端会自动再次提交审批）。
 *
 * 注：1「待核验」后端已不再下发（该字典项停用），这里保留字面仅作历史订单兜底。
 */
export const RECEIVE_STATUS_MAP: Record<number, { text: string; color: string }> = {
  0: { text: '待上传凭证', color: 'var(--app-danger-color)' },
  1: { text: '凭证已提交，待审核', color: 'var(--app-warning-color)' },
  2: { text: '凭证已驳回', color: 'var(--app-danger-color)' },
  3: { text: '部分收款', color: 'var(--app-warning-color)' },
  4: { text: '已收齐', color: 'var(--app-success-color)' },
};

/**
 * 单条付款凭证状态（后端 TradeOrderPaymentProofStatusEnum）。
 * 上传即「待审核」；审批通过置「已认定」（confirmed_amount = 申报金额），驳回置「已驳回」。
 */
export const PROOF_STATUS_MAP: Record<number, { text: string; color: string }> = {
  0: { text: '待审核', color: 'var(--app-warning-color)' },
  1: { text: '已认定', color: 'var(--app-success-color)' },
  2: { text: '已驳回', color: 'var(--app-danger-color)' },
};

/**
 * 门店收货单状态展示配置（后端 TradeStoreReceiptStatusEnum）。
 * 门店订货链 S2：配送出库 → 门店逐行确认实收（多收 / 少收 / 破损）。
 */
export const RECEIPT_STATUS_MAP: Record<number, { text: string; color: string }> = {
  0: { text: '待确认', color: 'var(--app-warning-color)' },
  10: { text: '已确认', color: 'var(--app-success-color)' },
  20: { text: '已作废', color: 'var(--app-text-color-secondary)' },
};

/** 收货差异类型展示配置（后端 diff_type：0 无差异 / 1 少收 / 2 多收 / 3 破损 / 4 混合） */
export const RECEIPT_DIFF_TYPE_MAP: Record<number, { text: string; color: string }> = {
  0: { text: '无差异', color: 'var(--app-success-color)' },
  1: { text: '少收', color: 'var(--app-danger-color)' },
  2: { text: '多收', color: 'var(--app-warning-color)' },
  3: { text: '破损', color: 'var(--app-danger-color)' },
  4: { text: '混合', color: 'var(--app-warning-color)' },
};

/**
 * 行级差异类型可选项。
 * 少收 / 多收由「实收 − 应收」自动预选，破损需要门店人工选择（数量上看不出来）。
 */
export const RECEIPT_DIFF_TYPE_OPTIONS = [
  { value: 1, label: '少收' },
  { value: 2, label: '多收' },
  { value: 3, label: '破损' },
] as const;

/** 线下收款渠道（字典 pay_channel_code 中的线下部分） */
export const OFFLINE_PAY_CHANNELS = [
  { code: 'offline_transfer', name: '银行转账' },
  { code: 'offline_wx', name: '微信转账' },
  { code: 'offline_alipay', name: '支付宝转账' },
  { code: 'offline_cash', name: '现金' },
] as const;

/** 订单状态筛选项 */
export const ORDER_TABS = [
  { key: 'all', title: '全部' },
  { key: 'UNPAID', title: '待付款' },
  { key: 'PAID', title: '待发货' },
  { key: 'SHIPPED', title: '待收货' },
  { key: 'COMPLETED', title: '已完成' },
] as const;

/**
 * 订单正向流转步骤（用于订单详情的步骤条）。
 * 注意：不含「已取消 / 售后中」——它们不是正向流程，用步骤条表达会误导。
 */
export const ORDER_STATUS_STEPS = [
  { key: 'UNPAID', text: '待付款' },
  { key: 'PAID', text: '待发货' },
  { key: 'SHIPPED', text: '待收货' },
  { key: 'COMPLETED', text: '已完成' },
] as const;

/** 默认分页大小 */
export const DEFAULT_PAGE_SIZE = 10;
