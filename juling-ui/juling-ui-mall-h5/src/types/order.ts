/** 订单状态 */
export type OrderStatus = 'UNPAID' | 'PAID' | 'SHIPPED' | 'COMPLETED' | 'CANCELED' | 'AFTER_SALE';

/** 订单收款状态（后端 TradeOrderReceiveStatusEnum）：0 未上传凭证 / 1 待核验 / 2 已驳回 / 3 部分收款 / 4 已收齐 */
export type ReceiveStatusCode = 0 | 1 | 2 | 3 | 4;

/** 付款凭证（线下转账的一次上传记录；驳回后重新上传会新增一条，历史保留） */
export interface PaymentProof {
  id: number;
  orderId: number;
  /** 凭证图片地址（多图） */
  urls: string[];
  /** 申报金额（单位：分） */
  amount: number;
  /** 后台核定的收款金额（单位：分），未核验时为空 */
  confirmedAmount?: number;
  payerName?: string;
  /** 收款渠道（字典 pay_channel_code 的线下值） */
  payChannelCode?: string;
  transferTime?: string | number;
  remark?: string;
  /** 单条凭证状态：0 待核验 / 1 已确认 / 2 已驳回 */
  status: number;
  auditTime?: string | number;
  /** 核验意见（驳回原因） */
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
  items: OrderItem[];
}

/** 创建订单参数 */
export interface OrderCreateParam {
  items: Array<{ skuId: number; quantity: number }>;
  receiverName: string;
  receiverMobile: string;
  receiverAddress: string;
  remark?: string;
}
