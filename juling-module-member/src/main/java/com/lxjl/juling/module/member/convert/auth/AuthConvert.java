package com.lxjl.juling.module.member.convert.auth;

import com.lxjl.juling.module.member.controller.app.auth.vo.*;
import com.lxjl.juling.framework.common.biz.system.oauth2.dto.OAuth2AccessTokenRespDTO;
import com.lxjl.juling.module.system.api.social.dto.SocialWxJsapiSignatureRespDTO;
import org.mapstruct.Mapper;
import org.mapstruct.factory.Mappers;

@Mapper
public interface AuthConvert {

    AuthConvert INSTANCE = Mappers.getMapper(AuthConvert.class);

    AppAuthLoginRespVO convert(OAuth2AccessTokenRespDTO bean);

    SocialWxJsapiSignatureRespDTO convert(SocialWxJsapiSignatureRespDTO bean);

}
