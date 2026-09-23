const env = import.meta.env;

/** 应用级配置：统一从环境变量读取，业务代码不要直接访问 import.meta.env */
export const appConfig = {
  title: env.VITE_APP_TITLE || '矩灵订货商城',
  tenantId: env.VITE_APP_TENANT_ID || '1',
  storagePrefix: env.VITE_STORAGE_PREFIX || 'juling-mall-h5-',
  apiPrefix: env.VITE_API_PREFIX || '/app-api',
  apiBaseUrl: env.VITE_API_BASE_URL || '',
  wsPath: env.VITE_WS_PATH || '/infra/ws',
  uploadType: env.VITE_UPLOAD_TYPE || 'server',
  isDev: env.DEV,
  isProd: env.PROD,
} as const;

/** axios 的 baseURL：开发环境为相对路径（交给 Vite 代理），生产环境为「根地址 + 前缀」 */
export const API_BASE_URL = `${appConfig.apiBaseUrl}${appConfig.apiPrefix}`;

/** 请求超时时间（毫秒） */
export const REQUEST_TIMEOUT = 20000;
