import type {
  AppAuthLoginRespVO,
  AppMemberUserInfoRespVO,
  LoginParam,
  LoginResult,
  UserInfo,
} from '@/types';
import { adaptLoginResult, adaptUserInfo } from '@/api/adapters';
import { http } from '@/utils/request';

/** 账号密码登录 */
export async function login(data: LoginParam): Promise<LoginResult> {
  const result = await http.post<AppAuthLoginRespVO>('/member/auth/login', data, { silent: true });
  return adaptLoginResult(result);
}

/** 短信验证码登录 */
export async function loginBySms(data: { mobile: string; code: string }): Promise<LoginResult> {
  const result = await http.post<AppAuthLoginRespVO>('/member/auth/sms-login', data, {
    silent: true,
  });
  return adaptLoginResult(result);
}

/** 发送短信验证码（scene=1 为会员登录场景） */
export function sendSmsCode(mobile: string): Promise<boolean> {
  return http.post<boolean>('/member/auth/send-sms-code', { mobile, scene: 1 });
}

/** 退出登录 */
export function logout(): Promise<boolean> {
  return http.post<boolean>('/member/auth/logout');
}

/** 获取当前登录会员信息 */
export async function getProfile(): Promise<UserInfo> {
  const result = await http.get<AppMemberUserInfoRespVO>('/member/user/get');
  return adaptUserInfo(result);
}
