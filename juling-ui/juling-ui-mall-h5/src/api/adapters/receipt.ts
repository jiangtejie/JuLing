import type {
  AppTradeStoreReceiptItemRespVO,
  AppTradeStoreReceiptPageItemRespVO,
  AppTradeStoreReceiptRespVO,
  BackendPage,
  PageResult,
  StoreReceipt,
  StoreReceiptDiffType,
  StoreReceiptItem,
  StoreReceiptStatus,
  StoreReceiptSummary,
} from '@/types';
// 带 .ts 扩展名：adapter 会被 node --test 直接执行，ESM 环境不接受省略扩展名
import { normalizeAssetUrl, normalizeOptionalAssetUrl } from '../../utils/asset.ts';

/**
 * 门店收货域 DTO → 领域模型映射。
 *
 * 后端数量字段是 numeric(24,6)、金额是 numeric(24,2)，序列化后可能是字符串，
 * 统一归一到 number，避免视图层出现 `price * count` 得到 "9.500" 这种拼串结果。
 */

/** 数值归一化：null / undefined / 非法值 → 0 */
function toNumber(value: number | string | null | undefined): number {
  const num = Number(value ?? 0);
  return Number.isFinite(num) ? num : 0;
}

/** 收货单状态码归一化：未知码兜底「待确认」，避免视图层取不到配置 */
export function adaptStoreReceiptStatus(status?: number | null): StoreReceiptStatus {
  return status === 10 || status === 20 ? status : 0;
}

/** 差异类型码归一化：未知码兜底「无差异」 */
export function adaptStoreReceiptDiffType(diffType?: number | null): StoreReceiptDiffType {
  return diffType === 1 || diffType === 2 || diffType === 3 || diffType === 4 ? diffType : 0;
}

/**
 * 规格文本：后端收货单行存的是快照字符串；
 * 兼容历史 / 其他来源可能下发的属性数组（取 valueName 拼接）。
 */
function adaptSpecText(properties: string): string {
  const raw: unknown = properties;
  if (Array.isArray(raw)) {
    return raw
      .map((item) => (item as { valueName?: string } | null)?.valueName)
      .filter(Boolean)
      .join(' ');
  }
  return typeof raw === 'string' ? raw : '';
}

/**
 * 收货凭证图片归一化。
 *
 * 后端 app 端 VO 的 fileUrls 是 **JSON 数组字符串**（trade_order_receipt.file_urls 为文本列，
 * 落库时 JsonUtils.toJsonString），并不是数组——直接当数组用会在运行时抛
 * 「value.map is not a function」。这里同时兼容数组、JSON 字符串与逗号分隔的兜底写法。
 */
export function adaptFileUrls(value: string | string[] | null | undefined): string[] {
  const normalize = (urls: unknown[]): string[] =>
    urls.map((url) => normalizeAssetUrl(typeof url === 'string' ? url : '')).filter(Boolean);

  if (Array.isArray(value)) return normalize(value);
  const text = (value ?? '').trim();
  if (!text) return [];
  if (text.startsWith('[')) {
    try {
      const parsed: unknown = JSON.parse(text);
      return Array.isArray(parsed) ? normalize(parsed) : [];
    } catch {
      // 非法 JSON：宁可当成「没有图片」，也不要把整段脏字符串当图片地址渲染（会破图）
      return [];
    }
  }
  return normalize(text.split(','));
}

/** 收货单行项 → StoreReceiptItem（spuName → name、properties → specText） */
export function adaptStoreReceiptItem(raw: AppTradeStoreReceiptItemRespVO): StoreReceiptItem {
  return {
    id: raw.id,
    orderItemId: raw.orderItemId,
    spuId: raw.spuId,
    skuId: raw.skuId,
    name: raw.spuName ?? '',
    specText: adaptSpecText(raw.properties),
    picUrl: normalizeOptionalAssetUrl(raw.picUrl),
    productId: raw.productId,
    productName: raw.productName ?? '',
    price: toNumber(raw.price),
    expectCount: toNumber(raw.expectCount),
    receiptCount: toNumber(raw.receiptCount),
    diffCount: toNumber(raw.diffCount),
    diffAmount: toNumber(raw.diffAmount),
    diffReason: raw.diffReason ?? undefined,
    batchNo: raw.batchNo ?? undefined,
    productionDate: raw.productionDate ?? undefined,
    expiryDate: raw.expiryDate ?? undefined,
  };
}

/** 待收货分页 → 前端分页 */
export function adaptStoreReceiptPage(
  page: BackendPage<AppTradeStoreReceiptPageItemRespVO>,
): PageResult<StoreReceiptSummary> {
  return {
    list: (page?.list ?? []).map((raw) => ({
      id: raw.id,
      no: raw.no,
      orderId: raw.orderId,
      orderNo: raw.orderNo,
      customerName: raw.customerName ?? '',
      totalCount: toNumber(raw.totalCount),
      totalPrice: toNumber(raw.totalPrice),
      receiveTime: raw.receiveTime ?? undefined,
      saleOutNo: raw.saleOutNo ?? '',
      status: adaptStoreReceiptStatus(raw.status),
      statusName: raw.statusName ?? '',
      diffType: adaptStoreReceiptDiffType(raw.diffType),
      diffTypeName: raw.diffTypeName ?? '',
    })),
    total: page?.total ?? 0,
  };
}

/** 收货单详情 → StoreReceipt（图片地址归一化，空串剔除） */
export function adaptStoreReceiptDetail(raw: AppTradeStoreReceiptRespVO): StoreReceipt {
  return {
    id: raw.id,
    no: raw.no,
    orderId: raw.orderId,
    orderNo: raw.orderNo,
    customerName: raw.customerName ?? '',
    saleOutNo: raw.saleOutNo ?? '',
    status: adaptStoreReceiptStatus(raw.status),
    statusName: raw.statusName ?? '',
    diffType: adaptStoreReceiptDiffType(raw.diffType),
    diffTypeName: raw.diffTypeName ?? '',
    totalCount: toNumber(raw.totalCount),
    receiptCount: toNumber(raw.receiptCount),
    diffCount: toNumber(raw.diffCount),
    totalPrice: toNumber(raw.totalPrice),
    receiptPrice: toNumber(raw.receiptPrice),
    diffAmount: toNumber(raw.diffAmount),
    receiverName: raw.receiverName ?? undefined,
    receiverMobile: raw.receiverMobile ?? undefined,
    fileUrls: adaptFileUrls(raw.fileUrls),
    remark: raw.remark ?? undefined,
    receiveTime: raw.receiveTime ?? undefined,
    items: (raw.items ?? []).map(adaptStoreReceiptItem),
  };
}
