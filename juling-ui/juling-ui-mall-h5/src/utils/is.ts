const toString = Object.prototype.toString;

export const isString = (value: unknown): value is string => typeof value === 'string';
export const isNumber = (value: unknown): value is number =>
  typeof value === 'number' && !Number.isNaN(value);
export const isBoolean = (value: unknown): value is boolean => typeof value === 'boolean';
export const isFunction = (value: unknown): value is (...args: never[]) => unknown =>
  typeof value === 'function';
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
 * 订货账号：总部下发的门店登录账号（通常就是门店名）。
 * 允许中文 / 字母 / 数字，长度 2-64 位（与后端校验对齐），前后空白自动忽略。
 */
export function isAccount(value: string): boolean {
  const account = value.trim();
  return account.length >= 2 && account.length <= 64;
}

export const isExternal = (path: string): boolean => /^(https?:|mailto:|tel:)/.test(path);
