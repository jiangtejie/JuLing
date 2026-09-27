import type {
  AppTradeOrderDetailRespVO,
  AppTradeOrderItemRespVO,
  AppTradeOrderPageItemRespVO,
  AppTradeOrderPaymentProofRespVO,
  BackendPage,
  Order,
  OrderItem,
  OrderStatus,
  PageResult,
  PaymentProof,
  ReceiveStatusCode,
} from '@/types';
// 带 `.ts` 扩展名：adapter 会被 `node --test` 直接执行，ESM 环境不接受省略扩展名
import { normalizeAssetUrl, normalizeOptionalAssetUrl } from '../../utils/asset.ts';

/**
 * 交易订单域 DTO → 领域模型映射，并集中承载「后端状态码 ↔ 前端 key」。
 *
 * 后端 `TradeOrderStatusEnum`：0 待支付 / 10 待发货 / 20 已发货 / 30 已完成 / 40 已取消，
 * 与前端字符串枚举语义对齐见下方两张映射表；后端无 `AFTER_SALE`。
 */

/** 后端订单状态码 → 前端 key */
export const ORDER_STATUS_CODE_TO_KEY: Record<number, OrderStatus> = {
  0: 'UNPAID',
  10: 'PAID', // 后端 UNDELIVERED（待发货）
  20: 'SHIPPED', // 后端 DELIVERED（已发货 → 前端「待收货」）
  30: 'COMPLETED',
  40: 'CANCELED',
};

/** 前端 key → 后端订单状态码（`AFTER_SALE` 后端无对应，映射为 -1） */
export const ORDER_STATUS_KEY_TO_CODE: Record<OrderStatus, number> = {
  UNPAID: 0,
  PAID: 10,
  SHIPPED: 20,
  COMPLETED: 30,
  CANCELED: 40,
  AFTER_SALE: -1,
};

/** 后端状态码 → 前端 key（未知码兜底 CANCELED） */
export function adaptOrderStatus(code: number): OrderStatus {
  return ORDER_STATUS_CODE_TO_KEY[code] ?? 'CANCELED';
}

/** 前端筛选 key → 后端状态码；`all` / 未知 / 无对应（AFTER_SALE）返回 undefined */
export function orderStatusKeyToCode(key?: string): number | undefined {
  if (!key || key === 'all') return undefined;
  const code = (ORDER_STATUS_KEY_TO_CODE as Record<string, number | undefined>)[key];
  return code === undefined || code < 0 ? undefined : code;
}

/** 属性数组 → 规格文本，如「红色 M」 */
function propertiesToSpecText(properties?: Array<{ valueName?: string }> | null): string {
  return (properties ?? [])
    .map((item) => item?.valueName)
    .filter(Boolean)
    .join(' ');
}

/** 后端订单项 → 前端 OrderItem（spuName→name、count→quantity） */
export function adaptOrderItem(raw: AppTradeOrderItemRespVO): OrderItem {
  const count = raw.count ?? 0;
  const price = raw.price ?? 0;
  return {
    id: raw.id,
    spuId: raw.spuId,
    skuId: raw.skuId,
    name: raw.spuName,
    picUrl: normalizeOptionalAssetUrl(raw.picUrl),
    specText: propertiesToSpecText(raw.properties),
    price,
    quantity: count,
    totalPrice: price * count,
  };
}

/**
 * 收款状态码归一化：后端未返回（老版本 / 空值）时按「未上传凭证」处理，
 * 避免视图层拿到 undefined 后在 RECEIVE_STATUS_MAP 里取不到配置。
 */
export function adaptReceiveStatus(status?: number | null): ReceiveStatusCode {
  return (status ?? 0) as ReceiveStatusCode;
}

/** 后端订单分页 → 前端分页 */
export function adaptOrderPage(page: BackendPage<AppTradeOrderPageItemRespVO>): PageResult<Order> {
  return {
    list: (page?.list ?? []).map((raw) => ({
      id: raw.id,
      orderNo: raw.no,
      status: adaptOrderStatus(raw.status),
      totalPrice: raw.payPrice ?? 0,
      payPrice: raw.payPrice ?? 0,
      paidAmount: raw.paidAmount ?? 0,
      paymentProofStatus: adaptReceiveStatus(raw.paymentProofStatus),
      createTime: raw.createTime,
      items: (raw.items ?? []).map(adaptOrderItem),
    })),
    total: page?.total ?? 0,
  };
}

/** 后端付款凭证 → 前端 PaymentProof（多图地址归一化，空串剔除） */
export function adaptPaymentProof(raw: AppTradeOrderPaymentProofRespVO): PaymentProof {
  return {
    id: raw.id,
    orderId: raw.orderId,
    urls: (raw.urls ?? []).map((url) => normalizeAssetUrl(url)).filter(Boolean),
    amount: raw.amount ?? 0,
    confirmedAmount: raw.confirmedAmount ?? undefined,
    payerName: raw.payerName ?? undefined,
    payChannelCode: raw.payChannelCode ?? undefined,
    transferTime: raw.transferTime ?? undefined,
    remark: raw.remark ?? undefined,
    status: raw.status ?? 0,
    auditTime: raw.auditTime ?? undefined,
    auditRemark: raw.auditRemark ?? undefined,
    createTime: raw.createTime,
  };
}

/** 后端订单详情 → 前端 Order（no→orderNo、deliveryPrice→freightPrice、userRemark→remark、地址拼接） */
export function adaptOrderDetail(raw: AppTradeOrderDetailRespVO): Order {
  const receiverAddress = [raw.receiverAreaName, raw.receiverDetailAddress]
    .filter((part) => part)
    .join(' ');
  return {
    id: raw.id,
    orderNo: raw.no,
    status: adaptOrderStatus(raw.status),
    totalPrice: raw.totalPrice ?? 0,
    discountPrice: raw.discountPrice ?? 0,
    payPrice: raw.payPrice ?? 0,
    paidAmount: raw.paidAmount ?? 0,
    paymentProofStatus: adaptReceiveStatus(raw.paymentProofStatus),
    freightPrice: raw.deliveryPrice ?? 0,
    receiverName: raw.receiverName,
    receiverMobile: raw.receiverMobile,
    receiverAddress,
    remark: raw.userRemark,
    createTime: raw.createTime,
    payTime: raw.payTime ?? undefined,
    deliveryTime: raw.deliveryTime ?? undefined,
    items: (raw.items ?? []).map(adaptOrderItem),
  };
}
