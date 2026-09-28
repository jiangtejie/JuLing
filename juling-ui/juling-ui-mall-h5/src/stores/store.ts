import { defineStore } from 'pinia';
import { getStoreList } from '@/api/order';
import { STORAGE_KEYS } from '@/constants';
import type { StoreOption } from '@/types';
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

    function switchStore(customerId: number): void {
      currentStoreId.value = customerId;
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
