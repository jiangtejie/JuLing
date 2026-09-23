import assert from 'node:assert/strict';
import { test } from 'node:test';

import { createToastDeduper } from '../src/utils/toast.ts';

test('相同消息在窗口内被抑制', () => {
  const shouldSuppress = createToastDeduper(1000);
  assert.equal(shouldSuppress('登录状态已过期，请重新登录', 0), false);
  assert.equal(shouldSuppress('登录状态已过期，请重新登录', 500), true);
  assert.equal(shouldSuppress('登录状态已过期，请重新登录', 999), true);
});

test('超出窗口后相同消息重新放行', () => {
  const shouldSuppress = createToastDeduper(1000);
  assert.equal(shouldSuppress('请求超时', 0), false);
  assert.equal(shouldSuppress('请求超时', 1000), false);
});

test('不同消息互不影响（原全局限流的缺陷）', () => {
  const shouldSuppress = createToastDeduper(1000);
  assert.equal(shouldSuppress('库存不足', 0), false);
  // 关键断言：紧接着的另一条不同错误必须能显示出来
  assert.equal(shouldSuppress('网络连接失败，请检查网络设置', 100), false);
  // 而重复的第一条仍应被抑制
  assert.equal(shouldSuppress('库存不足', 200), true);
});

test('窗口边界：恰好等于 windowMs 时放行', () => {
  const shouldSuppress = createToastDeduper(1000);
  assert.equal(shouldSuppress('A', 0), false);
  assert.equal(shouldSuppress('A', 999), true);
  assert.equal(shouldSuppress('A', 1000), false);
});

test('无消息历史时一律放行', () => {
  const shouldSuppress = createToastDeduper(1000);
  assert.equal(shouldSuppress('A', 0), false);
  assert.equal(shouldSuppress('B', 1), false);
  assert.equal(shouldSuppress('C', 2), false);
});
