import type { PageParam, PageResult } from '@vben/request';

import { requestClient } from '#/api/request';

export namespace TradeStoreReceiptApi {
  /** 门店收货单（表头） */
  export interface StoreReceipt {
    id?: number; // 收货单编号
    no?: string; // 收货单号
    orderId?: number; // 要货单（交易订单）编号
    orderNo?: string; // 要货单号
    customerId?: number; // 门店客户编号
    customerName?: string; // 门店名称
    deptId?: number; // 门店所属部门编号
    deptName?: string; // 门店所属部门名称
    warehouseId?: number; // 收货门店仓编号
    warehouseName?: string; // 收货门店仓名称
    saleOutId?: number; // 来源配送出库单编号
    saleOutNo?: string; // 来源配送出库单号
    status?: number; // 状态：0 待确认 / 10 已确认 / 20 已作废
    statusName?: string; // 状态名称（后端直接返回中文）
    diffType?: number; // 差异类型：0 无差异 / 1 少收 / 2 多收 / 3 破损 / 4 混合
    diffTypeName?: string; // 差异类型名称（后端直接返回中文）
    totalCount?: number; // 应收合计
    receiptCount?: number; // 实收合计
    diffCount?: number; // 差异合计（实收 − 应收，正数 = 多收）
    totalPrice?: number; // 应收金额合计，单位：元
    receiptPrice?: number; // 实收金额合计，单位：元
    diffAmount?: number; // 差异金额合计，单位：元
    // LocalDateTime 在后端可能被序列化成时间戳（毫秒）或字符串，展示统一走 formatDateTime
    receiveTime?: number | string; // 收货时间
    receiverName?: string; // 收货人
    receiverMobile?: string; // 收货人手机
    fileUrls?: string[] | string; // 收货凭证图片地址（后端 text 列，数组或逗号串）
    remark?: string; // 备注
    cancelReason?: string; // 作废原因
    createTime?: number | string; // 创建时间
    creatorName?: string; // 创建人
    items?: StoreReceiptItem[]; // 明细行（仅详情接口返回）
  }

  /** 门店收货单明细行 */
  export interface StoreReceiptItem {
    id?: number; // 明细行编号
    orderItemId?: number; // 要货单行编号
    spuId?: number; // 商品 SPU 编号
    skuId?: number; // 商品 SKU 编号
    spuName?: string; // 商品名称
    properties?: string; // 规格属性
    picUrl?: string; // 商品图片
    productId?: number; // ERP 物料编号
    productName?: string; // ERP 物料名称
    price?: number; // 配送价（门店进货单价），单位：元
    expectCount?: number; // 应收数量
    receiptCount?: number; // 实收数量
    diffCount?: number; // 差异数量（实收 − 应收，正数 = 多收）
    diffAmount?: number; // 差异金额，单位：元
    diffReason?: string; // 差异原因
    batchNo?: string; // 批次号
    // LocalDate 会被后端序列化成数组（如 [2026,9,25]），展示前必须过 formatBatchDate
    productionDate?: number[] | string; // 生产日期
    expiryDate?: number[] | string; // 有效期
    remark?: string; // 备注
  }

  /** 门店收货单分页查询参数 */
  export interface StoreReceiptPageReqVO extends PageParam {
    no?: string; // 收货单号（模糊）
    orderNo?: string; // 要货单号（模糊）
    customerId?: number; // 门店客户编号
    deptId?: number; // 门店所属部门编号
    status?: number; // 状态：0 待确认 / 10 已确认 / 20 已作废
    diffType?: number; // 差异类型
    receiveTime?: string[]; // 收货时间区间，格式 yyyy-MM-dd HH:mm:ss
  }

  /** 后台代录明细行 */
  export interface StoreReceiptItemCreateReqVO {
    orderItemId: number; // 要货单行编号
    receiptCount: number; // 实收数量
    diffReason?: string; // 差异原因
    batchNo?: string; // 批次号
    productionDate?: string; // 生产日期 yyyy-MM-dd
    expiryDate?: string; // 有效期 yyyy-MM-dd
  }

