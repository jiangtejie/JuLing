import { appConfig } from '@/config';

type StorageType = 'local' | 'session';

function getStorage(type: StorageType): Storage | undefined {
  if (typeof window === 'undefined') return undefined;
  return type === 'session' ? window.sessionStorage : window.localStorage;
}

const withPrefix = (key: string) => `${appConfig.storagePrefix}${key}`;

/**
 * 带前缀 + JSON 序列化的本地存储封装。
 * 读写异常（隐私模式 / 容量超限 / 脏数据）一律静默降级，不阻断业务。
 */
export const storage = {
  get<T>(key: string, defaultValue?: T, type: StorageType = 'local'): T | undefined {
    const raw = getStorage(type)?.getItem(withPrefix(key));
    if (raw === null || raw === undefined || raw === '') return defaultValue;
    try {
      return JSON.parse(raw) as T;
    } catch {
      // 兼容历史遗留的非 JSON 字符串
      return raw as unknown as T;
    }
  },

  set(key: string, value: unknown, type: StorageType = 'local'): void {
    try {
      getStorage(type)?.setItem(withPrefix(key), JSON.stringify(value));
    } catch (error) {
      console.warn('[storage] 写入失败:', key, error);
    }
  },

  remove(key: string, type: StorageType = 'local'): void {
    getStorage(type)?.removeItem(withPrefix(key));
  },

  /** 仅清理本应用前缀下的数据，不影响同域其它应用 */
  clear(type: StorageType = 'local'): void {
    const target = getStorage(type);
    if (!target) return;
    const keys: string[] = [];
    for (let i = 0; i < target.length; i++) {
      const key = target.key(i);
      if (key?.startsWith(appConfig.storagePrefix)) keys.push(key);
    }
    keys.forEach((key) => target.removeItem(key));
  },
};
