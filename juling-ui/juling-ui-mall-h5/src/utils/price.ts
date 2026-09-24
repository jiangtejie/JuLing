import type { Sku, SkuTierPrice } from '@/types';

/** 阶梯价匹配结果 */
export interface ResolvedPrice {
  /** 生效单价（单位：分） */
  price: number;
  /** 命中的阶梯区间，未命中为 undefined */
  tier?: SkuTierPrice;
  /** 是否享受阶梯价 */
  isTierPrice: boolean;
}

/**
 * 按订货数量解析单价。
 * 阶梯价按 minQuantity 升序排列，取「起始数量 <= 数量」的最大区间。
 * 数量未达到任何区间的起始数量或未配置阶梯价时，回退到 SKU 基础价。
 */
export function resolvePrice(
  sku: Pick<Sku, 'price' | 'tierPrices'>,
  quantity: number,
): ResolvedPrice {
  const tiers = sku.tierPrices ?? [];
  if (!tiers.length || quantity <= 0) {
    return { price: sku.price, isTierPrice: false };
  }

  const sorted = [...tiers].sort((a, b) => a.minQuantity - b.minQuantity);
  let matched: SkuTierPrice | undefined;
  for (const tier of sorted) {
    const max = tier.maxQuantity ?? Number.POSITIVE_INFINITY;
    if (quantity >= tier.minQuantity && quantity <= max) {
      matched = tier;
      break;
    }
  }

  if (!matched) return { price: sku.price, isTierPrice: false };
  return { price: matched.price, isTierPrice: matched.price !== sku.price, tier: matched };
}

/** 生成阶梯价展示文案：100-199 件 ￥9.90 */
export function formatTierRange(
  tier: SkuTierPrice,
  formatPriceFn: (fen: number) => string,
): string {
  const range =
    tier.maxQuantity === undefined
      ? `${tier.minQuantity} 件以上`
      : `${tier.minQuantity}-${tier.maxQuantity} 件`;
  return `${range} ¥${formatPriceFn(tier.price)}`;
}
