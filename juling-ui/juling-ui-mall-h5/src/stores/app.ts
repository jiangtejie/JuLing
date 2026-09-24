import { defineStore } from 'pinia';

/**
 * 应用级状态：页面缓存、网络状态、安全区等。
 */
export const useAppStore = defineStore('app', () => {
  /** keep-alive 缓存的组件名集合（与路由 name 一致） */
  const cachedViews = ref<string[]>([]);

  const online = useOnline();

  /** 是否离线 */
  const isOffline = computed(() => !online.value);

  function addCachedView(name?: string | symbol | null): void {
    if (typeof name !== 'string' || cachedViews.value.includes(name)) return;
    cachedViews.value.push(name);
  }

  function removeCachedView(name: string): void {
    cachedViews.value = cachedViews.value.filter((item) => item !== name);
  }

  function clearCachedViews(): void {
    cachedViews.value = [];
  }

  return {
    cachedViews,
    online,
    isOffline,
    addCachedView,
    removeCachedView,
    clearCachedViews,
  };
});
