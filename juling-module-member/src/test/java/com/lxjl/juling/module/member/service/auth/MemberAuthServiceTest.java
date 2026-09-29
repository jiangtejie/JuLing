package com.lxjl.juling.module.member.service.auth;

import com.lxjl.juling.framework.common.biz.system.oauth2.OAuth2TokenCommonApi;
import com.lxjl.juling.framework.common.biz.system.oauth2.dto.OAuth2AccessTokenRespDTO;
import com.lxjl.juling.framework.common.enums.CommonStatusEnum;
import com.lxjl.juling.framework.test.core.ut.BaseMockitoUnitTest;
import com.lxjl.juling.module.member.controller.app.auth.vo.AppAuthLoginReqVO;
import com.lxjl.juling.module.member.controller.app.auth.vo.AppAuthLoginRespVO;
import com.lxjl.juling.module.member.dal.dataobject.user.MemberUserDO;
import com.lxjl.juling.module.member.service.user.MemberUserService;
import com.lxjl.juling.module.system.api.logger.LoginLogApi;
import com.lxjl.juling.module.system.enums.logger.LoginResultEnum;
import org.junit.jupiter.api.Test;
import org.mockito.InjectMocks;
import org.mockito.Mock;

import static com.lxjl.juling.framework.test.core.util.AssertUtils.assertServiceException;
import static com.lxjl.juling.module.member.enums.ErrorCodeConstants.AUTH_LOGIN_BAD_CREDENTIALS;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.argThat;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.ArgumentMatchers.isNull;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * {@link MemberAuthService} 的单元测试类
 *
 * 只覆盖「订货账号 + 密码」这一条登录路径（私域订货的唯一登录方式）
 *
 * @author 亚特
 */
public class MemberAuthServiceTest extends BaseMockitoUnitTest {

    @InjectMocks
    private MemberAuthServiceImpl authService;

    @Mock
    private MemberUserService userService;
    @Mock
    private LoginLogApi loginLogApi;
    @Mock
    private OAuth2TokenCommonApi oauth2TokenApi;

    @Test
    public void testLogin_byAccount_success() {
        // 准备参数
        AppAuthLoginReqVO reqVO = AppAuthLoginReqVO.builder().account("张三").password("password").build();
        MemberUserDO user = MemberUserDO.builder().id(1L).username("张三").password("encoded")
                .status(CommonStatusEnum.ENABLE.getStatus()).build();
        when(userService.getUserByUsername("张三")).thenReturn(user);
        when(userService.isPasswordMatch("password", "encoded")).thenReturn(true);
        OAuth2AccessTokenRespDTO accessToken = new OAuth2AccessTokenRespDTO();
        accessToken.setUserId(1L);
        accessToken.setAccessToken("access-token");
        accessToken.setRefreshToken("refresh-token");
        when(oauth2TokenApi.createAccessToken(any())).thenReturn(accessToken);

        // 调用
        AppAuthLoginRespVO respVO = authService.login(reqVO);

        // 断言
        assertEquals(1L, respVO.getUserId());
        assertEquals("access-token", respVO.getAccessToken());
        assertEquals("refresh-token", respVO.getRefreshToken());
        verify(loginLogApi).createLoginLog(argThat(o ->
                o.getResult().equals(LoginResultEnum.SUCCESS.getResult()) && o.getUserId().equals(1L)));
        verify(userService).updateUserLogin(eq(1L), isNull());
    }

    @Test
    public void testLogin_byMobileFallback_success() {
        // 准备参数：订货账号找不到，回退按手机号找（兼容历史账号）
        AppAuthLoginReqVO reqVO = AppAuthLoginReqVO.builder().account("15601691300").password("password").build();
        MemberUserDO user = MemberUserDO.builder().id(2L).username("李四").mobile("15601691300")
                .password("encoded").status(CommonStatusEnum.ENABLE.getStatus()).build();
        when(userService.getUserByUsername("15601691300")).thenReturn(null);
        when(userService.getUserByMobile("15601691300")).thenReturn(user);
        when(userService.isPasswordMatch("password", "encoded")).thenReturn(true);
        OAuth2AccessTokenRespDTO accessToken = new OAuth2AccessTokenRespDTO();
        accessToken.setUserId(2L);
        accessToken.setAccessToken("access-token");
        when(oauth2TokenApi.createAccessToken(any())).thenReturn(accessToken);

        // 调用
        AppAuthLoginRespVO respVO = authService.login(reqVO);

        // 断言
        assertEquals(2L, respVO.getUserId());
    }

    @Test
    public void testLogin_badCredentials() {
        // 准备参数：账号不存在
        AppAuthLoginReqVO reqVO = AppAuthLoginReqVO.builder().account("不存在").password("password").build();
        when(userService.getUserByUsername("不存在")).thenReturn(null);
        when(userService.getUserByMobile("不存在")).thenReturn(null);

        // 调用，并断言
        assertServiceException(() -> authService.login(reqVO), AUTH_LOGIN_BAD_CREDENTIALS);
        verify(loginLogApi).createLoginLog(argThat(o ->
                o.getResult().equals(LoginResultEnum.BAD_CREDENTIALS.getResult()) && o.getUserId() == null));
    }

}
