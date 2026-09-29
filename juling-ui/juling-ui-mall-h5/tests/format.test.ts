import assert from 'node:assert/strict';
import { test } from 'node:test';

import {
  formatCount,
  formatDate,
  formatPrice,
  formatQuantity,
  maskMobile,
} from '../src/utils/format.ts';

/**
 * 金额 / 数量 / 时间的展示边界。
 * 这些函数出现在每一张列表卡片上，格式化错一位就是「113.00 元」变成「11300.00 元」。
 */

/* ------------------------------ 金额 ------------------------------ */

test('formatPrice：分 → 元，带千分位与两位小数', () => {
  assert.equal(formatPrice(1234567), '12,345.67');
  assert.equal(formatPrice(0), '0.00');
  assert.equal(formatPrice(5), '0.05');
  assert.equal(formatPrice(100), '1.00');
});

test('formatPrice：空值与非法值按 0 处理，不出现 NaN', () => {
  assert.equal(formatPrice(undefined), '0.00');
  assert.equal(formatPrice(null as unknown as undefined), '0.00');
  assert.equal(formatPrice('abc' as unknown as number), '0.00');
});

test('formatPrice：digits=0 时不带小数位（四舍五入到元）', () => {
  assert.equal(formatPrice(1234567, 0), '12,346');
  assert.equal(formatPrice(100, 0), '1');
});

/* ------------------------------ 数量 ------------------------------ */

test('formatQuantity：去掉无意义的尾随 0', () => {
  assert.equal(formatQuantity(10), '10');
  assert.equal(formatQuantity(10.0), '10');
  assert.equal(formatQuantity(9.5), '9.5');
  // 后端 numeric(24,6) 常常下发字符串
  assert.equal(formatQuantity('2.000'), '2');
  assert.equal(formatQuantity('0.250'), '0.25');
});

test('formatQuantity：空值 / NaN / 非数字一律回落 "0"', () => {
  assert.equal(formatQuantity(undefined), '0');
  assert.equal(formatQuantity(null as unknown as undefined), '0');
  assert.equal(formatQuantity(Number.NaN), '0');
  assert.equal(formatQuantity(Number.POSITIVE_INFINITY), '0');
  assert.equal(formatQuantity('abc' as unknown as number), '0');
});

test('formatQuantity：最多 3 位小数（四舍五入）', () => {
  assert.equal(formatQuantity(1.23456), '1.235');
  assert.equal(formatQuantity(1.0004), '1');
});

/* ------------------------------ 时间 ------------------------------ */

test('formatDate：默认到秒，支持自定义占位符', () => {
  const date = new Date(2026, 8, 27, 9, 5, 3);
  assert.equal(formatDate(date), '2026-09-27 09:05:03');
  assert.equal(formatDate(date, 'MM-DD HH:mm'), '09-27 09:05');
  assert.equal(formatDate(date, 'YYYY/MM/DD'), '2026/09/27');
});

test('formatDate：空值 / 非法值返回空串（页面据此显示占位）', () => {
  assert.equal(formatDate(undefined), '');
  assert.equal(formatDate(''), '');
  assert.equal(formatDate('not-a-date'), '');
});

test('formatDate：数字时间戳与 "yyyy-MM-dd HH:mm:ss" 字符串都能解析', () => {
  const timestamp = new Date(2026, 0, 1, 10, 0, 0).getTime();
  assert.equal(formatDate(timestamp, 'YYYY-MM-DD HH:mm'), '2026-01-01 10:00');
  // iOS Safari 不接受 "2026-01-01 10:00:00"，函数内部已把 - 换成 /
  assert.equal(formatDate('2026-01-01 10:00:00', 'YYYY-MM-DD HH:mm'), '2026-01-01 10:00');
});

test('formatDate：位数不足自动补 0', () => {
  assert.equal(formatDate(new Date(2026, 0, 2, 3, 4, 5), 'MM-DD HH:mm:ss'), '01-02 03:04:05');
});

/* ------------------------------ 其它 ------------------------------ */

test('formatCount：万级缩写', () => {
  assert.equal(formatCount(9999), '9999');
  assert.equal(formatCount(12800), '1.28万');
  assert.equal(formatCount(10000), '1万');
});

test('maskMobile：脱敏并保留首尾，长度不足 7 位原样返回', () => {
  assert.equal(maskMobile('13800138000'), '138****8000');
  assert.equal(maskMobile(undefined), '');
  assert.equal(maskMobile('12345'), '12345');
});
