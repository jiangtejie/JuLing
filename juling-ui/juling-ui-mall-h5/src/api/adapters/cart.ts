import type {
  AppCartItemRespVO,
  AppCartListRespVO,
  CartItem,
  CartListResult,
  InvalidCartItem,
} from '@/types';
import { adaptProperties } from './product.ts';
// 带 `.ts` 扩展名：adapter 会被 `node --test` 直接执行，ESM 环境不接受省略扩展名
import { normalizeAssetUrl } from '../../utils/asset.ts';

/**
 * 购物车 DTO → 领域模型映射。
 *
 * 注意（后端限制）：购物车内嵌的 SKU 只有 `id/picUrl/price/stock/properties`——
 * 无 name、无起订量、无阶梯价，故规格名由 properties 拼、起订量取 1、阶梯价置空。
 */
export function adaptCartItem(raw: AppCartItemRespVO): CartItem {
  const spu = raw.spu;
  const sku = raw.sku;

  const spuId = Number(spu?.id ?? 0);
  const skuId = Number(sku?.id ?? 0);
  const price = Number(sku?.price ?? 0);
  const stock = Number(sku?.stock ?? 0);
  const properties = adaptProperties(sku?.properties);
  const specText = Object.values(properties).filter(Boolean).join(' ') || `规格 ${skuId}`;
  const picUrl = normalizeAssetUrl(sku?.picUrl || spu?.picUrl || '');

  return {
    key: `${spuId}-${skuId}`,
    cartId: raw.id,
    spuId,
    skuId,
    name: spu?.name ?? '',
    picUrl,
    specText,
    price,
    originPrice: price,
    quantity: raw.count ?? 1,
    stock,
    minOrderQuantity: 1,
    checked: raw.selected ?? true,
    sku: {
      id: skuId,
      spuId,
      name: specText,
      picUrl,
      properties,
      price,
      marketPrice: price,
      stock,
      minOrderQuantity: 1,
      tierPrices: undefined,
    },
  };
}

/** 商品下架状态（后端 ProductSpuStatusEnum：0 下架 / 1 上架） */
const SPU_STATUS_DISABLED = 0;

/**
 * 推导失效原因：与后端 `TradeCartConvert` 把行项塞进 invalidList 的判定口径一致
 * （SPU 不存在 / 非上架 / SPU 库存 <= 0），保证页面文案说的就是它失效的真实原因。
 * 后端不下发原因字段，只认 SPU 状态 0（下架），状态缺失时不臆断「已下架」。
 */
function resolveInvalidReason(raw: AppCartItemRespVO): string {
  const spu = raw.spu;
  if (!spu) return '商品已下架或不存在';
  if (spu.status === SPU_STATUS_DISABLED) return '商品已下架';
  if (Number(spu.stock ?? 0) <= 0) return '库存不足';
  return '商品已失效';
}

/**
 * 失效行项：结构与有效项一致，额外带上 `invalid` 标记与 `invalidReason`。
 * 强制 `checked: false`——失效商品不可下单，避免被一起提交（后端也会拒绝）。
 */
export function adaptInvalidCartItem(raw: AppCartItemRespVO): InvalidCartItem {
  return {
    ...adaptCartItem(raw),
    invalid: true,
    checked: false,
    invalidReason: resolveInvalidReason(raw),
  };
}

/**
 * 购物车列表 → 有效行项数组。
 * 保留该签名（store 等调用方在用）；需要失效项请用 `adaptCartListResult`。
 */
export function adaptCartList(raw: AppCartListRespVO): CartItem[] {
  return (raw?.validList ?? []).map(adaptCartItem);
}

/** 购物车列表 → 聚合结果（有效项 + 失效项），页面据此展示「失效商品」分组 */
export function adaptCartListResult(raw: AppCartListRespVO): CartListResult {
  return {
    items: (raw?.validList ?? []).map(adaptCartItem),
    invalidItems: (raw?.invalidList ?? []).map(adaptInvalidCartItem),
  };
}
