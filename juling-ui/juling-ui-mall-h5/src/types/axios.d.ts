import 'axios';

declare module 'axios' {
  export interface AxiosRequestConfig {
    /**
     * 静默模式：请求失败时不弹出全局 toast。
     *
     * 仅用于「失败由调用方自己呈现」的场景。置为 true 后业务错误（后端返回的
     * `{ code, msg }`）**不会**被全局拦截器展示，调用方**必须**在 catch 中自行处理，
     * 否则会出现「操作无任何反馈」的静默失败。
     */
    silent?: boolean;
  }
}
