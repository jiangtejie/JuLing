/**
 * 后端 app 端 DTO 类型。
 *
 * 与 `juling-module-mall` / `juling-module-member` 的 App 端 Response VO 一一对应，
 * 字段名以后端为准（驼峰）。时间字段经 `TimestampLocalDateTimeSerializer` 序列化，
 * 默认输出毫秒时间戳（Long）；个别字段若带 `@JsonFormat(pattern)` 则输出格式化字符串，
 * 故统一声明为 `BackendDateTime = number | string`。
 *
 * 业务代码**不直接消费**这些类型——由 `src/api/adapters/*` 转换为前端领域模型。
 */

/** 后端时间字段：毫秒时间戳（number）或格式化字符串 */
export type BackendDateTime = number | string;

/** 后端统一分页响应 */
export interface BackendPage<T> {
  list: T[];
  total: number;
}

/* --------------------------------- 商品 --------------------------------- */

/** 用户 App - 商品 SPU 列表项（GET /product/spu/page） */
export interface AppProductSpuRespVO {
  id: number;
  name: string;
  /** 商品简介（前端用作 subTitle） */
  introduction: string;
  categoryId: number;
  picUrl: string;
  sliderPicUrls: string[];
  specType: boolean;
  /** 价格，单位：分 */
  price: number;
  /** 市场价，单位：分 */
  marketPrice: number;
  stock: number;
  salesCount: number;
  /** 支持的配送方式（DeliveryTypeEnum：1 快递 / 2 自提） */
  deliveryTypes: number[];
}

/** 商品属性值明细 */
export interface AppProductPropertyValueDetailRespVO {
  propertyId: number;
  propertyName: string;
  valueId: number;
  valueName: string;
}

/** 商品 SKU 明细（内嵌于 SPU 详情；无 name / 无阶梯价 / 无起订量） */
export interface AppProductSkuDetailRespVO {
  id: number;
  /** 商品属性数组（前端需转为 Record<属性名, 属性值>） */
  properties: AppProductPropertyValueDetailRespVO[];
  /** 销售价，单位：分 */
  price: number;
  marketPrice: number;
  /** VIP 价，单位：分 */
  vipPrice: number;
  picUrl: string;
  stock: number;
  /** 重量，kg */
  weight: number;
  /** 体积，m^3 */
  volume: number;
}

/** 用户 App - 商品 SPU 详情（GET /product/spu/get-detail） */
export interface AppProductSpuDetailRespVO {
  id: number;
  name: string;
  introduction: string;
  /** 商品详情 HTML（前端用作 detailHtml） */
  description: string;
  categoryId: number;
  picUrl: string;
  sliderPicUrls: string[];
  specType: boolean;
  price: number;
  marketPrice: number;
  stock: number;
  skus: AppProductSkuDetailRespVO[];
  salesCount: number;
}

/** 用户 App - 商品分类（GET /product/category/list） */
export interface AppCategoryRespVO {
  id: number;
  parentId: number;
  name: string;
  picUrl: string;
}

/* --------------------------------- 会员 --------------------------------- */

/** 登录响应（POST /member/auth/login、/sms-login） */
export interface AppAuthLoginRespVO {
  userId: number;
  accessToken: string;
  refreshToken: string;
  /** 过期时间（毫秒时间戳） */
  expiresTime: BackendDateTime;
  openid: string | null;
}

/** 会员等级 */
export interface AppMemberUserLevelRespVO {
  id: number;
  name: string;
  level: number;
  icon: string;
}

/** 会员信息（GET /member/user/get） */
export interface AppMemberUserInfoRespVO {
  id: number;
  nickname: string;
  avatar: string;
  mobile: string;
  email: string;
  /** 性别 */
  sex: number;
  point: number;
  experience: number;
  level: AppMemberUserLevelRespVO | null;
  brokerageEnabled: boolean;
}

/* -------------------------------- 购物车 -------------------------------- */

/** 商品 SPU 基础信息（购物车内嵌） */
export interface AppProductSpuBaseRespVO {
  id: number;
  name: string;
  picUrl: string;
  categoryId: number;
  stock: number;
  status: number;
}

/** 商品 SKU 基础信息（购物车内嵌；无 name、无阶梯价、无起订量） */
export interface AppProductSkuBaseRespVO {
  id: number;
  picUrl: string;
  price: number;
  stock: number;
  properties: AppProductPropertyValueDetailRespVO[];
}

