import type {
  AppTradeOrderDetailRespVO,
  AppTradeOrderItemRespVO,
  AppTradeOrderPageItemRespVO,
  BackendPage,
  Order,
  OrderItem,
  OrderStatus,
  PageResult,
} from '@/types';

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
    picUrl: raw.picUrl,
    specText: propertiesToSpecText(raw.properties),
    price,
    quantity: count,
    totalPrice: price * count,
  };
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
      createTime: raw.createTime,
      items: (raw.items ?? []).map(adaptOrderItem),
    })),
    total: page?.total ?? 0,
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
