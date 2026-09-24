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
