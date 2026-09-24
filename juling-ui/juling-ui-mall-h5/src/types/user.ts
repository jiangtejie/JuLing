/** 登录请求参数 */
export interface LoginParam {
  /** 手机号 */
  mobile: string;
  /** 密码 */
  password: string;
  /** 租户名（多租户场景，可空） */
  tenantName?: string;
  /** 图形验证码 */
  captchaVerification?: string;
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
  mobile?: string;
  /** 会员等级名称 */
  levelName?: string;
  /** 客户（门店 / 经销商）ID，订货业务常用 */
  customerId?: number;
  customerName?: string;
  /** 是否已认证的订货客户 */
  verified?: boolean;
}
