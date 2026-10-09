package com.lxjl.juling.module.member.service.auth;

import com.lxjl.juling.module.member.controller.app.auth.vo.*;

import jakarta.validation.Valid;

/**
 * 会员的认证 Service 接口
 *
 * 只提供订货账号的账号密码登录、token 的校验等认证相关的功能
 *
 * @author 亚特
 */
public interface MemberAuthService {

    /**
     * 订货账号（或手机号）+ 密码登录
     *
     * @param reqVO 登录信息
     * @return 登录结果
     */
    AppAuthLoginRespVO login(@Valid AppAuthLoginReqVO reqVO);

    /**
     * 基于 token 退出登录
     *
     * @param token token
     */
    void logout(String token);

    /**
     * 刷新访问令牌
     *
     * @param refreshToken 刷新令牌
     * @return 登录结果
     */
    AppAuthLoginRespVO refreshToken(String refreshToken);

}
