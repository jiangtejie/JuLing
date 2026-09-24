/**
 * 资源地址归一化（纯函数，便于单测）。
 *
 * 背景：yudao 后端返回的文件地址是**绝对 URL**，host 取自后端自身配置，
 * 常见形态是 `http://127.0.0.1:48080/admin-api/infra/file/...`。直接使用会有两个问题：
 * 1. 公网访问时，浏览器会去请求**访问者自己**的 127.0.0.1，图片必然失败；
 * 2. 站点是 https 时，加载 http 图片还会被浏览器按混合内容拦截。
 *
 * 处理办法：把「本机 / 内网」来源的绝对地址改写为同源相对路径（保留路径部分），
 * 交由当前站点的 nginx（生产）或 vite 代理（开发）转发到后端。
 * 公网 CDN 等正常域名不做改动。
 */

/** 本机 / 内网地址（127.0.0.1、localhost、10.x、192.168.x、172.16-31.x、::1），可带端口 */
const INTRANET_ORIGIN =
  /^https?:\/\/(?:127\.\d{1,3}\.\d{1,3}\.\d{1,3}|localhost|0\.0\.0\.0|\[::1\]|10\.\d{1,3}\.\d{1,3}\.\d{1,3}|192\.168\.\d{1,3}\.\d{1,3}|172\.(?:1[6-9]|2\d|3[01])\.\d{1,3}\.\d{1,3})(?::\d+)?/i;

/**
 * 把内网 / 本机的绝对资源地址归一化为同源相对路径。
 * - `http://127.0.0.1:48080/admin-api/infra/file/1/a.png` → `/admin-api/infra/file/1/a.png`
 * - `https://cdn.example.com/a.png` → 原样返回
 * - 相对路径 `/admin-api/...` → 原样返回
 */
export function normalizeAssetUrl(url?: string | null): string {
  const trimmed = (url ?? '').trim();
  if (!trimmed) return '';
  return trimmed.replace(INTRANET_ORIGIN, '');
}

/**
 * 可选图片地址的归一化：空值保持原样（`undefined` / `''` 的语义不变，避免把「无图」变成空串）。
 * adapter 层用它做统一收口，视图层再经 `resolveImage` 兜底占位图。
 */
export function normalizeOptionalAssetUrl(url?: string | null): string | undefined {
  return url ? normalizeAssetUrl(url) : (url ?? undefined);
}
