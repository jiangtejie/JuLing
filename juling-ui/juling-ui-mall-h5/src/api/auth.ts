import type {
  AppAuthLoginRespVO,
  AppMemberUserInfoRespVO,
  LoginParam,
  LoginResult,
  UpdatePasswordParam,
  UserInfo,
} from '@/types';
import { adaptLoginResult, adaptUserInfo } from '@/api/adapters';
import { http } from '@/utils/request';

/**
 * 订货账号 + 密码登录。
 *
 * 刻意**不加** `silent` —— 登录失败（如「登录失败，账号密码不正确」）必须把后端的
 * 业务 msg 经全局拦截器展示出来，否则用户点击登录后毫无反馈。
 *
 * 入参由 `{ mobile, password }` 改为 `{ account, password }`（订货账号，通常为门店名）；
 * 后端仍兼容 mobile 字段，但前端只传 account。
 */
export async function login(data: LoginParam): Promise<LoginResult> {
  const result = await http.post<AppAuthLoginRespVO>('/member/auth/login', data);
  return adaptLoginResult(result);
}

/** 退出登录 */
export function logout(): Promise<boolean> {
  return http.post<boolean>('/member/auth/logout');
}

/** 获取当前登录会员信息（username 为订货账号，可能为空） */
export async function getProfile(): Promise<UserInfo> {
  const result = await http.get<AppMemberUserInfoRespVO>('/member/user/get');
  return adaptUserInfo(result);
}

/**
 * 修改密码（校验原密码，**不需要**短信验证码）。
 *
 * 原密码错误时后端返回业务错误码 1004001006（原密码不正确），
 * 提示文案由全局响应拦截器统一展示，调用方只需处理成功分支。
 */
export function updatePasswordByOld(data: UpdatePasswordParam): Promise<boolean> {
  return http.put<boolean>('/member/user/update-password-by-old', data);
}

/*
 * 短信登录（POST /member/auth/sms-login）与发送短信验证码（POST /member/auth/send-sms-code）
 * 已下线：短信渠道未配置，这两条链路在 H5 上不可用，登录页 / 改密页的对应入口已移除。
 */
