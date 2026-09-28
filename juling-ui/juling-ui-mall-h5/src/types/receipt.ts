/**
 * 门店收货（配送出库后门店确认实收）领域模型。
 *
 * 与后端 trade_order_receipt / trade_order_receipt_item 对应，
 * 由 src/api/adapters/receipt.ts 从 App 端 DTO 转换而来。
 */

/** 收货单状态（后端 TradeStoreReceiptStatusEnum）：0 待确认 / 10 已确认 / 20 已作废 */
export type StoreReceiptStatus = 0 | 10 | 20;

/** 差异类型（后端 diff_type）：0 无差异 / 1 少收 / 2 多收 / 3 破损 / 4 混合 */
export type StoreReceiptDiffType = 0 | 1 | 2 | 3 | 4;

/** 待收货列表项（分页项，字段少于详情） */
export interface StoreReceiptSummary {
  id: number;
  /** 收货单号 */
  no: string;
  orderId: number;
  orderNo: string;
  /** 门店（客户）名称 */
  customerName: string;
  /** 应收数量合计 */
  totalCount: number;
  /** 应收金额合计（单位：分） */
  totalPrice: number;
  /** 确认收货时间，待确认时为空 */
  receiveTime?: string | number;
  /** 配送出库单号 */
  saleOutNo: string;
  status: StoreReceiptStatus;
  /** 后端下发的状态文案（未知码时兜底展示） */
  statusName: string;
  diffType: StoreReceiptDiffType;
  diffTypeName: string;
}

/** 收货单行项 */
export interface StoreReceiptItem {
  id: number;
  /** 原订单行编号：提交实收数量时作为行的唯一标识 */
  orderItemId: number;
  spuId: number;
  skuId: number;
  /** 商品名（后端 spuName） */
  name: string;
  /** 规格文本 */
  specText: string;
  picUrl?: string;
  productId: number;
  /** ERP 商品名，用于门店核对品名 */
  productName: string;
  /** 配送价（单位：分） */
  price: number;
  /** 应收数量（配送出库单行数量） */
  expectCount: number;
  receiptCount: number;
  /** 差异数量（实收 − 应收，正数=多收） */
  diffCount: number;
  /** 差异金额（单位：分） */
  diffAmount: number;
  diffReason?: string;
  batchNo?: string;
  productionDate?: string | number;
  expiryDate?: string | number;
}

/** 收货单详情 */
export interface StoreReceipt {
  id: number;
  no: string;
  orderId: number;
  orderNo: string;
  customerName: string;
  saleOutNo: string;
  status: StoreReceiptStatus;
  statusName: string;
  /** 收货单级差异类型（已确认后由后端按行差异汇总：少收 / 多收 / 破损 / 混合） */
  diffType: StoreReceiptDiffType;
  diffTypeName: string;
  /** 应收数量 / 实收数量 / 差异数量 */
  totalCount: number;
  receiptCount: number;
  diffCount: number;
  /** 应收金额 / 实收金额 / 差异金额（单位：分） */
  totalPrice: number;
  receiptPrice: number;
  diffAmount: number;
  receiverName?: string;
  receiverMobile?: string;
  /** 收货照片 */
  fileUrls: string[];
  remark?: string;
  receiveTime?: string | number;
  items: StoreReceiptItem[];
}

/** 提交收货参数：逐行回填实收数量，有差异的行必须带原因 */
export interface StoreReceiptCreateParam {
  orderId: number;
  receiverName?: string;
  receiverMobile?: string;
  fileUrls?: string[];
  remark?: string;
  items: Array<{
    orderItemId: number;
    /** 实收数量 */
    receiptCount: number;
    /** 差异原因（实收 = 应收时可省略） */
    diffReason?: string;
  }>;
}