  /** 后台代录收货单 */
  export interface StoreReceiptCreateReqVO {
    orderId: number; // 要货单（交易订单）编号
    receiverName?: string; // 收货人
    receiverMobile?: string; // 收货人手机
    fileUrls?: string[]; // 收货凭证图片地址
    remark?: string; // 备注
    items: StoreReceiptItemCreateReqVO[]; // 明细行
  }

  /** 门店库存汇总（门店仓维度） */
  export interface StoreStockSummary {
    customerId?: number; // 门店客户编号
    customerName?: string; // 门店名称
    warehouseId?: number; // 门店仓编号
    warehouseName?: string; // 门店仓名称
    productCount?: number; // 物料数
    totalCount?: number; // 库存数量合计
    totalAmount?: number; // 库存金额合计，单位：元
  }

  /** 门店往来台账 */
  export interface CustomerAccount {
    id?: number; // 台账编号
    customerId?: number; // 门店客户编号
    customerName?: string; // 门店名称
    deptId?: number; // 门店所属部门编号
    deptName?: string; // 门店所属部门名称
    bizType?: number; // 业务类型：1 配送应收 / 2 直拨应收 / 3 收款 / 4 收货差异调整 / 5 退货冲减 / 11 配送应收冲销 / 12 直拨应收冲销
    bizTypeName?: string; // 业务类型名称（后端直接返回中文）
    amount?: number; // 变动金额：正数 = 门店欠总部增加，负数 = 减少，单位：元
    balance?: number; // 记账后余额快照，单位：元
    billTime?: number | string; // 账单时间
    sourceType?: string; // 来源单据类型
    sourceNo?: string; // 来源单号
    remark?: string; // 备注
    createTime?: number | string; // 创建时间
  }

  /** 门店往来台账分页查询参数 */
  export interface CustomerAccountPageReqVO extends PageParam {
    customerId?: number; // 门店客户编号
    deptId?: number; // 门店所属部门编号
    bizType?: number; // 业务类型
    sourceNo?: string; // 来源单号（模糊）
    billTime?: string[]; // 账单时间区间，格式 yyyy-MM-dd HH:mm:ss
  }

  /** 门店往来汇总 */
  export interface CustomerAccountSummary {
    customerId?: number; // 门店客户编号
    customerName?: string; // 门店名称
    deptId?: number; // 门店所属部门编号
    deptName?: string; // 门店所属部门名称
    totalReceivable?: number; // 累计应收，单位：元
    totalReceived?: number; // 累计已收，单位：元
    balance?: number; // 当前余额（正数 = 门店欠总部），单位：元
  }
}

/** 查询门店收货单分页 */
export function getStoreReceiptPage(
  params: TradeStoreReceiptApi.StoreReceiptPageReqVO,
) {
  return requestClient.get<PageResult<TradeStoreReceiptApi.StoreReceipt>>(
    '/trade/store-receipt/page',
    { params },
  );
}

/** 查询门店收货单详情（含明细行） */
export function getStoreReceipt(id: number) {
  return requestClient.get<TradeStoreReceiptApi.StoreReceipt>(
    '/trade/store-receipt/get',
    { params: { id } },
  );
}

/** 后台代录门店收货单（门店电话/微信报单时由后台录入） */
export function createStoreReceipt(
  data: TradeStoreReceiptApi.StoreReceiptCreateReqVO,
) {
  return requestClient.post<number>('/trade/store-receipt/create', data);
}

/** 作废门店收货单（已确认的收货单作废会由后端回滚门店仓与往来账） */
export function cancelStoreReceipt(id: number, reason: string) {
  return requestClient.post<boolean>('/trade/store-receipt/cancel', null, {
    params: { id, reason },
  });
}

/** 导出门店收货单 Excel */
export function exportStoreReceipt(
  params: TradeStoreReceiptApi.StoreReceiptPageReqVO,
) {
  return requestClient.download('/trade/store-receipt/export-excel', { params });
}
