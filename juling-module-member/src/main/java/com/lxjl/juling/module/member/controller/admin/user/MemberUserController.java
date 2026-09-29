package com.lxjl.juling.module.member.controller.admin.user;

import com.lxjl.juling.framework.common.pojo.CommonResult;
import com.lxjl.juling.framework.common.pojo.PageResult;
import com.lxjl.juling.module.member.controller.admin.user.vo.*;
import com.lxjl.juling.module.member.convert.user.MemberUserConvert;
import com.lxjl.juling.module.member.dal.dataobject.user.MemberUserDO;
import com.lxjl.juling.module.member.service.user.MemberUserService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.annotation.Resource;
import jakarta.validation.Valid;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

import static com.lxjl.juling.framework.common.pojo.CommonResult.success;

@Tag(name = "管理后台 - 订货账号")
@RestController
@RequestMapping("/member/user")
@Validated
public class MemberUserController {

    @Resource
    private MemberUserService memberUserService;

    @PostMapping("/create")
    @Operation(summary = "开订货账号（私域加盟客户：账号名 + 初始密码 + 绑定门店）")
    @PreAuthorize("@ss.hasPermission('member:user:create')")
    public CommonResult<Long> createUser(@Valid @RequestBody MemberUserCreateReqVO createReqVO) {
        return success(memberUserService.createOrderUser(createReqVO));
    }

    @PutMapping("/reset-password")
    @Operation(summary = "重置订货账号密码（不需要短信验证码，重置后强制下线）")
    @PreAuthorize("@ss.hasPermission('member:user:reset-password')")
    public CommonResult<Boolean> resetPassword(@Valid @RequestBody MemberUserResetPasswordReqVO resetReqVO) {
        memberUserService.resetUserPasswordByAdmin(resetReqVO.getId(), resetReqVO.getPassword());
        return success(true);
    }

    @PutMapping("/update")
    @Operation(summary = "更新订货账号")
    @PreAuthorize("@ss.hasPermission('member:user:update')")
    public CommonResult<Boolean> updateUser(@Valid @RequestBody MemberUserUpdateReqVO updateReqVO) {
        memberUserService.updateUser(updateReqVO);
        return success(true);
    }

    @GetMapping("/get")
    @Operation(summary = "获得订货账号")
    @Parameter(name = "id", description = "编号", required = true, example = "1024")
    @PreAuthorize("@ss.hasPermission('member:user:query')")
    public CommonResult<MemberUserRespVO> getUser(@RequestParam("id") Long id) {
        MemberUserDO user = memberUserService.getUser(id);
        if (user == null) {
            return success(null);
        }
        return success(MemberUserConvert.INSTANCE.convert03(user));
    }

    @GetMapping("/page")
    @Operation(summary = "获得订货账号分页")
    @PreAuthorize("@ss.hasPermission('member:user:query')")
    public CommonResult<PageResult<MemberUserRespVO>> getUserPage(@Valid MemberUserPageReqVO pageVO) {
        PageResult<MemberUserDO> pageResult = memberUserService.getUserPage(pageVO);
        return success(MemberUserConvert.INSTANCE.convertPage(pageResult));
    }

}
