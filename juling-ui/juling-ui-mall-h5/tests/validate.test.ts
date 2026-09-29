import assert from 'node:assert/strict';
import { test } from 'node:test';

import { isAccount } from '../src/utils/is.ts';
import {
  PASSWORD_MAX_LENGTH,
  PASSWORD_MIN_LENGTH,
  validatePasswordChange,
} from '../src/utils/password.ts';

/**
 * 订货账号（登录）与修改密码表单的校验规则。
 * 抽成纯函数就是为了在这里直接覆盖，避免规则只存在于 .vue 里无法回归。
 */

/* ------------------------------ 订货账号校验 ------------------------------ */

test('isAccount：中文门店名 / 字母账号均合法（2-64 位）', () => {
  assert.equal(isAccount('亚特总店'), true);
  assert.equal(isAccount('ab'), true);
  assert.equal(isAccount('A'.repeat(64)), true);
  // 前后空白由校验内部去掉，粘贴带空格的账号不应被误判
  assert.equal(isAccount('  亚特总店  '), true);
});

test('isAccount：空 / 过短 / 过长 / 全空白不合法', () => {
  assert.equal(isAccount(''), false);
  assert.equal(isAccount('a'), false);
  assert.equal(isAccount('   '), false);
  assert.equal(isAccount('A'.repeat(65)), false);
});

/* ------------------------------ 修改密码规则 ------------------------------ */

/** 合法表单基线 */
const validForm = {
  oldPassword: 'old-pass',
  newPassword: 'new-pass',
  confirmPassword: 'new-pass',
};

test('validatePasswordChange：合法表单返回空串（无错误）', () => {
  assert.equal(validatePasswordChange(validForm), '');
});

test('validatePasswordChange：原密码为空时拦下', () => {
  assert.equal(validatePasswordChange({ ...validForm, oldPassword: '' }), '请输入原密码');
});

test('validatePasswordChange：新密码为空时拦下', () => {
  assert.equal(
    validatePasswordChange({ ...validForm, newPassword: '', confirmPassword: '' }),
    '请输入新密码',
  );
});

test('validatePasswordChange：新密码长度越界拦下，6 / 32 位为合法边界', () => {
  const message = `新密码长度需为 ${PASSWORD_MIN_LENGTH}-${PASSWORD_MAX_LENGTH} 位`;
  const tooShort = 'a'.repeat(PASSWORD_MIN_LENGTH - 1);
  const tooLong = 'a'.repeat(PASSWORD_MAX_LENGTH + 1);

  assert.equal(
    validatePasswordChange({ ...validForm, newPassword: tooShort, confirmPassword: tooShort }),
    message,
  );
  assert.equal(
    validatePasswordChange({ ...validForm, newPassword: tooLong, confirmPassword: tooLong }),
    message,
  );

  const min = 'a'.repeat(PASSWORD_MIN_LENGTH);
  const max = 'a'.repeat(PASSWORD_MAX_LENGTH);
  assert.equal(
    validatePasswordChange({ ...validForm, newPassword: min, confirmPassword: min }),
    '',
  );
  assert.equal(
    validatePasswordChange({ ...validForm, newPassword: max, confirmPassword: max }),
    '',
  );
});

test('validatePasswordChange：两次输入不一致时拦下', () => {
  assert.equal(
    validatePasswordChange({ ...validForm, confirmPassword: 'new-pass-2' }),
    '两次输入的新密码不一致',
  );
  assert.equal(
    validatePasswordChange({ ...validForm, confirmPassword: '' }),
    '两次输入的新密码不一致',
  );
});
