package com.lxjl.juling.module.member.enums;

import com.lxjl.juling.framework.common.exception.ErrorCode;

/**
 * Member 错误码枚举类
 * <p>
 * member 系统，使用 1-004-000-000 段
 */
public interface ErrorCodeConstants {

    // ========== 用户相关  1-004-001-000 ============
    ErrorCode USER_NOT_EXISTS = new ErrorCode(1_004_001_000, "用户不存在");
    ErrorCode USER_MOBILE_NOT_EXISTS = new ErrorCode(1_004_001_001, "手机号未注册用户");
    ErrorCode USER_MOBILE_USED = new ErrorCode(1_004_001_002, "修改手机失败，该手机号({})已经被使用");
    ErrorCode USER_EMAIL_USED = new ErrorCode(1_004_001_004, "修改邮箱失败，该邮箱({})已经被使用");
    ErrorCode USER_USERNAME_USED = new ErrorCode(1_004_001_005, "该订货账号({})已经被使用，请换一个");
    ErrorCode USER_OLD_PASSWORD_ERROR = new ErrorCode(1_004_001_006, "原密码不正确");
    ErrorCode USER_STORE_NOT_BOUND = new ErrorCode(1_004_001_007, "订货账号必须绑定门店（所属客户不能为空），否则无法下单");
    ErrorCode USER_USERNAME_BLANK = new ErrorCode(1_004_001_008, "订货账号不能为空");

    // ========== AUTH 模块 1-004-003-000 ==========
    ErrorCode AUTH_LOGIN_BAD_CREDENTIALS = new ErrorCode(1_004_003_000, "登录失败，账号密码不正确");
    ErrorCode AUTH_LOGIN_USER_DISABLED = new ErrorCode(1_004_003_001, "登录失败，账号被禁用");

}
