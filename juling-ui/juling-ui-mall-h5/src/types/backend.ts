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
  /** 手机号（会员手机号已非必填，可能为空） */
  mobile?: string | null;
  /** 订货账号（订货人的登录名，就是订货人姓名；旧数据可能不返回） */
  username?: string | null;
  email: string;
  /** 性别 */
  sex: number;
  point: number;
  experience: number;
  level: AppMemberUserLevelRespVO | null;
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
  /** 已确认收款金额（单位：分） */
  paidAmount?: number;
  /** 收款状态（TradeOrderReceiveStatusEnum） */
  paymentProofStatus?: number;
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
  /** 已确认收款金额（单位：分） */
  paidAmount?: number;
  /** 收款状态（TradeOrderReceiveStatusEnum） */
  paymentProofStatus?: number;
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

/** 付款凭证（GET /trade/order/payment-proof/list） */
export interface AppTradeOrderPaymentProofRespVO {
  id: number;
  orderId: number;
  urls: string[];
  amount: number;
  confirmedAmount: number | null;
  payerName: string | null;
  payChannelCode: string | null;
  transferTime: BackendDateTime | null;
  remark: string | null;
  /** 0 待核验 / 1 已确认 / 2 已驳回 */
  status: number;
  auditTime: BackendDateTime | null;
  auditRemark: string | null;
  createTime: BackendDateTime;
}

/** 提交付款凭证请求体（POST /trade/order/payment-proof/create） */
export interface AppTradeOrderPaymentProofCreateReqVO {
  orderId: number;
  urls: string[];
  /** 申报收款金额（单位：分） */
  amount: number;
  payerName?: string;
  payChannelCode?: string;
  transferTime?: string;
  remark?: string;
}

/** 创建订单请求体（AppTradeOrderCreateReqVO extends AppTradeOrderSettlementReqVO） */
export interface AppTradeOrderCreateReqVO {
  items: AppTradeOrderCreateItemReqVO[];
  /** 是否使用积分（必填 @NotNull） */
  pointStatus: boolean;
  /** 配送方式（必填，DeliveryTypeEnum：1 快递发货） */
  deliveryType: number;
  receiverName?: string;
  receiverMobile?: string;
  receiverAreaName?: string;
  receiverDetailAddress?: string;
  addressId?: number;
  remark?: string;
  /** 下单门店客户编号（门店订货链 S1：代理账号切换门店时传） */
  storeCustomerId?: number;
}

/* ------------------------------- 门店收货 ------------------------------- */

/**
 * 门店收货单分页项（GET /trade/order/store-receipt/pending-page）。
 * 配送出库单审核通过后由后端生成，门店在 H5 逐行确认实收。
 */
export interface AppTradeStoreReceiptPageItemRespVO {
  id: number;
  /** 收货单号 */
  no: string;
  orderId: number;
  orderNo: string;
  customerName: string;
  /** 应收数量合计 */
  totalCount: number;
  /** 应收金额合计（单位：分） */
  totalPrice: number;
  receiveTime: BackendDateTime | null;
  /** 配送出库单号 */
  saleOutNo: string;
  /** 状态（TradeStoreReceiptStatusEnum：0 待确认 / 10 已确认 / 20 已作废） */
  status: number;
  statusName: string;
  /** 差异类型（0 无差异 / 1 少收 / 2 多收 / 3 破损 / 4 混合） */
  diffType: number;
  diffTypeName: string;
}

/** 门店收货单行项（AppTradeStoreReceiptItemRespVO） */
export interface AppTradeStoreReceiptItemRespVO {
  id: number;
  /** 原订单行编号（提交实收数量时按它回填） */
  orderItemId: number;
  spuId: number;
  skuId: number;
  spuName: string;
  /** 规格文本（后端为 varchar 快照，老数据可能是属性数组，由 adapter 兼容） */
  properties: string;
  picUrl: string;
  /** ERP 商品编号 / 名称 */
  productId: number;
  productName: string;
  /** 配送价（门店进货单价，单位：分） */
  price: number;
  /** 应收数量（来自配送出库单） */
  expectCount: number;
  receiptCount: number;
  /** 差异数量（实收 − 应收，正数=多收） */
  diffCount: number;
  /** 差异金额（单位：分） */
  diffAmount: number;
  diffReason: string | null;
  batchNo: string | null;
  productionDate: BackendDateTime | null;
  expiryDate: BackendDateTime | null;
}

/** 门店收货单详情（GET /trade/order/store-receipt/get?orderId=） */
export interface AppTradeStoreReceiptRespVO {
  id: number;
  no: string;
  orderId: number;
  orderNo: string;
  customerName: string;
  saleOutNo: string;
  status: number;
  statusName: string;
  /** 差异类型（0 无差异 / 1 少收 / 2 多收 / 3 破损 / 4 混合） */
  diffType: number;
  diffTypeName: string;
  totalCount: number;
  receiptCount: number;
  diffCount: number;
  /** 应收金额合计（单位：分） */
  totalPrice: number;
  /** 实收金额合计（单位：分） */
  receiptPrice: number;
  /** 差异金额（单位：分） */
  diffAmount: number;
  receiverName: string | null;
  receiverMobile: string | null;
  /**
   * 收货凭证图片。
   *
   * 注意：后端 app 端 VO 下发的是 **JSON 数组字符串**（trade_order_receipt.file_urls
   * 是文本列，落库时 JsonUtils.toJsonString），并非数组；adapter 统一归一为 string[]。
   */
  fileUrls: string | string[] | null;
  remark: string | null;
  receiveTime: BackendDateTime | null;
  items: AppTradeStoreReceiptItemRespVO[];
}

/** 门店收货请求项（只提交实收数量与差异原因，应收/差异由后端按出库单核对） */
export interface AppTradeStoreReceiptCreateItemReqVO {
  orderItemId: number;
  /** 实收数量 */
  receiptCount: number;
  /** 差异原因（实收 ≠ 应收时必填） */
  diffReason?: string;
}

/** 提交门店收货请求体（POST /trade/order/store-receipt/create） */
export interface AppTradeStoreReceiptCreateReqVO {
  orderId: number;
  receiverName?: string;
  receiverMobile?: string;
  fileUrls?: string[];
  remark?: string;
  items: AppTradeStoreReceiptCreateItemReqVO[];
}
