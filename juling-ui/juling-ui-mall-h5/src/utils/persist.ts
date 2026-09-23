import { appConfig } from '@/config';
import { STORAGE_KEYS } from '@/constants';

/**
 * 持久化 key 统一加 `storagePrefix` 前缀。
 *
 * 为什么需要：本项目用 `VITE_STORAGE_PREFIX`（默认 `juling-mall-h5-`）隔离同域下的
 * 多个应用（见 README「环境变量 / 核心约定」），`utils/storage` 的读写也都会加前缀；
 * 但 pinia 持久化默认直接用 store id 作 key（即 `cart` / `user-info`），
 * 与同域其它应用会互相覆盖。这里集中加前缀，保证与 `storage` 封装一致。
 *
 * 注意：本模块**刻意放在 `utils/` 而不是 `stores/`**——`unplugin-auto-import`
 * 的 `dirs` 会扫描 `src/stores`，若 `persistKey` 定义在 stores 内、又被同目录的
 * store 反向 import，HMR 下容易出现模块图混乱（曾导致 `STORAGE_KEYS is not defined`）。
 */
export function persistKey(name: string): string {
  return `${appConfig.storagePrefix}${name}`;
}

/**
 * 一次性迁移：早期版本的持久化 key 未带前缀（直接是 `cart` / `user-info`）。
 * 升级时把它们搬到带前缀的新 key 上，避免老用户的订货单/会员信息“凭空丢失”。
 * 仅在新 key 不存在时搬迁，之后清理旧 key。
 */
export function migrateLegacyPersistKeys(): void {
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
