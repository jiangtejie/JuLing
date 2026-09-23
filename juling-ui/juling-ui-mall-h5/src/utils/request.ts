import axios, {
  type AxiosError,
  type AxiosInstance,
  type AxiosRequestConfig,
  type AxiosResponse,
  type InternalAxiosRequestConfig,
} from 'axios';
import { showToast } from 'vant';
import { API_BASE_URL, REQUEST_TIMEOUT } from '@/config';
import type { ApiResult } from '@/types';
import {
  getRefreshToken,
  getTenantId,
  getToken,
  redirectToLogin,
  setRefreshToken,
  setToken,
} from '@/utils/auth';
import { downloadBlob } from '@/utils/index';
import { createToastDeduper } from '@/utils/toast';

/** 业务异常：携带后端返回的 code，便于调用方分支处理 */
export class BizError extends Error {
  code: number;
  data?: unknown;

  constructor(message: string, code: number, data?: unknown) {
    super(message);
    this.name = 'BizError';
    this.code = code;
    this.data = data;
  }
}

/** 请求配置扩展：对外开关 + 内部标记 */
interface AppRequestConfig extends InternalAxiosRequestConfig {
  /** 关闭全局错误提示（由调用方自行处理） */
  silent?: boolean;
  /** 内部：已因 401 刷新并重放过，避免死循环 */
  retried?: boolean;
  /** 内部：跳过 401 刷新逻辑（如刷新请求本身） */
  skipAuthRefresh?: boolean;
  /** 内部：网络层重试计数 */
  retryCount?: number;
}

/* -------------------------------- 错误提示 -------------------------------- */

/**
 * 按「消息内容」去重：相同消息在窗口内合并，**不同消息各弹各的**
 * （修复原先单一时间戳全局限流导致不同错误互相吞没的问题）。
 * 去重逻辑抽到 `utils/toast` 以便单测覆盖。
 */
const shouldSuppressToast = createToastDeduper(1000);

function toastError(message: string): void {
  if (shouldSuppressToast(message)) return;
  showToast({ message, duration: 2000 });
}

/* ---------------------------- 登录失效处理（去重） ---------------------------- */

/**
 * 401 处理：清凭证 + 跳登录。
 * 并发多个 401 共享同一次跳转，避免重复清 token、重复 replace。
 */
let authFailurePromise: Promise<void> | null = null;

function handleAuthFailure(): Promise<void> {
  if (!authFailurePromise) {
    authFailurePromise = (async () => {
      // 本地有 token = 登录过期；没有 = 尚未登录。文案要区分，别让新用户看到「已过期」
      const expired = Boolean(getToken());
      toastError(expired ? '登录状态已过期，请重新登录' : '请先登录');
      await redirectToLogin();
    })().finally(() => {
      authFailurePromise = null;
    });
  }
  return authFailurePromise;
}

/* ------------------------------ Token 静默刷新 ------------------------------ */

/** 并发共享同一次刷新；用未挂拦截器的裸 axios，避免递归 */
let refreshPromise: Promise<string> | null = null;

async function doRefresh(): Promise<string> {
  const refreshToken = getRefreshToken();
  if (!refreshToken) throw new Error('NO_REFRESH_TOKEN');

  const response = await axios.request<ApiResult<{ accessToken: string; refreshToken?: string }>>({
    url: `${API_BASE_URL}/member/auth/refresh-token`,
    method: 'POST',
    params: { refreshToken },
    timeout: REQUEST_TIMEOUT,
    headers: { 'tenant-id': getTenantId() },
  });

  const body = response.data;
  const data = body?.data;
  if (!body || (body.code !== 0 && body.code !== 200) || !data?.accessToken) {
    throw new Error('REFRESH_FAILED');
  }
  setToken(data.accessToken);
  if (data.refreshToken) setRefreshToken(data.refreshToken);
  return data.accessToken;
}

function refreshAccessToken(): Promise<string> {
  if (!refreshPromise) {
    refreshPromise = doRefresh().finally(() => {
      refreshPromise = null;
    });
  }
  return refreshPromise;
}

/** 该请求是否值得「刷新后重放」 */
function canRetryWithRefresh(config?: AppRequestConfig): boolean {
  if (!config) return false;
  return !config.retried && !config.skipAuthRefresh && Boolean(getRefreshToken());
}

/** 刷新 token 后原样重放请求 */
async function retryWithRefresh(config: AppRequestConfig): Promise<unknown> {
  const token = await refreshAccessToken();
  config.retried = true;
  if (config.headers) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return service.request(config);
}

/* ------------------------------ 网络层有限重试 ------------------------------ */

const MAX_RETRY = 1;
const RETRY_BASE_DELAY = 300;

const sleep = (ms: number) => new Promise((resolve) => setTimeout(resolve, ms));

/**
 * 仅对**幂等的 GET**、且属于网络层错误 / 超时 / 5xx 时重试一次。
 * 写操作（POST/PUT/DELETE）一律不重试，避免重复下单等副作用。
 */
function shouldRetryRequest(error: AxiosError, config: AppRequestConfig): boolean {
  if ((config.method ?? 'get').toLowerCase() !== 'get') return false;
  if ((config.retryCount ?? 0) >= MAX_RETRY) return false;
  if (config.skipAuthRefresh) return false;
  const status = error.response?.status;
  const isNetwork = !error.response;
  const isTimeout = error.code === 'ECONNABORTED';
  const isServerError = status !== undefined && status >= 500;
  return isNetwork || isTimeout || isServerError;
}

