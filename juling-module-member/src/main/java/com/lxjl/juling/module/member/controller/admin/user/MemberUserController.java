package com.lxjl.juling.module.member.controller.admin.user;

import cn.hutool.core.collection.CollUtil;
import cn.hutool.core.collection.ListUtil;
import com.lxjl.juling.framework.common.pojo.CommonResult;
import com.lxjl.juling.framework.common.pojo.PageResult;
import com.lxjl.juling.module.member.controller.admin.user.vo.*;
import com.lxjl.juling.module.member.convert.user.MemberUserConvert;
import com.lxjl.juling.module.member.dal.dataobject.user.MemberUserDO;
import com.lxjl.juling.module.member.dal.dataobject.user.MemberUserStoreDO;
import com.lxjl.juling.module.member.service.user.MemberUserStoreService;
import com.lxjl.juling.module.member.service.user.MemberUserService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.annotation.Resource;
import jakarta.validation.Valid;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

import java.util.Collections;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

import static com.lxjl.juling.framework.common.pojo.CommonResult.success;
import static com.lxjl.juling.framework.common.util.collection.CollectionUtils.convertSet;

@Tag(name = "管理后台 - 订货账号")
@RestController
@RequestMapping("/member/user")
@Validated
public class MemberUserController {

    @Resource
    private MemberUserService memberUserService;

    @Resource
    private MemberUserStoreService memberUserStoreService;

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

    @DeleteMapping("/delete")
    @Operation(summary = "删除订货账号", description = "已绑定门店/部门的账号会拒绝删除，请改用停用")
    @Parameter(name = "id", description = "编号", required = true, example = "1024")
    @PreAuthorize("@ss.hasPermission('member:user:delete')")
    public CommonResult<Boolean> deleteUser(@RequestParam("id") Long id) {
        memberUserService.deleteUser(id);
        return success(true);
    }

    @PutMapping("/update-status")
    @Operation(summary = "停用 / 启用订货账号", description = "停用后无法登录，订单与台账仍可追溯")
    @Parameter(name = "id", description = "编号", required = true, example = "1024")
    @Parameter(name = "status", description = "状态：0 开启、1 停用", required = true, example = "1")
    @PreAuthorize("@ss.hasPermission('member:user:update-status')")
    public CommonResult<Boolean> updateUserStatus(@RequestParam("id") Long id,
                                                 @RequestParam("status") Integer status) {
        memberUserService.updateUserStatus(id, status);
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
        MemberUserRespVO vo = MemberUserConvert.INSTANCE.convert03(user);
        attachStoreGrants(ListUtil.toList(vo));
        return success(vo);
    }

    @GetMapping("/page")
    @Operation(summary = "获得订货账号分页")
    @PreAuthorize("@ss.hasPermission('member:user:query')")
    public CommonResult<PageResult<MemberUserRespVO>> getUserPage(@Valid MemberUserPageReqVO pageVO) {
        PageResult<MemberUserDO> pageResult = memberUserService.getUserPage(pageVO);
        PageResult<MemberUserRespVO> result = MemberUserConvert.INSTANCE.convertPage(pageResult);
        attachStoreGrants(result.getList());
        return success(result);
    }

    /**
     * 装配「授权门店」
     *
     * <p>授权关系在 member_user_store 上而不是账号表里，所以走 VO 转换之后单独补；
     * 批量查一次，避免列表页 N+1。
     */
    private void attachStoreGrants(List<MemberUserRespVO> list) {
        if (CollUtil.isEmpty(list)) {
            return;
        }
        List<MemberUserStoreDO> grants = memberUserStoreService
                .getStoreListByUserIds(convertSet(list, MemberUserRespVO::getId));
        Map<Long, List<Long>> storeIdMap = grants.stream().collect(Collectors.groupingBy(
                MemberUserStoreDO::getUserId,
                Collectors.mapping(MemberUserStoreDO::getCustomerId, Collectors.toList())));
        Map<Long, Long> defaultMap = grants.stream()
                .filter(item -> Boolean.TRUE.equals(item.getIsDefault()))
                .collect(Collectors.toMap(MemberUserStoreDO::getUserId, MemberUserStoreDO::getCustomerId,
                        (a, b) -> a));
        list.forEach(vo -> {
            vo.setStoreCustomerIds(storeIdMap.getOrDefault(vo.getId(), Collections.emptyList()));
            vo.setDefaultStoreCustomerId(defaultMap.get(vo.getId()));
        });
    }

}
