import type { App } from 'vue';
import { createRouter, createWebHashHistory } from 'vue-router';
import { setupRouterGuard } from './guard';
import { routes } from './routes';

/**
 * Hash 模式：地址形如 https://host/#/order/list
 * 在微信公众号、APP 内嵌 WebView、静态托管等场景下无需服务端配置 rewrite，兼容性最好。
 * 若后续需要 SEO，可切换为 createWebHistory 并配置 nginx try_files。
 */
export const router = createRouter({
  history: createWebHashHistory(),
  routes,
  scrollBehavior: (_to, _from, savedPosition) => savedPosition ?? { left: 0, top: 0 },
});

export function setupRouter(app: App): void {
  setupRouterGuard(router);
  app.use(router);
}

export * from './routes';
