import { ref } from 'vue';
import { appConfig } from '@/config';
import { STORAGE_KEYS } from '@/constants';
import { storage } from './storage';

/**
 * 登录凭证统一读写入口。
 *
 * 设计要点：
 * 1. 独立模块（避免 axios 与 store 循环依赖）；
 * 2. 用模块级 `ref` 承载，storage 只负责持久化——这样「清 token」后依赖它的
 *    `computed`（如 `useUserStore().isLogin`）会自动更新，解决原先
 *    「redirectToLogin 清了 storage、store 里的 ref 却不变」的状态分裂；
 * 3. accessToken / refreshToken 成对管理，供 401 静默刷新使用。
 */

const accessToken = ref<string>(storage.get<string>(STORAGE_KEYS.TOKEN, '') ?? '');
const refreshToken = ref<string>(storage.get<string>(STORAGE_KEYS.REFRESH_TOKEN, '') ?? '');

export function getToken(): string {
  return accessToken.value;
}

export function setToken(token: string): void {
  accessToken.value = token;
  storage.set(STORAGE_KEYS.TOKEN, token);
}

export function getRefreshToken(): string {
  return refreshToken.value;
}

export function setRefreshToken(token: string): void {
  refreshToken.value = token;
  storage.set(STORAGE_KEYS.REFRESH_TOKEN, token);
}

/** 成对写入登录凭证（登录成功后调用） */
export function setTokens(access: string, refresh?: string): void {
  setToken(access);
  setRefreshToken(refresh ?? '');
}

/** 清空登录凭证（accessToken + refreshToken） */
export function clearTokens(): void {
  accessToken.value = '';
  refreshToken.value = '';
  storage.remove(STORAGE_KEYS.TOKEN);
  storage.remove(STORAGE_KEYS.REFRESH_TOKEN);
}

/** @deprecated 语义模糊，请改用 clearTokens() */
export function removeToken(): void {
  clearTokens();
}

export function getTenantId(): string {
  return appConfig.tenantId;
}

export function isLogin(): boolean {
  return Boolean(accessToken.value);
}

/**
 * 统一会话重置入口：token + userInfo + 购物车 + 当前门店。
 *
 * 为什么需要：掉线（401）原先只清 token，A 账号持久化在 localStorage 里的
 * **购物车**与 **currentStoreId** 会留给下一个登录的 B 账号 —— 表现为「串号 / 下错店」。
 * 登出与掉线都走这里，保证换账号后不残留上一账号的数据。
 *
 * 放在 utils 层：axios 拦截器与各 store 都要用，而 store 反向依赖 utils；
 * stores 用**动态 import** 引入（与 router 同样的手法），避免
 * user store → utils/auth → user store 的循环依赖。
 */
export async function resetSessionState(): Promise<void> {
  clearTokens();
  try {
    const [{ useUserStore }, { useCartStore }, { useStoreStore }] = await Promise.all([
      import('@/stores/user'),
      import('@/stores/cart'),
      import('@/stores/store'),
    ]);
    useUserStore().reset();
    useCartStore().clear();
    useStoreStore().reset();
  } catch (error) {
    // 极端时序（pinia 还没安装好）不能让脏数据留在本地：退化为直接清持久化 key
    console.warn('[auth] 重置会话状态失败，退化为清理本地持久化数据:', error);
    storage.remove(STORAGE_KEYS.USER_INFO);
    storage.remove(STORAGE_KEYS.CART);
    storage.remove(STORAGE_KEYS.CURRENT_STORE);
  }
}

/** 跳转登录页（保留回跳地址），使用动态 import 规避循环依赖 */
export async function redirectToLogin(redirect?: string): Promise<void> {
  // 掉线 = 会话结束：token、会员信息、购物车、当前门店一并清掉，避免下一个账号串号
  await resetSessionState();
  const { router } = await import('@/router');
  const current = redirect ?? router.currentRoute.value.fullPath;
  if (current.startsWith('/login')) return;
  await router.replace({ path: '/login', query: { redirect: current } });
}
