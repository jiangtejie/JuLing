import type { Router } from 'vue-router';

import { LOGIN_PATH } from '@vben/constants';
import { $t } from '@vben/locales';
import { preferences } from '@vben/preferences';
import { useAccessStore, useDictStore, useUserStore } from '@vben/stores';
import { startProgress, stopProgress } from '@vben/utils';

import { message } from 'antdv-next';

import { getSimpleDictDataList } from '#/api/system/dict/data';
import { accessRoutes, coreRouteNames } from '#/router/routes';
import { useAuthStore } from '#/store';

import { generateAccess } from './access';

/** 全局 404 兜底路由的名称，定义见 router/routes/core.ts */
const FALLBACK_NOT_FOUND_ROUTE_NAME = 'FallbackNotFound';

/** 菜单节点（只取兜底逻辑需要的字段），避免额外引入类型依赖 */
interface AccessibleMenuLike {
  children?: AccessibleMenuLike[];
  path?: string;
  show?: boolean;
}

/** 判断是否命中了 404 兜底路由 */
function isFallbackNotFound(matched: { name?: unknown }[]): boolean {
  return matched.some((route) => route.name === FALLBACK_NOT_FOUND_ROUTE_NAME);
}

/**
 * 获取当前用户可访问的第一个菜单路径。
 *
 * 用途：当默认首页（preferences.app.defaultHomePath）对应的菜单未被授权给当前角色时，
 * 登录后会命中 404 兜底路由。此方法用于改跳该用户可访问的第一个菜单，避免用户直接看到 404。
 */
function getFirstAccessiblePath(
  menus?: AccessibleMenuLike[],
): string | undefined {
  if (!Array.isArray(menus)) {
    return undefined;
  }
  for (const menu of menus) {
    const childPath = getFirstAccessiblePath(menu?.children);
    if (childPath) {
      return childPath;
    }
    const path = menu?.path;
    const isLeaf = !menu?.children || menu.children.length === 0;
    if (
      isLeaf &&
      menu?.show !== false &&
      typeof path === 'string' &&
      path.startsWith('/') &&
      !path.startsWith('//')
    ) {
      return path;
    }
  }
  return undefined;
}

/**
 * 通用守卫配置
 * @param router
 */
function setupCommonGuard(router: Router) {
  // 记录已经加载的页面
  const loadedPaths = new Set<string>();

  router.beforeEach((to) => {
    to.meta.loaded = loadedPaths.has(to.path);

    // 页面加载进度条
    if (!to.meta.loaded && preferences.transition.progress) {
      startProgress();
    }
    return true;
  });

  router.afterEach((to) => {
    // 记录页面是否加载,如果已经加载，后续的页面切换动画等效果不在重复执行

    loadedPaths.add(to.path);

    // 关闭页面加载进度条
    if (preferences.transition.progress) {
      stopProgress();
    }
  });
}

/**
 * 权限访问守卫配置
 * @param router
 */
function setupAccessGuard(router: Router) {
  router.beforeEach(async (to, from) => {
    const accessStore = useAccessStore();
    const userStore = useUserStore();
    const authStore = useAuthStore();
    const dictStore = useDictStore();

    // 基本路由，这些路由不需要进入权限拦截
    if (coreRouteNames.includes(to.name as string)) {
      if (to.path === LOGIN_PATH && accessStore.accessToken) {
        return decodeURIComponent(
          (to.query?.redirect as string) ||
            userStore.userInfo?.homePath ||
            preferences.app.defaultHomePath,
        );
      }
      return true;
    }

    // accessToken 检查
    if (!accessStore.accessToken) {
      // 明确声明忽略权限访问权限，则可以访问
      if (to.meta.ignoreAccess) {
        return true;
      }

      // 没有访问权限，跳转登录页面
      if (to.fullPath !== LOGIN_PATH) {
        return {
          path: LOGIN_PATH,
          // 如不需要，直接删除 query
          query:
            to.fullPath === preferences.app.defaultHomePath
              ? {}
              : { redirect: encodeURIComponent(to.fullPath) },
          // 携带当前跳转的页面，登录后重新跳转该页面
          replace: true,
        };
      }
      return to;
    }

    // 是否已经生成过动态路由
    if (accessStore.isAccessChecked) {
      // 兜底：默认首页未被授权给当前角色时会命中 404 兜底路由；
      // 此时改跳该用户可访问的第一个菜单，避免登录后直接看到 404 页面
      if (
        isFallbackNotFound(to.matched) &&
        to.path ===
          (userStore.userInfo?.homePath ?? preferences.app.defaultHomePath)
      ) {
        const fallbackPath = getFirstAccessiblePath(
          accessStore.accessMenus as unknown as AccessibleMenuLike[],
        );
        if (fallbackPath && fallbackPath !== to.path) {
          return { path: fallbackPath, replace: true };
        }
      }
      return true;
    }

    // 加载字典数据（不阻塞加载）
    dictStore.setDictCacheByApi(getSimpleDictDataList);

    // 生成路由表
    // 当前登录用户拥有的角色标识列表
    let userInfo = userStore.userInfo;
    if (!userInfo) {
      // add by 棱信矩灵：由于矩灵是 fetchUserInfo 统一加载用户 + 权限信息，所以将 fetchMenuListAsync
      const loading = message.loading({
        content: `${$t('common.loadingMenu')}...`,
      });
      try {
        const authPermissionInfo = await authStore.fetchUserInfo();
        if (authPermissionInfo) {
          userInfo = authPermissionInfo.user;
        }
      } finally {
        loading();
      }
    }
    const userRoles = userStore.userRoles ?? [];

    // 生成菜单和路由
    const { accessibleMenus, accessibleRoutes } = await generateAccess({
      roles: userRoles,
      router,
      // 则会在菜单中显示，但是访问会被重定向到403
      routes: accessRoutes,
    });

    // 保存菜单信息和路由信息
    accessStore.setAccessMenus(accessibleMenus);
    accessStore.setAccessRoutes(accessibleRoutes);
    accessStore.setIsAccessChecked(true);
    userStore.setUserRoles(userRoles);
    const homePath = (userInfo?.homePath ||
      preferences.app.defaultHomePath) as string;
    const redirectPath = (from.query.redirect ??
      (to.path === preferences.app.defaultHomePath
        ? homePath
        : to.fullPath)) as string;

    // 兜底：默认首页未被授权给当前角色时，改跳该用户可访问的第一个菜单
    const resolved = router.resolve(decodeURIComponent(redirectPath));
    if (
      isFallbackNotFound(resolved.matched) &&
      decodeURIComponent(redirectPath) === homePath
    ) {
      const fallbackPath = getFirstAccessiblePath(
        accessibleMenus as unknown as AccessibleMenuLike[],
      );
      if (fallbackPath) {
        return { ...router.resolve(fallbackPath), replace: true };
      }
    }

    return {
      ...resolved,
      replace: true,
    };
  });
}

/**
 * 项目守卫配置
 * @param router
 */
function createRouterGuard(router: Router) {
  /** 通用 */
  setupCommonGuard(router);
  /** 权限访问 */
  setupAccessGuard(router);
}

export { createRouterGuard };
