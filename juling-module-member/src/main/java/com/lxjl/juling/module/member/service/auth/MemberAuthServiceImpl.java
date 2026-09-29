package com.lxjl.juling.module.member.service.auth;

import cn.hutool.core.util.StrUtil;
import com.lxjl.juling.framework.common.enums.CommonStatusEnum;
import com.lxjl.juling.framework.common.enums.UserTypeEnum;
import com.lxjl.juling.framework.common.util.monitor.TracerUtils;
import com.lxjl.juling.framework.common.util.servlet.ServletUtils;
import com.lxjl.juling.module.member.controller.app.auth.vo.*;
import com.lxjl.juling.module.member.convert.auth.AuthConvert;
import com.lxjl.juling.module.member.dal.dataobject.user.MemberUserDO;
import com.lxjl.juling.module.member.service.user.MemberUserService;
import com.lxjl.juling.module.system.api.logger.LoginLogApi;
import com.lxjl.juling.module.system.api.logger.dto.LoginLogCreateReqDTO;
import com.lxjl.juling.framework.common.biz.system.oauth2.OAuth2TokenCommonApi;
import com.lxjl.juling.framework.common.biz.system.oauth2.dto.OAuth2AccessTokenCreateReqDTO;
import com.lxjl.juling.framework.common.biz.system.oauth2.dto.OAuth2AccessTokenRespDTO;
import com.lxjl.juling.module.system.enums.logger.LoginLogTypeEnum;
import com.lxjl.juling.module.system.enums.logger.LoginResultEnum;
import com.lxjl.juling.module.system.enums.oauth2.OAuth2ClientConstants;
import jakarta.annotation.Resource;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.util.Objects;

import static com.lxjl.juling.framework.common.exception.util.ServiceExceptionUtil.exception;
import static com.lxjl.juling.framework.common.util.servlet.ServletUtils.getClientIP;
import static com.lxjl.juling.module.member.enums.ErrorCodeConstants.*;

/**
 * 会员的认证 Service 实现类
 *
 * @author 亚特
 */
@Service
@Slf4j
public class MemberAuthServiceImpl implements MemberAuthService {

    @Resource
    private MemberUserService userService;
    @Resource
    private LoginLogApi loginLogApi;
    @Resource
    private OAuth2TokenCommonApi oauth2TokenApi;

    @Override
    public AppAuthLoginRespVO login(AppAuthLoginReqVO reqVO) {
        // 使用「订货账号（或手机号）+ 密码」进行登录。
        // 私域订货 H5 不开放给 C 端：订货人用名字当账号登录，account 为主、mobile 兼容。
        String loginName = StrUtil.blankToDefault(reqVO.getAccount(), reqVO.getMobile());
        MemberUserDO user = login0(loginName, reqVO.getPassword());

        // 创建 Token 令牌，记录登录日志
        return createTokenAfterLoginSuccess(user, loginName, LoginLogTypeEnum.LOGIN_USERNAME);
    }

    private AppAuthLoginRespVO createTokenAfterLoginSuccess(MemberUserDO user, String loginName,
                                                            LoginLogTypeEnum logType) {
        // 统一校验用户状态，避免登录方式增加后遗漏
        validateUserStatus(user, loginName, logType);

        // 插入登陆日志
        createLoginLog(user.getId(), loginName, logType, LoginResultEnum.SUCCESS);
        // 创建 Token 令牌
        OAuth2AccessTokenRespDTO accessTokenRespDTO = oauth2TokenApi.createAccessToken(new OAuth2AccessTokenCreateReqDTO()
                .setUserId(user.getId()).setUserType(getUserType().getValue())
                .setClientId(OAuth2ClientConstants.CLIENT_ID_DEFAULT));
        // 构建返回结果
        return AuthConvert.INSTANCE.convert(accessTokenRespDTO);
    }

    private void validateUserStatus(MemberUserDO user, String loginName, LoginLogTypeEnum logType) {
        if (CommonStatusEnum.isDisable(user.getStatus())) {
            createLoginLog(user.getId(), loginName, logType, LoginResultEnum.USER_DISABLED);
            throw exception(AUTH_LOGIN_USER_DISABLED);
        }
    }

