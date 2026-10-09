import assert from 'node:assert/strict';
import { test } from 'node:test';

import { deriveOrderStatusView } from '../src/constants/index.ts';

test('待发货 + 待提交(0) / 审核中(10) → 统一显示「处理中」（内部细节不外露）', () => {
  assert.deepEqual(deriveOrderStatusView('PAID', 0), {
    color: 'var(--app-primary-color)',
    text: '处理中',
  });
  assert.deepEqual(deriveOrderStatusView('PAID', 10), {
    color: 'var(--app-primary-color)',
    text: '处理中',
  });
});

test('待发货 + 已驳回 → 审核未通过（需要门店重新上传凭证）', () => {
  assert.deepEqual(deriveOrderStatusView('PAID', 30), {
    color: 'var(--app-danger-color)',
    text: '审核未通过',
  });
});

test('待发货 + 审批通过 / 历史无审核状态 → 显示待发货', () => {
  assert.equal(deriveOrderStatusView('PAID', 20).text, '待发货');
  assert.equal(deriveOrderStatusView('PAID').text, '待发货');
});

test('其它状态沿用原订单状态映射', () => {
  assert.equal(deriveOrderStatusView('UNPAID').text, '待付款');
  assert.equal(deriveOrderStatusView('SHIPPED', 20).text, '待收货');
  assert.equal(deriveOrderStatusView('COMPLETED').text, '已完成');
  assert.equal(deriveOrderStatusView('CANCELED').text, '已取消');
});

test('未知状态兜底为中性文案，不能误导门店', () => {
  assert.equal(deriveOrderStatusView(undefined).text, '处理中');
  assert.equal(deriveOrderStatusView('UNKNOWN').text, '处理中');
});