/** 购物车行项（AppCartListRespVO.Cart） */
export interface AppCartItemRespVO {
  id: number;
  /** 数量（前端用作 quantity） */
  count: number;
  selected: boolean;
  spu: AppProductSpuBaseRespVO | null;
  sku: AppProductSkuBaseRespVO | null;
}

/** 购物车列表（GET /trade/cart/list） */
export interface AppCartListRespVO {
  validList: AppCartItemRespVO[];
  invalidList: AppCartItemRespVO[];
}

/* ------------------------------- 交易订单 ------------------------------- */

/** 订单项（AppTradeOrderItemRespVO，独立顶层类） */
export interface AppTradeOrderItemRespVO {
  id: number;
  orderId: number;
  spuId: number;
  /** 商品名（前端用作 name） */
  spuName: string;
  skuId: number;
  properties: AppProductPropertyValueDetailRespVO[];
  picUrl: string;
  /** 购买数量（前端用作 quantity） */
  count: number;
  commentStatus: boolean;
  price: number;
  payPrice: number;
  afterSaleId: number | null;
  afterSaleStatus: number | null;
}

/** 订单分页项（GET /trade/order/page） */
export interface AppTradeOrderPageItemRespVO {
  id: number;
  /** 订单号（前端用作 orderNo） */
  no: string;
  type: number;
  /** 订单状态（TradeOrderStatusEnum：0/10/20/30/40） */
  status: number;
  productCount: number;
  commentStatus: boolean;
  createTime: BackendDateTime;
  payOrderId: number | null;
  payPrice: number;
  deliveryType: number;
  items: AppTradeOrderItemRespVO[];
  combinationRecordId: number | null;
}

/** 订单详情（GET /trade/order/get-detail） */
export interface AppTradeOrderDetailRespVO {
  id: number;
  /** 订单号（前端用作 orderNo） */
  no: string;
  type: number;
  createTime: BackendDateTime;
  /** 买家备注（前端用作 remark） */
  userRemark: string;
  /** 订单状态（TradeOrderStatusEnum） */
  status: number;
  productCount: number;
  finishTime: BackendDateTime | null;
  cancelTime: BackendDateTime | null;
  commentStatus: boolean;
  payStatus: boolean;
  payOrderId: number | null;
  payTime: BackendDateTime | null;
  payExpireTime: BackendDateTime | null;
  payChannelCode: string;
  payChannelName: string;
  totalPrice: number;
  discountPrice: number;
  /** 运费（前端用作 freightPrice） */
  deliveryPrice: number;
  adjustPrice: number;
  payPrice: number;
  deliveryType: number;
  logisticsId: number | null;
  logisticsName: string;
  logisticsNo: string;
  deliveryTime: BackendDateTime | null;
  receiveTime: BackendDateTime | null;
  receiverName: string;
  receiverMobile: string;
  receiverAreaId: number | null;
  receiverAreaName: string;
  receiverDetailAddress: string;
  pickUpStoreId: number | null;
  pickUpVerifyCode: string | null;
  refundStatus: number | null;
  refundPrice: number | null;
  couponId: number | null;
  couponPrice: number;
  pointPrice: number;
  vipPrice: number;
  combinationRecordId: number | null;
  items: AppTradeOrderItemRespVO[];
}

/** 创建订单响应（POST /trade/order/create） */
export interface AppTradeOrderCreateRespVO {
  id: number;
  payOrderId: number;
}

/** 创建订单请求项 */
export interface AppTradeOrderCreateItemReqVO {
  skuId: number;
  /** 购买数量 */
  count: number;
  /** 购物车项编号（可选，与 skuId+count 二选一） */
  cartId?: number;
}

/** 创建订单请求体（AppTradeOrderCreateReqVO extends AppTradeOrderSettlementReqVO） */
export interface AppTradeOrderCreateReqVO {
  items: AppTradeOrderCreateItemReqVO[];
  /** 是否使用积分（必填 @NotNull） */
  pointStatus: boolean;
  /** 配送方式（必填，DeliveryTypeEnum：1 快递 / 2 自提） */
  deliveryType: number;
  receiverName?: string;
  receiverMobile?: string;
  receiverAreaName?: string;
  receiverDetailAddress?: string;
  addressId?: number;
  remark?: string;
}
