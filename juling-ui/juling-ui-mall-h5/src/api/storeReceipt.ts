import type {
  AppTradeStoreReceiptCreateItemReqVO,
  AppTradeStoreReceiptCreateReqVO,
  AppTradeStoreReceiptPageItemRespVO,
  AppTradeStoreReceiptRespVO,
  BackendPage,
  PageResult,
  StoreReceipt,
  StoreReceiptCreateParam,
  StoreReceiptSummary,
} from '@/types';
import { adaptStoreReceiptDetail, adaptStoreReceiptPage } from '@/api/adapters';
import { http } from '@/utils/request';

/**
 * 门店收货接口（配送出库单审核后，门店在 H5 逐行确认实收）。
 *
 * 业务链路：配送出库单审核 → 中心库出库、订单变「已发货」→ 门店确认收货
 * → 实收写入门店仓库存 + 生成门店往来（应收 / 差异调整）。
 */

export interface StoreReceiptQuery {
  pageNo?: number;
  pageSize?: number;
}

/** 待收货分页（后端已按当前登录门店过滤） */
export async function getStoreReceiptPage(
  params: StoreReceiptQuery,
): Promise<PageResult<StoreReceiptSummary>> {
  const page = await http.get<BackendPage<AppTradeStoreReceiptPageItemRespVO>>(
    '/trade/order/store-receipt/pending-page',
    { pageNo: params.pageNo, pageSize: params.pageSize },
  );
  return adaptStoreReceiptPage(page);
}

/**
 * 收货单详情（按订单号取，订单与收货单一对一）。
 *
 * 后端可能返回空数据（收货单尚未生成 / 已作废清理），这里收敛为 null，
 * 由页面给出「暂无可确认的收货单」空态，而不是渲染一张全 0 的假单据。
 */
export async function getStoreReceiptDetail(orderId: number): Promise<StoreReceipt | null> {
  const detail = await http.get<AppTradeStoreReceiptRespVO | null>(
    '/trade/order/store-receipt/get',
    { orderId },
  );
  return detail ? adaptStoreReceiptDetail(detail) : null;
}

/**
 * 提交收货。
 *
 * items 只需回填实收数量与差异原因：应收数量、差异数量与差异金额都由后端
 * 按配送出库单重新核对（前端算出的值只用于展示，不能作为入账依据）。
 */
export function createStoreReceipt(data: StoreReceiptCreateParam): Promise<number> {
  const payload: AppTradeStoreReceiptCreateReqVO = {
    orderId: data.orderId,
    items: data.items.map((item) => {
      const row: AppTradeStoreReceiptCreateItemReqVO = {
        orderItemId: item.orderItemId,
        receiptCount: item.receiptCount,
      };
      if (item.diffReason) row.diffReason = item.diffReason;
      return row;
    }),
  };
  if (data.receiverName) payload.receiverName = data.receiverName;
  if (data.receiverMobile) payload.receiverMobile = data.receiverMobile;
  if (data.fileUrls?.length) payload.fileUrls = data.fileUrls;
  if (data.remark) payload.remark = data.remark;
  return http.post<number>('/trade/order/store-receipt/create', payload);
}

/**
 * 上传收货照片，返回文件访问地址。
 * 复用 infra 的文件上传接口（multipart），与付款凭证走同一套存储。
 */
export function uploadStoreReceiptImage(file: File): Promise<string> {
  return http.upload<string>('/infra/file/upload', file, { directory: 'trade/store-receipt' });
}
