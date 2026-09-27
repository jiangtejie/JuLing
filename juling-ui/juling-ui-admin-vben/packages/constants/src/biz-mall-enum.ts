// ========== MALL - 商品模块 ==========
/**
 * 商品 首页 日期类型
 */
export enum TimeRangeTypeEnum {
  DAY30 = 1,
  WEEK = 7,
  MONTH = 30,
  YEAR = 365,
}

/**
 * 商品 SPU 状态
 */
export const ProductSpuStatusEnum = {
  RECYCLE: {
    status: -1,
    name: '回收站',
  },
  DISABLE: {
    status: 0,
    name: '下架',
  },
  ENABLE: {
    status: 1,
    name: '上架',
  },
};

// ========== MALL - 营销模块 ==========
/**
 * 优惠劵模板的有限期类型的枚举
 */
export const CouponTemplateValidityTypeEnum = {
  DATE: {
    type: 1,
    name: '固定日期可用',
  },
  TERM: {
    type: 2,
    name: '领取之后可用',
  },
};

/**
 * 优惠劵模板的领取方式的枚举
 */
export const CouponTemplateTakeTypeEnum = {
  USER: {
    type: 1,
    name: '直接领取',
  },
  ADMIN: {
    type: 2,
    name: '指定发放',
  },
  REGISTER: {
    type: 3,
    name: '新人券',
  },
};

/**
 * 营销的商品范围枚举
 */
export const PromotionProductScopeEnum = {
  ALL: {
    scope: 1,
    name: '通用劵',
  },
  SPU: {
    scope: 2,
    name: '商品劵',
  },
  CATEGORY: {
    scope: 3,
    name: '品类劵',
  },
};

/**
 * 营销的条件类型枚举
 */
export const PromotionConditionTypeEnum = {
  PRICE: {
    type: 10,
    name: '满 N 元',
  },
  COUNT: {
    type: 20,
    name: '满 N 件',
  },
};

/**
 * 优惠类型枚举
 */
export const PromotionDiscountTypeEnum = {
  PRICE: {
    type: 1,
    name: '满减',
  },
  PERCENT: {
    type: 2,
    name: '折扣',
  },
};

// ========== MALL - 交易模块 ==========

/**
 * 配送方式枚举
 */
export const DeliveryTypeEnum = {
  EXPRESS: {
    type: 1,
    name: '快递发货',
  },
  PICK_UP: {
    type: 2,
    name: '到店自提',
  },
};
/**
 * 交易订单 - 状态
 */
export const TradeOrderStatusEnum = {
  UNPAID: {
    status: 0,
    name: '待支付',
  },
  UNDELIVERED: {
    status: 10,
    name: '待发货',
  },
  DELIVERED: {
    status: 20,
    name: '已发货',
  },
  COMPLETED: {
    status: 30,
    name: '已完成',
  },
  CANCELED: {
    status: 40,
    name: '已取消',
  },
};

/** 客服消息类型枚举类 */
export const KeFuMessageContentTypeEnum = {
  TEXT: 1, // 文本消息
  IMAGE: 2, // 图片消息
  VOICE: 3, // 语音消息
  VIDEO: 4, // 视频消息
  SYSTEM: 5, // 系统消息
  // ========== 商城特殊消息 ==========
  PRODUCT: 10, // 商品消息
  ORDER: 11, // 订单消息
};

/** Promotion 的 WebSocket 消息类型枚举类 */
export const WebSocketMessageTypeConstants = {
  KEFU_MESSAGE_TYPE: 'kefu_message_type', // 客服消息类型
  KEFU_MESSAGE_ADMIN_READ: 'kefu_message_read_status_change', // 客服消息管理员已读
};

// 预设颜色
export const PREDEFINE_COLORS = [
  '#ff4500',
  '#ff8c00',
  '#ffd700',
  '#90ee90',
  '#00ced1',
  '#1e90ff',
  '#c71585',
  '#409EFF',
  '#909399',
  '#C0C4CC',
  '#b7390b',
  '#ff7800',
  '#fad400',
  '#5b8c5f',
  '#00babd',
  '#1f73c3',
  '#711f57',
];
