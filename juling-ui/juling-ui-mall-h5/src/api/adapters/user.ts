import type { AppAuthLoginRespVO, AppMemberUserInfoRespVO, LoginResult, UserInfo } from '@/types';

/**
 * 会员域 DTO → 领域模型映射。
 *
 * 注意：后端 `AppMemberUserInfoRespVO` **不提供** `customerId` / `customerName` / `verified`
 * （订货客户认证标识），前端领域模型保留这些可选字段但恒为空——见计划 D2。
 * `level` 对象在此拍平为 `levelName`。
 */

/** 后端登录响应 → 前端 LoginResult（expiresTime 统一为毫秒时间戳 number） */
export function adaptLoginResult(raw: AppAuthLoginRespVO): LoginResult {
  return {
    userId: raw.userId,
    accessToken: raw.accessToken,
    refreshToken: raw.refreshToken,
    expiresTime: Number(raw.expiresTime ?? 0),
  };
}

/** 后端会员信息 → 前端 UserInfo */
export function adaptUserInfo(raw: AppMemberUserInfoRespVO): UserInfo {
  return {
    id: raw.id,
    nickname: raw.nickname,
    avatar: raw.avatar,
    mobile: raw.mobile,
    levelName: raw.level?.name,
  };
}
