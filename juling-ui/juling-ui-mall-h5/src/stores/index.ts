import { createPinia } from 'pinia';
import piniaPluginPersistedstate from 'pinia-plugin-persistedstate';
import type { App } from 'vue';
import { appConfig } from '@/config';
import { STORAGE_KEYS } from '@/constants';

export const pinia = createPinia();

/**
 * 持久化 key 统一加 `storagePrefix` 前缀。
 *
 * 为什么需要：本项目用 `VITE_STORAGE_PREFIX`（默认 `juling-mall-h5-`）隔离同域下的
 * 多个应用（见 README「环境变量 / 核心约定」），`utils/storage` 的读写也都会加前缀；
 * 但 pinia 持久化默认直接用 store id 作 key（即 `cart` / `user-info`），
 * 与同域其它应用会互相覆盖。这里集中加前缀，保证与 `storage` 封装一致。
 */
export function persistKey(name: string): string {
  return `${appConfig.storagePrefix}${name}`;
}

/**
 * 一次性迁移：早期版本的持久化 key 未带前缀（直接是 `cart` / `user-info`）。
 * 升级时把它们搬到带前缀的新 key 上，避免老用户的订货单/会员信息“凭空丢失”。
 * 仅在新 key 不存在时搬迁，之后清理旧 key。
 */
function migrateLegacyPersistKeys(): void {
  if (typeof window === 'undefined') return;
  [STORAGE_KEYS.CART, STORAGE_KEYS.USER_INFO].forEach((name) => {
    const legacyValue = window.localStorage.getItem(name);
    if (legacyValue === null) return;
    const nextKey = persistKey(name);
    if (window.localStorage.getItem(nextKey) === null) {
      window.localStorage.setItem(nextKey, legacyValue);
    }
    window.localStorage.removeItem(name);
  });
}

migrateLegacyPersistKeys();

// 状态持久化：刷新页面不丢失购物车 / 登录信息
pinia.use(piniaPluginPersistedstate);

export function setupStore(app: App): void {
  app.use(pinia);
}
