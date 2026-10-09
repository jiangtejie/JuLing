import assert from 'node:assert/strict';
import { test } from 'node:test';

import { formatTierRange, resolvePrice } from '../src/utils/price.ts';

/**
 * 阶梯价命中规则（订货业务核心）。
 * 区间两端都是**闭区间**，数量掉进区间之间（数据配错留缝）必须回退基础价，
 * 否则会按错误的档位计价。
 */

/** 常见三档：1-9 / 10-99 / 100 以上 */
const tiers = [
  { minQuantity: 1, maxQuantity: 9, price: 1000 },
  { minQuantity: 10, maxQuantity: 99, price: 900 },
  { minQuantity: 100, price: 800 },
];

const sku = { price: 1200, tierPrices: tiers };

test('resolvePrice：区间两端都是闭区间（min / max 均命中）', () => {
  assert.equal(resolvePrice(sku, 9).price, 1000);
  assert.equal(resolvePrice(sku, 10).price, 900);
  assert.equal(resolvePrice(sku, 99).price, 900);
  assert.equal(resolvePrice(sku, 100).price, 800);
});

test('resolvePrice：未达最低档位时用 SKU 基础价', () => {
  const high = { price: 1200, tierPrices: [{ minQuantity: 10, maxQuantity: 99, price: 900 }] };
  assert.deepEqual(resolvePrice(high, 1), { price: 1200, isTierPrice: false });
  assert.deepEqual(resolvePrice(high, 9), { price: 1200, isTierPrice: false });
});

test('resolvePrice：上不封顶的区间（maxQuantity 缺省）吃掉所有更大的数量', () => {
  assert.equal(resolvePrice(sku, 100).price, 800);
  assert.equal(resolvePrice(sku, 999999).price, 800);
  assert.equal(resolvePrice(sku, 999999).tier?.minQuantity, 100);
});

test('resolvePrice：数量落在两个区间的缝隙里 → 回退基础价（配置留缝不猜）', () => {
  const gapped = {
    price: 1200,
    tierPrices: [
      { minQuantity: 1, maxQuantity: 9, price: 1000 },
      { minQuantity: 20, maxQuantity: 29, price: 800 },
    ],
  };
  assert.equal(resolvePrice(gapped, 10).price, 1200);
  assert.equal(resolvePrice(gapped, 19).price, 1200);
  assert.equal(resolvePrice(gapped, 15).isTierPrice, false);
  // 缝隙两侧仍正常命中
  assert.equal(resolvePrice(gapped, 9).price, 1000);
  assert.equal(resolvePrice(gapped, 20).price, 800);
});

test('resolvePrice：数量 <= 0（未填写 / 清空输入）一律回退基础价', () => {
  assert.deepEqual(resolvePrice(sku, 0), { price: 1200, isTierPrice: false });
  assert.deepEqual(resolvePrice(sku, -3), { price: 1200, isTierPrice: false });
});

test('resolvePrice：无阶梯价 / 空数组时用基础价', () => {
  assert.deepEqual(resolvePrice({ price: 1200 }, 50), { price: 1200, isTierPrice: false });
  assert.deepEqual(resolvePrice({ price: 1200, tierPrices: [] }, 50), {
    price: 1200,
    isTierPrice: false,
  });
});

test('resolvePrice：乱序下发的阶梯价按 minQuantity 排序后命中（不依赖后端顺序）', () => {
  const shuffled = {
    price: 1200,
    tierPrices: [
      { minQuantity: 100, price: 800 },
      { minQuantity: 1, maxQuantity: 9, price: 1000 },
      { minQuantity: 10, maxQuantity: 99, price: 900 },
    ],
  };
  assert.equal(resolvePrice(shuffled, 5).price, 1000);
  assert.equal(resolvePrice(shuffled, 50).price, 900);
  assert.equal(resolvePrice(shuffled, 500).price, 800);
});

test('resolvePrice：档位价与基础价相同时不算「享受阶梯价」，但仍回传命中区间', () => {
  const flat = { price: 1000, tierPrices: [{ minQuantity: 10, price: 1000 }] };
  const resolved = resolvePrice(flat, 10);
  assert.equal(resolved.price, 1000);
  assert.equal(resolved.isTierPrice, false);
  assert.equal(resolved.tier?.minQuantity, 10);
});

test('formatTierRange：闭区间文案与「以上」文案', () => {
  const format = (fen: number) => (fen / 100).toFixed(2);
  assert.equal(
    formatTierRange({ minQuantity: 100, maxQuantity: 199, price: 990 }, format),
    '100-199 件 ¥9.90',
  );
  assert.equal(formatTierRange({ minQuantity: 200, price: 890 }, format), '200 件以上 ¥8.90');
});
