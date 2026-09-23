/// <reference types="vite/client" />
/// <reference types="vite-plugin-pwa/client" />

/** 环境变量类型声明：与 .env / .env.[mode] 中的 VITE_ 变量一一对应 */
interface ImportMetaEnv {
  /** 应用标题 */
  readonly VITE_APP_TITLE: string;
  /** 租户 ID */
  readonly VITE_APP_TENANT_ID: string;
  /** 本地存储 key 前缀 */
  readonly VITE_STORAGE_PREFIX: string;
  /** 接口前缀，如 /app-api */
  readonly VITE_API_PREFIX: string;
  /** 接口根地址，同源部署时留空 */
  readonly VITE_API_BASE_URL: string;
  /** 开发环境代理目标 */
  readonly VITE_API_PROXY_TARGET: string;
  /** 是否启用开发代理 */
  readonly VITE_USE_PROXY: string;
  /** WebSocket 前缀 */
  readonly VITE_WS_PATH: string;
  /** 上传方式：server | client */
  readonly VITE_UPLOAD_TYPE: 'server' | 'client';
  /** 开发服务器端口 */
  readonly VITE_PORT: string;
  /** 生产构建是否剔除 console */
  readonly VITE_DROP_CONSOLE: string;
  /** 是否启用 PWA */
  readonly VITE_PWA: string;
  /** 是否开启打包体积分析 */
  readonly VITE_REPORT?: string;
}

interface ImportMeta {
  readonly env: ImportMetaEnv;
}
