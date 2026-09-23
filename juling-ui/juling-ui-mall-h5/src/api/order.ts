import type {
  AppTradeOrderCreateReqVO,
  AppTradeOrderCreateRespVO,
  AppTradeOrderDetailRespVO,
  AppTradeOrderPageItemRespVO,
  BackendPage,
  Order,
  OrderCreateParam,
  PageResult,
} from '@/types';
import { adaptOrderDetail, adaptOrderPage, orderStatusKeyToCode } from '@/api/adapters';
import { http } from '@/utils/request';

export interface OrderQuery {
  pageNo?: number;
  pageSize?: number;
  /** 订单状态筛选（前端 key，如 UNPAID / PAID / all） */
  status?: string;
}

/** 提交订单（订货单 → 后端交易订单；返回后端订单编号 id） */
export async function createOrder(data: OrderCreateParam): Promise<number> {
  const payload: AppTradeOrderCreateReqVO = {
    items: data.items.map((item) => ({ skuId: item.skuId, count: item.quantity })),
    // 后端结算必填项：不使用积分；配送方式固定「快递发货」
    pointStatus: false,
    deliveryType: 1,
    receiverName: data.receiverName,
    receiverMobile: data.receiverMobile,
    receiverDetailAddress: data.receiverAddress,
  };
  if (data.remark) payload.remark = data.remark;
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