/* ------------------------------- 实例与拦截器 ------------------------------- */

const service: AxiosInstance = axios.create({
  baseURL: API_BASE_URL,
  timeout: REQUEST_TIMEOUT,
  headers: { 'Content-Type': 'application/json;charset=utf-8' },
});

service.interceptors.request.use(
  (config: InternalAxiosRequestConfig) => {
    const token = getToken();
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    // 多租户：后端通过 tenant-id 头识别租户
    const tenantId = getTenantId();
    if (tenantId) {
      config.headers['tenant-id'] = tenantId;
    }
    return config;
  },
  (error: AxiosError) => Promise.reject(error),
);

service.interceptors.response.use(
  // 返回值是「解包后的业务数据」而非 AxiosResponse，故显式放宽返回类型；
  // 对外的类型安全由下面的 request<T>() 统一保证。
  async (response: AxiosResponse): Promise<any> => {
    const config = response.config as AppRequestConfig;
    const { responseType, silent } = config;

    // 二进制流（文件下载）原样返回，由调用方处理
    if (responseType === 'blob' || responseType === 'arraybuffer') {
      return response;
    }

    const payload = response.data as ApiResult | undefined;

    // 非统一包装的响应（第三方接口 / 静态 JSON）直接透传
    if (!payload || typeof payload !== 'object' || !('code' in payload)) {
      return payload;
    }

    const { code, data, msg } = payload;

    // yudao 体系：code === 0 成功；部分网关返回 200
    if (code === 0 || code === 200) {
      return data;
    }

    // 业务码 401：先尝试静默刷新并重放，失败再走统一失效处理
    if (code === 401) {
      if (canRetryWithRefresh(config)) {
        try {
          return await retryWithRefresh(config);
        } catch {
          // 刷新失败 → 落到下面
        }
      }
      await handleAuthFailure();
      return Promise.reject(new BizError(msg || '登录已过期', code, data));
    }

    if (!silent) toastError(msg || '请求失败');
    return Promise.reject(new BizError(msg || '请求失败', code, data));
  },
  async (error: AxiosError<ApiResult>) => {
    const config = error.config as AppRequestConfig | undefined;
    const status = error.response?.status;
    const bizMsg = error.response?.data?.msg;

    // HTTP 401：先尝试静默刷新并重放
    if (status === 401) {
      if (config && canRetryWithRefresh(config)) {
        try {
          return await retryWithRefresh(config);
        } catch {
          // 刷新失败 → 落到下面
        }
      }
      await handleAuthFailure();
      return Promise.reject(error);
    }

    // 网络层 / 服务端瞬时故障：幂等 GET 有限重试
    if (config && shouldRetryRequest(error, config)) {
      config.retryCount = (config.retryCount ?? 0) + 1;
      await sleep(RETRY_BASE_DELAY * config.retryCount);
      return service.request(config);
    }

    let message = bizMsg || '请求失败，请稍后重试';
    if (error.code === 'ECONNABORTED' || /timeout/i.test(error.message)) {
      message = '请求超时，请检查网络后重试';
    } else if (!error.response) {
      message = '网络连接失败，请检查网络设置';
    } else if (status === 403) {
      message = bizMsg || '没有访问该资源的权限';
    } else if (status === 404) {
      message = '请求的资源不存在';
    } else if (status && status >= 500) {
      message = bizMsg || '服务器繁忙，请稍后重试';
    }

    if (!config?.silent) toastError(message);
    return Promise.reject(error);
  },
);

/** 发起请求并拿到已解包的业务数据 */
export function request<T = unknown>(config: AxiosRequestConfig): Promise<T> {
  // 拦截器已把 { code, data, msg } 解包为 data，这里的断言与运行时行为一致
  return service.request(config) as unknown as Promise<T>;
}

type Params = Record<string, unknown> | undefined;

export const http = {
  get<T = unknown>(url: string, params?: Params, config?: AxiosRequestConfig): Promise<T> {
    return request<T>({ url, method: 'GET', params, ...config });
  },

  post<T = unknown>(url: string, data?: unknown, config?: AxiosRequestConfig): Promise<T> {
    return request<T>({ url, method: 'POST', data, ...config });
  },

  put<T = unknown>(url: string, data?: unknown, config?: AxiosRequestConfig): Promise<T> {
    return request<T>({ url, method: 'PUT', data, ...config });
  },

  delete<T = unknown>(url: string, params?: Params, config?: AxiosRequestConfig): Promise<T> {
    return request<T>({ url, method: 'DELETE', params, ...config });
  },

  /**
   * 文件上传（multipart/form-data）。
   * 不显式设置 Content-Type——交给浏览器自动补上 multipart boundary，
   * 手动写死 `multipart/form-data`（无 boundary）会导致后端解析失败。
   */
  upload<T = unknown>(url: string, file: File | Blob, extra?: Record<string, string>): Promise<T> {
    const formData = new FormData();
    formData.append('file', file);
    Object.entries(extra ?? {}).forEach(([key, value]) => formData.append(key, value));
    return request<T>({ url, method: 'POST', data: formData });
  },

  /** 文件下载：自动保存为本地文件 */
  async download(
    url: string,
    params?: Params,
    filename = 'download',
    config?: AxiosRequestConfig,
  ): Promise<void> {
    const response = (await service.request({
      url,
      method: 'GET',
      params,
      responseType: 'blob',
      ...config,
    })) as unknown as AxiosResponse<Blob>;
    downloadBlob(response.data, filename);
  },
};

export default service;