    /**
     * 账号密码校验（私域订货的主登录路径）
     *
     * @param loginName 登录名：订货账号 或 手机号
     */
    private MemberUserDO login0(String loginName, String password) {
        final LoginLogTypeEnum logTypeEnum = LoginLogTypeEnum.LOGIN_USERNAME;
        // 登录名为空直接判失败：绝不能落到 selectByUsername(null) / selectByMobile(null)，
        // 那会退化成"随便查一行再比密码"，等于给空账号开了一道门。
        if (StrUtil.isBlank(loginName)) {
            throw exception(AUTH_LOGIN_BAD_CREDENTIALS);
        }
        // 1. 先按订货账号找（账号名就是订货人名字），找不到再按手机号找（兼容历史账号）
        MemberUserDO user = userService.getUserByUsername(loginName);
        if (user == null) {
            user = userService.getUserByMobile(loginName);
        }
        if (user == null) {
            createLoginLog(null, loginName, logTypeEnum, LoginResultEnum.BAD_CREDENTIALS);
            throw exception(AUTH_LOGIN_BAD_CREDENTIALS);
        }
        // 2. 校验密码
        if (!userService.isPasswordMatch(password, user.getPassword())) {
            createLoginLog(user.getId(), loginName, logTypeEnum, LoginResultEnum.BAD_CREDENTIALS);
            throw exception(AUTH_LOGIN_BAD_CREDENTIALS);
        }
        // 3. 校验是否禁用
        validateUserStatus(user, loginName, logTypeEnum);
        return user;
    }

    private void createLoginLog(Long userId, String loginName, LoginLogTypeEnum logType, LoginResultEnum loginResult) {
        // 插入登录日志
        LoginLogCreateReqDTO reqDTO = new LoginLogCreateReqDTO();
        reqDTO.setLogType(logType.getType());
        reqDTO.setTraceId(TracerUtils.getTraceId());
        reqDTO.setUserId(userId);
        reqDTO.setUserType(getUserType().getValue());
        reqDTO.setUsername(loginName);
        reqDTO.setUserAgent(ServletUtils.getUserAgent());
        reqDTO.setUserIp(getClientIP());
        reqDTO.setResult(loginResult.getResult());
        loginLogApi.createLoginLog(reqDTO);
        // 更新最后登录时间
        if (userId != null && Objects.equals(LoginResultEnum.SUCCESS.getResult(), loginResult.getResult())) {
            userService.updateUserLogin(userId, getClientIP());
        }
    }

    @Override
    public void logout(String token) {
        // 删除访问令牌
        OAuth2AccessTokenRespDTO accessTokenRespDTO = oauth2TokenApi.removeAccessToken(token);
        if (accessTokenRespDTO == null) {
            return;
        }
        // 删除成功，则记录登出日志
        createLogoutLog(accessTokenRespDTO.getUserId());
    }

    @Override
    public AppAuthLoginRespVO refreshToken(String refreshToken) {
        OAuth2AccessTokenRespDTO accessTokenDO = oauth2TokenApi.refreshAccessToken(refreshToken,
                OAuth2ClientConstants.CLIENT_ID_DEFAULT);
        return AuthConvert.INSTANCE.convert(accessTokenDO);
    }

    private void createLogoutLog(Long userId) {
        LoginLogCreateReqDTO reqDTO = new LoginLogCreateReqDTO();
        reqDTO.setLogType(LoginLogTypeEnum.LOGOUT_SELF.getType());
        reqDTO.setTraceId(TracerUtils.getTraceId());
        reqDTO.setUserId(userId);
        reqDTO.setUserType(getUserType().getValue());
        reqDTO.setUsername(getUsername(userId));
        reqDTO.setUserAgent(ServletUtils.getUserAgent());
        reqDTO.setUserIp(getClientIP());
        reqDTO.setResult(LoginResultEnum.SUCCESS.getResult());
        loginLogApi.createLoginLog(reqDTO);
    }

    private String getUsername(Long userId) {
        if (userId == null) {
            return null;
        }
        MemberUserDO user = userService.getUser(userId);
        return user != null ? user.getUsername() : null;
    }

    private UserTypeEnum getUserType() {
        return UserTypeEnum.MEMBER;
    }

}
