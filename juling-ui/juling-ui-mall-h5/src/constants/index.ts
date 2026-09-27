/** 本地存储 key（最终会拼接 appConfig.storagePrefix 前缀） */
export const STORAGE_KEYS = {
  TOKEN: 'token',
  REFRESH_TOKEN: 'refresh-token',
  USER_INFO: 'user-info',
  CART: 'cart',
  SEARCH_HISTORY: 'search-history',
} as const;

/** 订单状态展示配置（色值统一引用 CSS 变量，跟随主题换肤） */
export const ORDER_STATUS_MAP = {
  UNPAID: { text: '待付款', type: 'danger', color: 'var(--app-danger-color)' },
  PAID: { text: '待发货', type: 'warning', color: 'var(--app-warning-color)' },
  SHIPPED: { text: '待收货', type: 'primary', color: 'var(--app-primary-color)' },
  COMPLETED: { text: '已完成', type: 'success', color: 'var(--app-success-color)' },
  CANCELED: { text: '已取消', type: 'default', color: 'var(--app-text-color-secondary)' },
  AFTER_SALE: { text: '售后中', type: 'default', color: 'var(--app-text-color-secondary)' },
} as const;

/**
 * 订单收款状态展示配置（后端 TradeOrderReceiveStatusEnum，订单维度）。
 * 线下收款流程：未上传凭证 → 待核验 → 部分收款 / 已收齐（驳回后可重传）。
 */
export const RECEIVE_STATUS_MAP: Record<number, { text: string; color: string }> = {
  0: { text: '待上传凭证', color: 'var(--app-danger-color)' },
  1: { text: '凭证待核验', color: 'var(--app-warning-color)' },
  2: { text: '凭证已驳回', color: 'var(--app-danger-color)' },
  3: { text: '部分收款', color: 'var(--app-warning-color)' },
  4: { text: '已收齐', color: 'var(--app-success-color)' },
};

/** 单条付款凭证状态（后端 TradeOrderPaymentProofStatusEnum） */
export const PROOF_STATUS_MAP: Record<number, { text: string; color: string }> = {
  0: { text: '待核验', color: 'var(--app-warning-color)' },
  1: { text: '已确认', color: 'var(--app-success-color)' },
  2: { text: '已驳回', color: 'var(--app-danger-color)' },
};

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
