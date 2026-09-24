import { showToast } from 'vant';
import type { Router } from 'vue-router';
import { appConfig } from '@/config';
import { useAppStore } from '@/stores/app';
import { isLogin } from '@/utils/auth';

/** 无需登录即可访问的路径 */
const WHITE_LIST = ['/login'];

export function setupRouterGuard(router: Router): void {
  router.beforeEach((to) => {
    // 1. 登录校验
    if (to.meta.auth && !isLogin() && !WHITE_LIST.includes(to.path)) {
      showToast('请先登录');
      return { path: '/login', query: { redirect: to.fullPath } };
    }

    // 2. 已登录用户访问登录页 -> 直接回首页
    if (to.path === '/login' && isLogin()) {
      return { path: '/' };
    }

    return true;
  });

  router.afterEach((to) => {
    // 3. 页面标题
    document.title = to.meta.title ? `${to.meta.title} · ${appConfig.title}` : appConfig.title;

    // 4. 登记需要缓存的页面（组件 name 与路由 name 一致）
    if (to.meta.keepAlive && typeof to.name === 'string') {
      useAppStore().addCachedView(to.name);
    }
  });
}
