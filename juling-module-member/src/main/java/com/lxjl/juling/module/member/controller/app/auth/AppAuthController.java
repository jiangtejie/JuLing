package com.lxjl.juling.module.member.controller.app.auth;

import cn.hutool.core.util.StrUtil;
import com.lxjl.juling.framework.common.enums.UserTypeEnum;
import com.lxjl.juling.framework.common.pojo.CommonResult;
import com.lxjl.juling.framework.security.config.SecurityProperties;
import com.lxjl.juling.framework.security.core.util.SecurityFrameworkUtils;
import com.lxjl.juling.module.member.controller.app.auth.vo.*;
import com.lxjl.juling.module.member.convert.auth.AuthConvert;
import com.lxjl.juling.module.member.service.auth.MemberAuthService;
import com.lxjl.juling.module.system.api.social.SocialClientApi;
import com.lxjl.juling.module.system.api.social.dto.SocialWxJsapiSignatureRespDTO;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.extern.slf4j.Slf4j;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

import jakarta.annotation.Resource;
import jakarta.annotation.security.PermitAll;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;

import static com.lxjl.juling.framework.common.pojo.CommonResult.success;

@Tag(name = "用户 APP - 认证")
@RestController
@RequestMapping("/member/auth")
@Validated
@Slf4j
public class AppAuthController {

    @Resource
    private MemberAuthService authService;

    @Resource
    private SocialClientApi socialClientApi;

    @Resource
    private SecurityProperties securityProperties;

    @PostMapping("/login")
    @Operation(summary = "使用订货账号 + 密码登录")
    @PermitAll
    public CommonResult<AppAuthLoginRespVO> login(@RequestBody @Valid AppAuthLoginReqVO reqVO) {
        return success(authService.login(reqVO));
    }

    @PostMapping("/logout")
    @Operation(summary = "登出系统")
    @PermitAll
    public CommonResult<Boolean> logout(HttpServletRequest request) {
        String token = SecurityFrameworkUtils.obtainAuthorization(request,
                securityProperties.getTokenHeader(), securityProperties.getTokenParameter());
        if (StrUtil.isNotBlank(token)) {
            authService.logout(token);
        }
        return success(true);
    }

    @PostMapping("/refresh-token")
    @Operation(summary = "刷新令牌")
    @Parameter(name = "refreshToken", description = "刷新令牌", required = true)
    @PermitAll
    public CommonResult<AppAuthLoginRespVO> refreshToken(@RequestParam("refreshToken") String refreshToken) {
        return success(authService.refreshToken(refreshToken));
    }

    @PostMapping("/create-weixin-jsapi-signature")
    @Operation(summary = "创建微信 JS SDK 初始化所需的签名",
            description = "参考 https://developers.weixin.qq.com/doc/offiaccount/OA_Web_Apps/JS-SDK.html 文档")
    @PermitAll
    public CommonResult<SocialWxJsapiSignatureRespDTO> createWeixinMpJsapiSignature(@RequestParam("url") String url) {
        SocialWxJsapiSignatureRespDTO signature = socialClientApi.createWxMpJsapiSignature(
                UserTypeEnum.MEMBER.getValue(), url);
        return success(AuthConvert.INSTANCE.convert(signature));
    }

}
