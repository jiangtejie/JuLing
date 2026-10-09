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

/** 前端 key → 后端订单状态码（`AFTER_SALE` / `UNKNOWN` 后端无对应，映射为 -1） */
export const ORDER_STATUS_KEY_TO_CODE: Record<OrderStatus, number> = {
  UNPAID: 0,
  PAID: 10,
  SHIPPED: 20,
  COMPLETED: 30,
  CANCELED: 40,
  AFTER_SALE: -1,
  UNKNOWN: -1,
};

/**
 * 后端状态码 → 前端 key。
 *
 * 未知码**不再兜底为 `CANCELED`**：后端一旦新增状态（例如新的审核 / 退款节点），
 * 门店端会看到与事实相反的「已取消」。现在返回显式的 `UNKNOWN`，
 * 由视图层按中性文案展示（`ORDER_STATUS_MAP` 需补一项 UNKNOWN）。
 */
export function adaptOrderStatus(code: number): OrderStatus {
  return ORDER_STATUS_CODE_TO_KEY[code] ?? 'UNKNOWN';
}

/** 前端筛选 key → 后端状态码；`all` / 未知 / 无对应（AFTER_SALE）返回 undefined */
export function orderStatusKeyToCode(key?: string): number | undefined {
  if (!key || key === 'all') return undefined;
  const code = (ORDER_STATUS_KEY_TO_CODE as Record<string, number | undefined>)[key];
  return code === undefined || code < 0 ? undefined : code;
}

/**
 * 订单页签 → 后端查询参数（门店订货链的业务口径）
 *
 * 后端 status=待发货(10) 同时覆盖「审核中 / 已驳回 / 已通过」，光看 status 分不出能不能发货，
 * 所以：
 * - 「处理中」(REVIEWING)：status=10 且 auditPassed=false（审核未完成，含被驳回的单，门店需重传凭证）
 * - 「待发货」(PAID)：status=10 且 auditPassed=true（已通过两级审批，或直营门店免审）
 * - 其它页签（all / UNPAID / SHIPPED / COMPLETED）按原状态码，不加审核条件
 */
export function orderTabToQuery(tab?: string): {
  auditPassed?: boolean;
  status?: number;
} {
  if (tab === 'REVIEWING') {
    return { status: orderStatusKeyToCode('PAID'), auditPassed: false };
  }
  if (tab === 'PAID') {
    return { status: orderStatusKeyToCode('PAID'), auditPassed: true };
  }
  return { status: orderStatusKeyToCode(tab) };
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
    // 行小计优先用后端 payPrice（应付金额·总）：后台改价 / 优惠后它与 price×count 不一致，
    // 自算会让「商品金额」与「实付」对不上；后端未下发时才回退自算。
    totalPrice: raw.payPrice ?? price * count,
    // 数量进度：下单 → 已发（ERP 出库审核回写）→ 已收（门店确认）。后端 decimal 可能是字符串，
    // 原样透传，由消费方统一 Number(x) || 0。
    deliveredCount: raw.deliveredCount ?? null,
    receiptCount: raw.receiptCount ?? null,
  };
}

/**
 * 收款状态码归一化：后端未返回（老版本 / 空值）时按「未上传凭证」处理，
 * 避免视图层拿到 undefined 后在 RECEIVE_STATUS_MAP 里取不到配置。
 *
 * 值域不变（0-4），只是 1「待核验」在新流程下不再产生——门店提交凭证后订单直接进入
 * 「待发货」并自动提交两级审批；仍有历史订单可能是 1，故原样透传，由文案兜底。
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
      // 门店订货链：代理人账号管多家门店，列表必须能看出每单是哪家店的；审核状态只给粗粒度
      customerId: raw.customerId ?? null,
      customerName: raw.customerName ?? null,
      storeType: raw.storeType ?? null,
      auditStatus: raw.auditStatus ?? null,
    })),
    total: page?.total ?? 0,
  };
}

/** 后端付款凭证 → 前端 PaymentProof（多图地址归一化，空串剔除；状态 0 待审核 / 1 已认定 / 2 已驳回） */
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
    // 订单「已完成」节点的时间（此前漏适配，详情页始终没有时间）
    finishTime: raw.finishTime ?? undefined,
    items: (raw.items ?? []).map(adaptOrderItem),
    // 门店订货链：详情页要显示「这是哪家店的订单」与粗粒度审核结果（不含审批人/节点）
    customerId: raw.customerId ?? null,
    customerName: raw.customerName ?? null,
    storeType: raw.storeType ?? null,
    auditStatus: raw.auditStatus ?? null,
    auditRemark: raw.auditRemark ?? null,
    receiptStatus: raw.receiptStatus ?? null,
  };
}
