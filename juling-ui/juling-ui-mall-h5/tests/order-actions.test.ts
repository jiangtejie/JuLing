import assert from 'node:assert/strict';
import { test } from 'node:test';

import { resolveUploadAction } from '../src/utils/order-actions.ts';

const proof = (status: number) => ({ id: 1, status }) as never;

test('还没上传凭证、货款未收齐 → 显示「上传付款凭证」', () => {
  const r = resolveUploadAction({
    auditStatus: 0,
    isAbnormal: false,
    proofs: [],
    remainAmount: 1000,
  });
  assert.deepEqual(r, {
    visible: true,
    text: '上传付款凭证',
    barText: '上传凭证',
  });
});

test('已提交、等审批（凭证待审核 / 审核中 10 / 已通过 20）→ 一律收起入口', () => {
  for (const input of [
    { auditStatus: 0, isAbnormal: false, proofs: [proof(0)], remainAmount: 1000 },
    { auditStatus: 10, isAbnormal: false, proofs: [proof(0)], remainAmount: 0 },
    { auditStatus: 20, isAbnormal: false, proofs: [proof(1)], remainAmount: 0 },
    { auditStatus: 10, isAbnormal: false, proofs: [], remainAmount: 1000 },
  ]) {
    assert.equal(resolveUploadAction(input).visible, false);
  }
});

test('凭证被驳回（status=2）→ 重新显示，文案为「重新上传付款凭证」', () => {
  const r = resolveUploadAction({
    auditStatus: 30,
    isAbnormal: false,
    proofs: [proof(2)],
    remainAmount: 1000,
  });
  assert.deepEqual(r, {
    visible: true,
    text: '重新上传付款凭证',
    barText: '重新上传凭证',
  });
});

test('货款已收齐 / 订单异常态 → 收起入口', () => {
  assert.equal(
    resolveUploadAction({ auditStatus: 0, isAbnormal: false, proofs: [], remainAmount: 0 })
      .visible,
    false,
  );
  assert.equal(
    resolveUploadAction({ auditStatus: 0, isAbnormal: true, proofs: [], remainAmount: 1000 })
      .visible,
    false,
  );
});

test('已认定后再补款（部分收款 + 审批通过）→ 收起入口，避免被后端拒绝', () => {
  assert.equal(
    resolveUploadAction({
      auditStatus: 20,
      isAbnormal: false,
      proofs: [proof(1)],
      remainAmount: 500,
    }).visible,
    false,
  );
});
