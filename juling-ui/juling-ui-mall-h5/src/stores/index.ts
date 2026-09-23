import { createPinia } from 'pinia';
import piniaPluginPersistedstate from 'pinia-plugin-persistedstate';
import type { App } from 'vue';
import { migrateLegacyPersistKeys } from '@/utils/persist';

export const pinia = createPinia();

// 升级迁移：把旧的无前缀持久化 key 搬到带前缀的新 key（规则见 utils/persist）
migrateLegacyPersistKeys();

// 状态持久化：刷新页面不丢失购物车 / 登录信息
pinia.use(piniaPluginPersistedstate);

export function setupStore(app: App): void {
  app.use(pinia);
}
