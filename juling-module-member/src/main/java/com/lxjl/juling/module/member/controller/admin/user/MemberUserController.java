package com.lxjl.juling.module.member.controller.admin.user;

import cn.hutool.core.collection.CollUtil;
import com.lxjl.juling.framework.common.pojo.CommonResult;
import com.lxjl.juling.framework.common.pojo.PageResult;
import com.lxjl.juling.module.member.controller.admin.user.vo.*;
import com.lxjl.juling.module.member.convert.user.MemberUserConvert;
import com.lxjl.juling.module.member.dal.dataobject.group.MemberGroupDO;
import com.lxjl.juling.module.member.dal.dataobject.level.MemberLevelDO;
import com.lxjl.juling.module.member.dal.dataobject.tag.MemberTagDO;
import com.lxjl.juling.module.member.dal.dataobject.user.MemberUserDO;
import com.lxjl.juling.module.member.enums.point.MemberPointBizTypeEnum;
import com.lxjl.juling.module.member.service.group.MemberGroupService;
import com.lxjl.juling.module.member.service.level.MemberLevelService;
import com.lxjl.juling.module.member.service.point.MemberPointRecordService;
import com.lxjl.juling.module.member.service.tag.MemberTagService;
import com.lxjl.juling.module.member.service.user.MemberUserService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.annotation.Resource;
import jakarta.validation.Valid;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

import java.util.Collection;
import java.util.List;
import java.util.Objects;
import java.util.Set;
import java.util.stream.Collectors;

import static com.lxjl.juling.framework.common.pojo.CommonResult.success;
import static com.lxjl.juling.framework.common.util.collection.CollectionUtils.convertSet;
import static com.lxjl.juling.framework.web.core.util.WebFrameworkUtils.getLoginUserId;

@Tag(name = "管理后台 - 会员用户")
@RestController
@RequestMapping("/member/user")
@Validated
public class MemberUserController {

    @Resource
    private MemberUserService memberUserService;
    @Resource
    private MemberTagService memberTagService;
    @Resource
    private MemberLevelService memberLevelService;
    @Resource
    private MemberGroupService memberGroupService;
    @Resource
    private MemberPointRecordService memberPointRecordService;

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
    @Operation(summary = "更新会员用户")
    @PreAuthorize("@ss.hasPermission('member:user:update')")
    public CommonResult<Boolean> updateUser(@Valid @RequestBody MemberUserUpdateReqVO updateReqVO) {
        memberUserService.updateUser(updateReqVO);
        return success(true);
    }

    @PutMapping("/update-level")
    @Operation(summary = "更新会员用户等级")
    @PreAuthorize("@ss.hasPermission('member:user:update-level')")
    public CommonResult<Boolean> updateUserLevel(@Valid @RequestBody MemberUserUpdateLevelReqVO updateReqVO) {
        memberLevelService.updateUserLevel(updateReqVO);
        return success(true);
    }

    @PutMapping("/update-point")
    @Operation(summary = "更新会员用户积分")
    @PreAuthorize("@ss.hasPermission('member:user:update-point')")
    public CommonResult<Boolean> updateUserPoint(@Valid @RequestBody MemberUserUpdatePointReqVO updateReqVO) {
        memberPointRecordService.createPointRecord(updateReqVO.getId(), updateReqVO.getPoint(),
                MemberPointBizTypeEnum.ADMIN, String.valueOf(getLoginUserId()));
        return success(true);
    }

    @GetMapping("/get")
    @Operation(summary = "获得会员用户")
    @Parameter(name = "id", description = "编号", required = true, example = "1024")
    @PreAuthorize("@ss.hasPermission('member:user:query')")
    public CommonResult<MemberUserRespVO> getUser(@RequestParam("id") Long id) {
        MemberUserDO user = memberUserService.getUser(id);
        if (user == null) {
            return success(null);
        }
        MemberUserRespVO userVO = MemberUserConvert.INSTANCE.convert03(user);
        if (user.getLevelId() != null) {
            MemberLevelDO level = memberLevelService.getLevel(userVO.getLevelId());
            if (level != null) {
                userVO.setLevelName(level.getName());
            }
        }
        return success(userVO);
    }

    @GetMapping("/page")
    @Operation(summary = "获得会员用户分页")
    @PreAuthorize("@ss.hasPermission('member:user:query')")
    public CommonResult<PageResult<MemberUserRespVO>> getUserPage(@Valid MemberUserPageReqVO pageVO) {
        PageResult<MemberUserDO> pageResult = memberUserService.getUserPage(pageVO);
        if (CollUtil.isEmpty(pageResult.getList())) {
            return success(PageResult.empty());
        }

        // 处理用户标签返显
        Set<Long> tagIds = pageResult.getList().stream()
                .map(MemberUserDO::getTagIds)
                .filter(Objects::nonNull)
                .flatMap(Collection::stream)
                .collect(Collectors.toSet());
        List<MemberTagDO> tags = memberTagService.getTagList(tagIds);
        // 处理用户级别返显
        List<MemberLevelDO> levels = memberLevelService.getLevelList(
                convertSet(pageResult.getList(), MemberUserDO::getLevelId));
        // 处理用户分组返显
        List<MemberGroupDO> groups = memberGroupService.getGroupList(
                convertSet(pageResult.getList(), MemberUserDO::getGroupId));
        return success(MemberUserConvert.INSTANCE.convertPage(pageResult, tags, levels, groups));
    }

}
