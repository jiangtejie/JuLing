import type { PageParam, PageResult } from '@vben/request';

import { requestClient } from '#/api/request';

export namespace TradeWorkbenchApi {
  /** 待处理要货单 */
  export interface Order {
    id?: number; // 订单编号
    no?: string; // 要货单号
    createTime?: Date; // 下单时间
    customerId?: number; // 门店客户编号
    customerName?: string; // 门店名称
    deptId?: number; // 门店所属部门
    storeType?: string; // 店型：DIRECT 直营 / FRANCHISE 加盟
    settlementMode?: string; // 结算模式
    payPrice?: number; // 应付金额，单位：分
    paidAmount?: number; // 已确认收款金额，单位：分
    paymentProofStatus?: number; // 收款状态
    auditStatus?: number; // 审核状态
    status?: number; // 订单状态
    itemCount?: number; // 订单行数
    pendingItemCount?: number; // 未分料行数
    /** 展开后由 getWorkbenchItems 填充 */
    workbenchItems?: Item[];
  }

  /** 要货单明细行 */
  export interface Item {
    id?: number; // 订单行编号
    spuId?: number; // 商品 SPU
    spuName?: string; // 商品名称
    skuId?: number; // 商品 SKU
    picUrl?: string; // 商品图片
    count?: number; // 要货数量
    price?: number; // 单价，单位：分
    payPrice?: number; // 小计，单位：分
    erpProductId?: number; // ERP 物料编号
    erpProductName?: string; // ERP 物料名称
    erpProductBarCode?: string; // ERP 物料条码
    allowCentral?: boolean; // 允许统配
    allowDirect?: boolean; // 允许直拨
    allocMode?: string; // 已选分料方式
    allocCount?: number; // 已下推数量
    pushedBillType?: string; // 已下推单据类型
    pushedBillNo?: string; // 已下推单据号
    availableCount?: number; // 可下推数量
    availableHint?: string; // 可下推提示
    /** 前端编辑态 */
    pushMode?: string;
    pushCount?: number;
    supplierId?: number;
  }

  /** 下推请求行 */
  export interface PushItem {
    itemId: number;
    allocMode: string;
    count?: number;
    supplierId?: number;
  }

  /** 下推请求 */
  export interface PushReqVO {
    orderId: number;
    warehouseId?: number;
    supplierId?: number;
    items: PushItem[];
  }

  /** 下推结果 */
  export interface PushResult {
    itemId?: number;
    allocMode?: string;
    billType?: string;
    billId?: number;
    billNo?: string;
  }

  export interface PushRespVO {
    results?: PushResult[];
  }
}

/** 查询待处理要货单分页（订单工作台） */
export function getWorkbenchPage(params: PageParam) {
  return requestClient.get<PageResult<TradeWorkbenchApi.Order>>(
    '/trade/workbench/page',
    { params },
  );
}

/** 查询要货单明细行（含分料属性与已下推情况） */
export function getWorkbenchItems(orderId: number) {
  return requestClient.get<TradeWorkbenchApi.Item[]>(
    '/trade/workbench/get-items',
    { params: { orderId } },
  );
}

/** 分料下推：统配 → 配送出库单；直拨 → 采购订单 */
export function pushWorkbenchItems(data: TradeWorkbenchApi.PushReqVO) {
  return requestClient.post<TradeWorkbenchApi.PushRespVO>(
    '/trade/workbench/push',
    data,
  );
}
