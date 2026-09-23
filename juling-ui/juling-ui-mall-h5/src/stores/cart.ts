import { defineStore } from 'pinia';
import { adaptCartList } from '@/api/adapters/cart';
import { getCartList } from '@/api/cart';
import { STORAGE_KEYS } from '@/constants';
import type { CartItem, Sku } from '@/types';
import { deepClone } from '@/utils/index';
import { persistKey } from '@/utils/persist';
import { resolvePrice } from '@/utils/price';

export interface AddCartPayload {
  spuId: number;
  sku: Partial<Sku> & { id: number; name: string; price: number; stock: number };
  quantity: number;
}

/**
 * 订货单（购物车）状态。
 * 使用 pinia-plugin-persistedstate 持久化到 localStorage，
 * 刷新页面 / 从公众号返回时不会丢失已选商品。
 */
export const useCartStore = defineStore(
  'cart',
  () => {
    const items = ref<CartItem[]>([]);

    /** 已勾选行项 */
    const checkedItems = computed(() => items.value.filter((item) => item.checked));

    /** 已勾选商品总件数 */
    const totalQuantity = computed(() =>
      checkedItems.value.reduce((sum, item) => sum + item.quantity, 0),
    );

    /** 已勾选合计金额（单位：分，可直接传给 van-submit-bar 的 price） */
    const totalPrice = computed(() =>
      checkedItems.value.reduce((sum, item) => sum + item.price * item.quantity, 0),
    );

    /** 订货单商品种类数 */
    const totalKinds = computed(() => items.value.length);

    const allChecked = computed({
      get: () => items.value.length > 0 && items.value.every((item) => item.checked),
      set: (value: boolean) => {
        items.value.forEach((item) => {
          item.checked = value;
        });
      },
    });

    const itemKey = (spuId: number, skuId: number) => `${spuId}-${skuId}`;

    function findIndex(skuId: number): number {
      return items.value.findIndex((item) => item.skuId === skuId);
    }

    /** 加入订货单；已存在则累加数量 */
    function addItem(payload: AddCartPayload): void {
      const { spuId, sku, quantity } = payload;
      const index = findIndex(sku.id);
      const maxQuantity = sku.stock ?? Number.MAX_SAFE_INTEGER;

      if (index > -1) {
        const exist = items.value[index];
        const next = Math.min(exist.quantity + quantity, maxQuantity);
        exist.quantity = next;
        recalculate(exist);
        return;
      }

      const specText = Object.values(sku.properties ?? {}).join(' ') || sku.name;
      const item: CartItem = {
        key: itemKey(spuId, sku.id),
        spuId,
        skuId: sku.id,
        name: sku.name,
        picUrl: sku.picUrl,
        specText,
        price: sku.price,
        originPrice: sku.price,
        quantity: Math.min(quantity, maxQuantity),
        stock: sku.stock,
        minOrderQuantity: sku.minOrderQuantity ?? 1,
        checked: true,
        // 深拷贝快照：后续商品数据刷新不会污染已加入订货单的行项
        sku: deepClone(sku),
      };
      recalculate(item);
      items.value.unshift(item);
    }

    /** 修改数量并重新计算阶梯价 */
    function updateQuantity(skuId: number, quantity: number): void {
      const index = findIndex(skuId);
      if (index === -1) return;
      const item = items.value[index];
      item.quantity = Math.max(item.minOrderQuantity, Math.min(quantity, item.stock));
      recalculate(item);
    }

    /** 按当前数量重新解析单价（阶梯价核心逻辑） */
    function recalculate(item: CartItem): void {
      const sku = item.sku;
      if (!sku?.price) return;
      const resolved = resolvePrice(
        { price: sku.price, tierPrices: sku.tierPrices },
        item.quantity,
      );
      item.price = resolved.price;
      item.tierPrice = resolved.isTierPrice;
    }

    function removeItems(skuIds: number[]): void {
      items.value = items.value.filter((item) => !skuIds.includes(item.skuId));
    }

    function clearChecked(): void {
      items.value = items.value.filter((item) => !item.checked);
    }

    function clear(): void {
      items.value = [];
    }

    /** 批量覆盖（用于服务端购物车同步 / 演示数据注入） */
    function setItems(next: CartItem[]): void {
      items.value = next;
      items.value.forEach(recalculate);
    }

    /**
     * 从服务端拉取订货单（登录态使用）。
     * 失败时保留本地数据，不影响未登录 / 离线场景。
     */
    async function loadFromServer(): Promise<void> {
      const resp = await getCartList();
      setItems(adaptCartList(resp));
    }

    return {
      items,
      checkedItems,
      totalQuantity,
      totalPrice,
      totalKinds,
      allChecked,
      addItem,
      updateQuantity,
      removeItems,
      clearChecked,
      clear,
      setItems,
      loadFromServer,
    };
  },
  {
    persist: {
      key: persistKey(STORAGE_KEYS.CART),
      pick: ['items'],
    },
  },
);
