import { defineStore } from 'pinia';
import {
  login as loginApi,
  loginBySms as loginBySmsApi,
  logout as logoutApi,
  getProfile,
} from '@/api/auth';
import { STORAGE_KEYS } from '@/constants';
import type { LoginParam, UserInfo } from '@/types';
import { clearTokens, getToken, setTokens } from '@/utils/auth';
import { persistKey } from '@/utils/persist';

/**
 * 用户状态。
 *
 * token 的单一数据源在 `utils/auth`（响应式 ref + storage 持久化），
 * store 不再另存一份 token，只用 `computed` 读取——避免出现
 * 「storage 已清空、store 的 isLogin 仍为 true」的状态分裂。
 */
export const useUserStore = defineStore(
  'user',
  () => {
    const userInfo = ref<UserInfo | null>(null);

    /** 响应式登录态：直接跟随 utils/auth 的 token（不再本地缓存副本） */
    const token = computed(() => getToken());
    const isLogin = computed(() => Boolean(token.value));
    const nickname = computed(() => userInfo.value?.nickname || '未登录');
    const avatar = computed(() => userInfo.value?.avatar || '');

    /** 账号密码登录 */
    async function login(param: LoginParam): Promise<void> {
      const result = await loginApi(param);
      // 成对写入 accessToken + refreshToken（后者用于 401 静默刷新）
      setTokens(result.accessToken, result.refreshToken);
      await fetchProfile();
    }

    /** 短信验证码登录 */
    async function loginBySms(param: { mobile: string; code: string }): Promise<void> {
      const result = await loginBySmsApi(param);
      setTokens(result.accessToken, result.refreshToken);
      await fetchProfile();
    }

    /** 拉取会员信息 */
    async function fetchProfile(): Promise<UserInfo | null> {
      if (!token.value) return null;
      userInfo.value = await getProfile();
      return userInfo.value;
    }

    /** 退出登录（接口失败也要清理本地状态） */
    async function logout(): Promise<void> {
      try {
        await logoutApi();
      } catch {
        // 忽略：本地状态必须清理
      } finally {
        reset();
      }
    }

    function reset(): void {
      userInfo.value = null;
      clearTokens();
    }

    return {
      token,
      userInfo,
      isLogin,
      nickname,
      avatar,
      login,
      loginBySms,
      fetchProfile,
      logout,
      reset,
    };
  },
  {
    // 仅持久化会员信息，token 由 utils/auth 单独管理
    persist: {
      key: persistKey(STORAGE_KEYS.USER_INFO),
      pick: ['userInfo'],
    },
  },
);
