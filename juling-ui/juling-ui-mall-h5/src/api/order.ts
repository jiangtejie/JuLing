import type {
  AppTradeOrderCreateReqVO,
  AppTradeOrderCreateRespVO,
  AppTradeOrderDetailRespVO,
  AppTradeOrderPageItemRespVO,
  AppTradeOrderPaymentProofCreateReqVO,
  AppTradeOrderPaymentProofRespVO,
  BackendPage,
  Order,
  OrderCreateParam,
  PageResult,
  PaymentProof,
  PaymentProofCreateParam,
  StoreOption,
} from '@/types';
import {
  adaptOrderDetail,
  adaptOrderPage,
  adaptPaymentProof,
  orderStatusKeyToCode,
} from '@/api/adapters';
import { http } from '@/utils/request';

export interface OrderQuery {
  pageNo?: number;
  pageSize?: number;
  /** 订单状态筛选（前端 key，如 UNPAID / PAID / all） */
  status?: string;
}

/**
 * 获得可下单门店列表（门店订货链 S1）。
 * 代理账号可切换其名下门店；普通门店账号只有自己。
 */
export function getStoreList(): Promise<StoreOption[]> {
  return http.get<StoreOption[]>('/trade/order/store-list');
}

/** 提交订单（订货单 → 后端交易订单；返回后端订单编号 id） */
export async function createOrder(data: OrderCreateParam): Promise<number> {
  const payload: AppTradeOrderCreateReqVO = {
    items: data.items.map((item) => ({ skuId: item.skuId, count: item.quantity })),
    // 配送方式固定「快递发货」（积分/优惠券等营销字段已随营销模块下线）
    deliveryType: 1,
    receiverName: data.receiverName,
    receiverMobile: data.receiverMobile,
    receiverDetailAddress: data.receiverAddress,
  };
  if (data.remark) payload.remark = data.remark;
  // 门店订货链：携带所选门店，后端据此校验归属并快照组织/客户
  if (data.storeCustomerId) payload.storeCustomerId = data.storeCustomerId;
  const result = await http.post<AppTradeOrderCreateRespVO>('/trade/order/create', payload);
  return result.id;
}

/** 订单分页（前端 key 自动转后端状态码） */
export async function getOrderPage(params: OrderQuery): Promise<PageResult<Order>> {
  const page = await http.get<BackendPage<AppTradeOrderPageItemRespVO>>('/trade/order/page', {
    pageNo: params.pageNo,
    pageSize: params.pageSize,
    status: orderStatusKeyToCode(params.status),
  });
  return adaptOrderPage(page);
}

/** 订单详情 */
export async function getOrderDetail(id: number): Promise<Order> {
  const detail = await http.get<AppTradeOrderDetailRespVO>('/trade/order/get-detail', { id });
  return adaptOrderDetail(detail);
}

/** 取消订单（后端为 DELETE + query 参数 id） */
export function cancelOrder(id: number): Promise<boolean> {
  return http.delete<boolean>('/trade/order/cancel', { id });
}

/** 确认收货（后端为 PUT + query 参数 id） */
export function confirmOrder(id: number): Promise<boolean> {
  return http.put<boolean>('/trade/order/receive', undefined, { params: { id } });
}

/**
 * 上传付款凭证图片，返回文件访问地址。
 * 复用 infra 的文件上传接口（multipart），与后台用的是同一套存储。
 */
export function uploadPaymentImage(file: File): Promise<string> {
  return http.upload<string>('/infra/file/upload', file, { directory: 'trade/payment-proof' });
}

/**
 * 提交付款凭证（线下收款）。
 * 每次上传都是一条独立记录：支持分次付款多次上传，被驳回后也能重新上传。
 */
export function createPaymentProof(data: PaymentProofCreateParam): Promise<number> {
  const payload: AppTradeOrderPaymentProofCreateReqVO = {
    orderId: data.orderId,
    urls: data.urls,
    amount: data.amount,
  };
  if (data.payerName) payload.payerName = data.payerName;
  if (data.payChannelCode) payload.payChannelCode = data.payChannelCode;
  if (data.transferTime) payload.transferTime = data.transferTime;
  if (data.remark) payload.remark = data.remark;
  return http.post<number>('/trade/order/payment-proof/create', payload);
}

/** 订单的付款凭证列表（含历史记录与驳回原因） */
export async function getPaymentProofList(orderId: number): Promise<PaymentProof[]> {
  const list = await http.get<AppTradeOrderPaymentProofRespVO[]>(
    '/trade/order/payment-proof/list',
    { orderId },
  );
  return (list ?? []).map(adaptPaymentProof);
}

/** 各状态订单数量（后端 /trade/order/get-count） */
export interface OrderCountMap {
  /** 全部 */
  allCount: number;
  /** 待付款 */
  unpaidCount: number;
  /** 待发货 */
  undeliveredCount: number;
  /** 待收货 */
  deliveredCount: number;
  /** 售后中 */
  afterSaleCount: number;
}

/** 订单数量统计（用于「我的」页订单卡片角标） */
export function getOrderCount(): Promise<OrderCountMap> {
  return http.get<OrderCountMap>('/trade/order/get-count');
}
