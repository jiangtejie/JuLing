/**
 * 订单状态。
 *
 * `UNKNOWN`：后端返回了前端尚未识别的状态码（后端新增状态时的兜底）。
 * 语义中性，视图层必须按「处理中」这类中性文案展示，**绝不能**渲染成「已取消」。
 */
export type OrderStatus =
  'UNPAID' | 'PAID' | 'SHIPPED' | 'COMPLETED' | 'CANCELED' | 'AFTER_SALE' | 'UNKNOWN';

/**
 * 订单收款状态（后端 TradeOrderReceiveStatusEnum）：
 * 0 未上传凭证 / 1 凭证已提交待审核 / 2 已驳回 / 3 部分收款 / 4 已收齐。
 *
 * 门店提交凭证后订单直接进入「待发货」并自动提交两级审批，因此 1「待核验」不再下发
 * （字典项停用），保留在类型里只为兼容历史订单。
 */
export type ReceiveStatusCode = 0 | 1 | 2 | 3 | 4;

/**
 * 要货审核状态（后端 TradeOrderAuditStatusEnum）：0 待提交 / 10 审核中 / 20 已通过 / 30 已驳回。
 *
 * 展示纪律：门店侧**只给粗粒度结论**——不展示审批人、审批节点、当前在谁手里，
 * 文案也不出现具体岗位 / 人名（见 constants 的 AUDIT_STATUS_MAP）。
 */
export type OrderAuditStatus = 0 | 10 | 20 | 30;

/** 订单收货状态（后端 receiptStatus）：0 未收货 / 10 部分收货 / 20 已收货 */
export type OrderReceiptStatus = 0 | 10 | 20;

/** 店型（后端 erp_customer.store_type）：DIRECT 直营 / FRANCHISE 加盟（直营门店免审核闸门） */
export type StoreType = 'DIRECT' | 'FRANCHISE';

/** 付款凭证（线下转账的一次上传记录；驳回后重新上传会新增一条，历史保留） */
export interface PaymentProof {
  id: number;
  orderId: number;
  /** 凭证图片地址（多图） */
  urls: string[];
  /** 申报金额（单位：分） */
  amount: number;
  /** 审批认定的收款金额（单位：分），未认定时为空 */
  confirmedAmount?: number;
  payerName?: string;
  /** 收款渠道（字典 pay_channel_code 的线下值） */
  payChannelCode?: string;
  transferTime?: string | number;
  remark?: string;
  /** 单条凭证状态：0 待审核（上传即此值）/ 1 已认定（审批通过）/ 2 已驳回（审批驳回） */
  status: number;
  auditTime?: string | number;
  /** 审批意见（驳回原因） */
  auditRemark?: string;
  createTime: string | number;
}

/** 提交付款凭证参数 */
export interface PaymentProofCreateParam {
  orderId: number;
  urls: string[];
  /** 本次申报的收款金额（单位：分） */
  amount: number;
  payerName?: string;
  payChannelCode?: string;
  transferTime?: string;
  remark?: string;
}

/** 订单行项 */
export interface OrderItem {
  id: number;
  spuId: number;
  skuId: number;
  name: string;
  picUrl?: string;
  specText: string;
  price: number;
  quantity: number;
  /** 小计（单位：分） */
  totalPrice: number;
  /**
   * 门店订货链数量进度（后端 decimal，可能为 null / 字符串）。
   * 消费方统一按「Number(x) || 0」处理：
   * - deliveredCount：ERP 配送出库单审核后回写的已发货数量；
   * - receiptCount：门店在 H5 确认的实收数量。
   */
  deliveredCount?: number | string | null;
  receiptCount?: number | string | null;
}

/** 订单 */
export interface Order {
  id: number;
  orderNo: string;
  status: OrderStatus;
  /** 订单总额（单位：分） */
  totalPrice: number;
  /** 优惠金额（单位：分） */
  discountPrice?: number;
  /** 实付金额（单位：分） */
  payPrice: number;
  /** 已确认收款金额（单位：分，线下收款累计） */
  paidAmount: number;
  /** 收款状态（0-4，见 ReceiveStatusCode） */
  paymentProofStatus: ReceiveStatusCode;
  /** 运费（单位：分） */
  freightPrice?: number;
  receiverName?: string;
  receiverMobile?: string;
  receiverAddress?: string;
  remark?: string;
  createTime: string | number;
  payTime?: string | number;
  deliveryTime?: string | number;
  /** 完成时间（后端 finishTime，订单「已完成」节点的时间） */
  finishTime?: string | number;
  items: OrderItem[];
  /* ---------------------- 门店订货链：归属 · 审核 · 收货 ---------------------- */
  /** 下单门店（客户）编号；代理人账号管多家门店，订单只快照 customerId */
  customerId?: number | null;
  /** 下单门店名称（后端补客户主数据，可能为空） */
  customerName?: string | null;
  /** 店型（DIRECT 直营 / FRANCHISE 加盟） */
  storeType?: string | null;
  /** 要货审核状态（OrderAuditStatus）；后端未下发时为 null，按「待提交」展示 */
  auditStatus?: number | null;
  /** 审核意见（驳回原因），仅详情接口下发 */
  auditRemark?: string | null;
  /** 收货状态（OrderReceiptStatus），仅详情接口下发 */
  receiptStatus?: number | null;
}

/** 可下单门店（门店订货链：账号的**授权门店**，一家店或多家的片区订货管理人） */
export interface StoreOption {
  customerId: number;
  customerName: string;
  settlementMode?: string;
  /** 店型（DIRECT 直营 / FRANCHISE 加盟），后端已有则透传 */
  storeType?: string | null;
  /** 是否账号的默认门店：H5 首次进入用它 */
  isDefault?: boolean;
}

/** 创建订单参数 */
export interface OrderCreateParam {
  items: Array<{ skuId: number; quantity: number }>;
  receiverName: string;
  receiverMobile: string;
  receiverAddress: string;
  remark?: string;
  /** 下单门店客户编号（不传则用账号绑定门店） */
  storeCustomerId?: number;
}
