package com.lxjl.juling.module.member.service.auth;

import com.lxjl.juling.framework.common.biz.system.oauth2.OAuth2TokenCommonApi;
import com.lxjl.juling.framework.common.enums.CommonStatusEnum;
import com.lxjl.juling.framework.test.core.ut.BaseMockitoUnitTest;
import com.lxjl.juling.module.member.controller.app.auth.vo.AppAuthLoginReqVO;
import com.lxjl.juling.module.member.dal.dataobject.user.MemberUserDO;
import com.lxjl.juling.module.member.service.user.MemberUserService;
import com.lxjl.juling.module.system.api.logger.LoginLogApi;
import com.lxjl.juling.module.system.enums.logger.LoginLogTypeEnum;
import com.lxjl.juling.module.system.enums.logger.LoginResultEnum;
import org.junit.jupiter.api.Test;
import org.mockito.InjectMocks;
import org.mockito.Mock;

import static com.lxjl.juling.framework.test.core.util.AssertUtils.assertServiceException;
import static com.lxjl.juling.module.member.enums.ErrorCodeConstants.AUTH_LOGIN_USER_DISABLED;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.argThat;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class MemberAuthServiceImplStatusTest extends BaseMockitoUnitTest {

    @InjectMocks
    private MemberAuthServiceImpl authService;

    @Mock
    private MemberUserService userService;
    @Mock
    private LoginLogApi loginLogApi;
    @Mock
    private OAuth2TokenCommonApi oauth2TokenApi;

    @Test
    void testLogin_userDisabled() {
        // 准备参数
        AppAuthLoginReqVO reqVO = AppAuthLoginReqVO.builder().account("张三").password("password").build();
        MemberUserDO user = MemberUserDO.builder().id(1L).username("张三").mobile("15601691300")
                .password("encoded").status(CommonStatusEnum.DISABLE.getStatus()).build();
        when(userService.getUserByUsername("张三")).thenReturn(user);
        when(userService.isPasswordMatch("password", "encoded")).thenReturn(true);

        // 调用，并断言
        assertServiceException(() -> authService.login(reqVO), AUTH_LOGIN_USER_DISABLED);
        verify(loginLogApi).createLoginLog(argThat(o ->
                o.getLogType().equals(LoginLogTypeEnum.LOGIN_USERNAME.getType())
                        && o.getResult().equals(LoginResultEnum.USER_DISABLED.getResult())
                        && o.getUserId().equals(user.getId())));
        verify(oauth2TokenApi, never()).createAccessToken(any());
    }

}
