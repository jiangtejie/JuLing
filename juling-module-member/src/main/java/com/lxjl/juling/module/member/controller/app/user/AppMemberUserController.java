package com.lxjl.juling.module.member.controller.app.user;

import com.lxjl.juling.framework.common.pojo.CommonResult;
import com.lxjl.juling.module.member.controller.app.user.vo.*;
import com.lxjl.juling.module.member.convert.user.MemberUserConvert;
import com.lxjl.juling.module.member.dal.dataobject.user.MemberUserDO;
import com.lxjl.juling.module.member.service.user.MemberUserService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.annotation.Resource;
import jakarta.validation.Valid;
import lombok.extern.slf4j.Slf4j;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

import static com.lxjl.juling.framework.common.pojo.CommonResult.success;
import static com.lxjl.juling.framework.security.core.util.SecurityFrameworkUtils.getLoginUserId;

@Tag(name = "用户 APP - 订货账号个人中心")
@RestController
@RequestMapping("/member/user")
@Validated
@Slf4j
public class AppMemberUserController {

    @Resource
    private MemberUserService userService;

    @GetMapping("/get")
    @Operation(summary = "获得基本信息")
    public CommonResult<AppMemberUserInfoRespVO> getUserInfo() {
        MemberUserDO user = userService.getUser(getLoginUserId());
        return success(MemberUserConvert.INSTANCE.convert(user));
    }

    @PutMapping("/update")
    @Operation(summary = "修改基本信息")
    public CommonResult<Boolean> updateUser(@RequestBody @Valid AppMemberUserUpdateReqVO reqVO) {
        userService.updateUser(getLoginUserId(), reqVO);
        return success(true);
    }

    @PutMapping("/update-password-by-old")
    @Operation(summary = "用原密码修改密码",
            description = "校验原密码，不需要短信验证码")
    public CommonResult<Boolean> updateUserPasswordByOld(@RequestBody @Valid AppMemberUserUpdatePasswordByOldReqVO reqVO) {
        userService.updateUserPasswordByOld(getLoginUserId(), reqVO);
        return success(true);
    }

}
