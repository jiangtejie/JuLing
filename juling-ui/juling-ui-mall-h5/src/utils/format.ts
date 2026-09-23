import { isEmpty } from './is';

/**
 * 金额统一以「分」为最小单位在后端流转，避免浮点误差。
 * 展示时再转成元。
 */
export function fenToYuan(fen: number | string | undefined, digits = 2): number {
  const value = Number(fen ?? 0);
  if (!Number.isFinite(value)) return 0;
  return Number((value / 100).toFixed(digits));
}

export function yuanToFen(yuan: number | string | undefined): number {
  const value = Number(yuan ?? 0);
  if (!Number.isFinite(value)) return 0;
  return Math.round(value * 100);
}

/** 1234567 -> '12,345.67' */
export function formatPrice(fen: number | string | undefined, digits = 2): string {
  const yuan = fenToYuan(fen, digits);
  const [int, decimal] = yuan.toFixed(digits).split('.');
  const withSeparator = int.replace(/\B(?=(\d{3})+(?!\d))/g, ',');
  return digits > 0 ? `${withSeparator}.${decimal}` : withSeparator;
}

/** 大数字缩写：12800 -> '1.28万' */
export function formatCount(count: number): string {
  if (count < 10000) return String(count);
  return `${(count / 10000).toFixed(2).replace(/\.?0+$/, '')}万`;
}

const pad = (n: number) => String(n).padStart(2, '0');

/** 轻量日期格式化，支持 YYYY MM DD HH mm ss 占位符 */
export function formatDate(
  value: Date | string | number | undefined,
  pattern = 'YYYY-MM-DD HH:mm:ss',
): string {
  if (isEmpty(value)) return '';
  const date =
    value instanceof Date
      ? value
      : typeof value === 'number'
        ? new Date(value)
        : new Date(String(value).replace(/-/g, '/'));
  if (Number.isNaN(date.getTime())) return '';
  const map: Record<string, string> = {
    YYYY: String(date.getFullYear()),
    MM: pad(date.getMonth() + 1),
    DD: pad(date.getDate()),
    HH: pad(date.getHours()),
    mm: pad(date.getMinutes()),
    ss: pad(date.getSeconds()),
  };
  return pattern.replace(/YYYY|MM|DD|HH|mm|ss/g, (key) => map[key] ?? key);
}

/** 相对时间：刚刚 / 5 分钟前 / 3 天前 */
export function formatRelativeTime(value: Date | string | number): string {
  const date =
    value instanceof Date
      ? value
      : typeof value === 'number'
        ? new Date(value)
        : new Date(String(value).replace(/-/g, '/'));
  if (Number.isNaN(date.getTime())) return '';
  const diff = Date.now() - date.getTime();
  const minute = 60 * 1000;
  const hour = 60 * minute;
  const day = 24 * hour;
  if (diff < minute) return '刚刚';
  if (diff < hour) return `${Math.floor(diff / minute)} 分钟前`;
  if (diff < day) return `${Math.floor(diff / hour)} 小时前`;
  if (diff < 30 * day) return `${Math.floor(diff / day)} 天前`;
  return formatDate(date, 'YYYY-MM-DD');
}

/** 手机号脱敏：138****8000 */
export function maskMobile(mobile?: string): string {
  if (!mobile || mobile.length < 7) return mobile ?? '';
  return `${mobile.slice(0, 3)}****${mobile.slice(-4)}`;
}
