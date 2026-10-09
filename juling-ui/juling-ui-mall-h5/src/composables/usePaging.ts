import type { Ref } from 'vue';
import type { PageParam, PageResult } from '@/types';
import { DEFAULT_PAGE_SIZE } from '@/constants';

export interface UsePagingOptions<P> {
  /** 每页条数 */
  pageSize?: number;
  /** 是否在挂载后立即加载，默认 true */
  immediate?: boolean;
  /** 默认查询参数 */
  defaultParams?: Partial<P>;
}

/**
 * 分页列表通用逻辑，配合 <van-list> / <van-pull-refresh> 使用。
 *
 * const { list, loading, finished, refreshing, onLoad, onRefresh } = usePaging(
 *   (params) => getProductPage(params),
 *   { defaultParams: { keyword: '' } },
 * )
 */
export function usePaging<T, P extends object = Record<string, unknown>>(
  fetcher: (params: P & PageParam) => Promise<PageResult<T>>,
  options: UsePagingOptions<P> = {},
) {
  const { pageSize = DEFAULT_PAGE_SIZE, immediate = true, defaultParams } = options;

  const list = ref<T[]>([]) as Ref<T[]>;
  const total = ref(0);
  const pageNo = ref(1);
  const loading = ref(false);
  const finished = ref(false);
  const error = ref(false);
  const refreshing = ref(false);
  const params = ref({ ...(defaultParams ?? {}) } as Partial<P>);
  // 请求序号：快速切换筛选条件/页签时，先发出的旧请求可能后返回，
  // 用它丢弃过期响应，避免旧数据覆盖当前列表
  let requestSeq = 0;

  /** 加载下一页（绑定到 van-list 的 @load） */
  async function onLoad(): Promise<void> {
    if (finished.value) {
      loading.value = false;
      return;
    }
    const seq = (requestSeq += 1);
    loading.value = true;
    error.value = false;
    try {
      const result = await fetcher({
        ...(params.value as P),
        pageNo: pageNo.value,
        pageSize,
      });
      if (seq !== requestSeq) {
        return; // 已被更新的请求取代，丢弃本次结果
      }
      const rows = result?.list ?? [];
      list.value = pageNo.value === 1 ? rows : [...list.value, ...rows];
      total.value = result?.total ?? list.value.length;
      pageNo.value += 1;
      finished.value = list.value.length >= total.value || rows.length < pageSize;
    } catch {
      if (seq !== requestSeq) {
        return;
      }
      error.value = true;
      finished.value = false;
    } finally {
      if (seq === requestSeq) {
        loading.value = false;
        refreshing.value = false;
      }
    }
  }

  /** 下拉刷新 */
  async function onRefresh(): Promise<void> {
    refreshing.value = true;
    await reset();
  }

  /** 回到第一页重新查询 */
  async function reset(): Promise<void> {
    requestSeq += 1; // 作废仍在途的旧请求
    pageNo.value = 1;
    finished.value = false;
    list.value = [];
    await onLoad();
  }

  /** 合并查询条件后重新查询 */
  async function search(next?: Partial<P>): Promise<void> {
    if (next) params.value = { ...params.value, ...next };
    await reset();
  }

  if (immediate) {
    onMounted(() => {
      if (!list.value.length && !loading.value) void onLoad();
    });
  }

  return {
    list,
    total,
    pageNo,
    loading,
    finished,
    error,
    refreshing,
    params,
    onLoad,
    onRefresh,
    reset,
    search,
  };
}
