import assert from 'node:assert/strict';
import { test } from 'node:test';

import { orderTabToQuery } from '../src/api/adapters/order.ts';

test('处理中页签：status=待发货 + auditPassed=false（审核未完成，含被驳回）', () => {
  assert.deepEqual(orderTabToQuery('REVIEWING'), {
    status: 10,
    auditPassed: false,
  });
});

test('待发货页签：status=待发货 + auditPassed=true（已通过两级审批或直营免审）', () => {
  assert.deepEqual(orderTabToQuery('PAID'), { status: 10, auditPassed: true });
});

test('待付款 / 待收货 / 已完成：只按状态码，不带审核条件', () => {
  assert.deepEqual(orderTabToQuery('UNPAID'), { status: 0 });
  assert.deepEqual(orderTabToQuery('SHIPPED'), { status: 20 });
  assert.deepEqual(orderTabToQuery('COMPLETED'), { status: 30 });
});

test('全部 / 空 / 未知：不带任何筛选参数', () => {
  assert.deepEqual(orderTabToQuery('all'), { status: undefined });
  assert.deepEqual(orderTabToQuery(undefined), { status: undefined });
  assert.deepEqual(orderTabToQuery('SOMETHING_NEW'), { status: undefined });
});
