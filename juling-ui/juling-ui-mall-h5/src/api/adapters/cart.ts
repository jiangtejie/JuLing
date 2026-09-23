import type { AppCartItemRespVO, AppCartListRespVO, CartItem } from '@/types';
import { adaptProperties } from './product';

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
  const picUrl = sku?.picUrl || spu?.picUrl || '';

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

/** 购物车列表 → 行项数组（只取有效项） */
export function adaptCartList(raw: AppCartListRespVO): CartItem[] {
  return (raw?.validList ?? []).map(adaptCartItem);
}
