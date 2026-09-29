import { defineStore } from 'pinia';
import { getStoreList } from '@/api/order';
import { useCartStore } from '@/stores/cart';
import { STORAGE_KEYS } from '@/constants';
import type { StoreOption } from '@/types';
import { confirmDialog } from '@/utils/confirm';
import { persistKey } from '@/utils/persist';

/**
 * 下单门店状态（门店订货链 S1）。
 *
 * 背景：一个代理/经销商可能在多个品牌下拥有多家门店，若下错门店会把 A 店的货下到 B 店。
 * 因此账号登录后拉取"可下单门店"，并在下单页显式展示当前门店、允许切换。
 */
export const useStoreStore = defineStore(
  'store',
  () => {
    const stores = ref<StoreOption[]>([]);
    const currentStoreId = ref<number | null>(null);
    const loading = ref(false);

    /** 当前门店：未选择时取第一个（后端返回的第一个为默认门店） */
    const currentStore = computed<StoreOption | null>(
      () =>
        stores.value.find((item) => item.customerId === currentStoreId.value) ??
        stores.value[0] ??
        null,
    );

    /** 拉取可下单门店；账号未绑定门店时由后端报错提示 */
    async function fetchStores(): Promise<StoreOption[]> {
      loading.value = true;
      try {
        const list = await getStoreList();
        stores.value = list ?? [];
        if (!stores.value.some((item) => item.customerId === currentStoreId.value)) {
          currentStoreId.value = stores.value[0]?.customerId ?? null;
        }
        return stores.value;
      } finally {
        loading.value = false;
      }
    }

    /**
     * 切换下单门店。
     *
     * 下错门店 = 把 A 店的货下到 B 店（订单会快照客户 / 组织，后续发货与对账都跟着走），
     * 所以这里做两件事：
     * 1. **二次确认**：明确告知切到哪家店，避免误触；切到同一门店时直接返回，不打扰；
     * 2. **清理与该门店相关的脏状态**：订货单里的单价按门店取（配送价目表按客户 / 门店），
     *    切店后旧行项的价格可能不适用，直接清空，避免拿别家门店的价格下单。
     *
     * 注：确认弹窗放在 store 里，是因为调用方（下单页）不在本次改动范围内；
     * 调用方应 await 本方法，未确认时不要自行把「已选门店」置为新门店。
     *
     * @returns 是否真的发生了切换（用户取消 / 同门店 → false）
     */
    async function switchStore(
      customerId: number,
      options?: { skipConfirm?: boolean },
    ): Promise<boolean> {
      if (currentStoreId.value === customerId) return false;
      const target = stores.value.find((item) => item.customerId === customerId);
      const storeName = target?.customerName || `门店 ${customerId}`;
      if (!options?.skipConfirm) {
        const confirmed = await confirmDialog(
          `确认把下单门店切换为「${storeName}」？切换门店会清空当前订货单。`,
          '切换下单门店',
        );
        if (!confirmed) return false;
      }
      currentStoreId.value = customerId;
      // 门店相关的脏状态：订货单价格随门店变化，切店后必须失效
      useCartStore().clear();
      return true;
    }

    function reset(): void {
      stores.value = [];
      currentStoreId.value = null;
    }

    return { stores, currentStoreId, currentStore, loading, fetchStores, switchStore, reset };
  },
  {
    // 仅持久化"当前门店"，门店列表每次登录后重新拉取（权限可能变化）
    persist: {
      key: persistKey(STORAGE_KEYS.CURRENT_STORE),
      pick: ['currentStoreId'],
    },
  },
);
