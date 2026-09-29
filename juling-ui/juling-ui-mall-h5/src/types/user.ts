/** 登录请求参数（POST /member/auth/login） */
export interface LoginParam {
  /** 订货账号（总部下发，通常为门店名；2-64 位） */
  account: string;
  /** 密码 */
  password: string;
  /** 租户名（多租户场景，可空） */
  tenantName?: string;
  /** 图形验证码 */
  captchaVerification?: string;
}

/**
 * 修改密码请求参数（PUT /member/user/update-password-by-old）。
 * 校验原密码、不需要短信验证码；原密码错误时后端返回业务错误码 1004001006。
 */
export interface UpdatePasswordParam {
  /** 原密码 */
  oldPassword: string;
  /** 新密码（6-32 位） */
  newPassword: string;
}

/** 登录结果 */
export interface LoginResult {
  userId: number;
  accessToken: string;
  refreshToken: string;
  expiresTime: number;
}

/** 会员信息 */
export interface UserInfo {
  id: number;
  nickname: string;
  avatar?: string;
  /** 手机号（会员手机号已非必填，可能为空） */
  mobile?: string;
  /** 订货账号（总部下发的登录账号，旧数据可能为空） */
  username?: string;
  /** 会员等级名称 */
  levelName?: string;
  /** 客户（门店 / 经销商）ID，订货业务常用 */
  customerId?: number;
  customerName?: string;
  /** 是否已认证的订货客户 */
  verified?: boolean;
}
