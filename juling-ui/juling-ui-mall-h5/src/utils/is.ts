const toString = Object.prototype.toString;

export const isArray = Array.isArray;
export const isDate = (value: unknown): value is Date => toString.call(value) === '[object Date]';

export const isObject = (value: unknown): value is Record<string, unknown> =>
  value !== null && typeof value === 'object';

/** 空值判断：null / undefined / '' / [] / {} 均视为空 */
export function isEmpty(value: unknown): boolean {
  if (value === null || value === undefined || value === '') return true;
  if (isArray(value)) return value.length === 0;
  if (isDate(value)) return false;
  if (isObject(value)) return Object.keys(value).length === 0;
  return false;
}

/** 中国大陆手机号 */
export const isMobile = (value: string): boolean => /^1[3-9]\d{9}$/.test(value);

/**
 * 订货账号：总部下发给订货人的登录账号，就是订货人姓名（如「张三」）。
 * 允许中文 / 字母 / 数字，长度 2-64 位（与后端校验对齐），前后空白自动忽略。
 */
export function isAccount(value: string): boolean {
  const account = value.trim();
  return account.length >= 2 && account.length <= 64;
}
