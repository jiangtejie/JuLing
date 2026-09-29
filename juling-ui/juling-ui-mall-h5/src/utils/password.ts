/**
 * 修改密码表单规则。
 *
 * 抽成不依赖 Vue 的纯函数：页面只做「取错误文案 → showToast」，规则本身可被
 * `node --test` 直接覆盖（见 tests/validate.test.ts）。
 */

/** 新密码长度下限（与后端 @Length(min = 6, max = 32) 对齐） */
export const PASSWORD_MIN_LENGTH = 6;

/** 新密码长度上限 */
export const PASSWORD_MAX_LENGTH = 32;

/** 修改密码表单字段 */
export interface PasswordChangeForm {
  /** 原密码 */
  oldPassword: string;
  /** 新密码 */
  newPassword: string;
  /** 确认新密码 */
  confirmPassword: string;
}

/**
 * 校验修改密码表单。
 * @returns 错误文案；校验通过时返回空串。
 */
export function validatePasswordChange(form: PasswordChangeForm): string {
  if (!form.oldPassword) return '请输入原密码';
  if (!form.newPassword) return '请输入新密码';
  if (
    form.newPassword.length < PASSWORD_MIN_LENGTH ||
    form.newPassword.length > PASSWORD_MAX_LENGTH
  ) {
    return `新密码长度需为 ${PASSWORD_MIN_LENGTH}-${PASSWORD_MAX_LENGTH} 位`;
  }
  if (form.newPassword !== form.confirmPassword) return '两次输入的新密码不一致';
  return '';
}
