package com.lxjl.juling.module.member.controller.admin.user.vo;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;
import org.hibernate.validator.constraints.URL;
import org.springframework.format.annotation.DateTimeFormat;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.time.LocalDateTime;
import java.util.List;

import static com.lxjl.juling.framework.common.util.date.DateUtils.FORMAT_YEAR_MONTH_DAY;

/**
 * 会员用户 Base VO，提供给添加、修改、详细的子 VO 使用
 * 如果子 VO 存在差异的字段，请不要添加到这里，影响 Swagger 文档生成
 */
@Data
public class MemberUserBaseVO {

    @Schema(description = "订货账号（订货人的登录名，就是订货人名字）", example = "张三")
    @Size(max = 64, message = "订货账号长度不能超过 64 个字符")
    private String username;

    @Schema(description = "手机号（私域订货场景可选，不填则只能用订货账号登录）", example = "15601691300")
    private String mobile;

    @Schema(description = "状态", requiredMode = Schema.RequiredMode.REQUIRED, example = "2")
    @NotNull(message = "状态不能为空")
    private Byte status;

    @Schema(description = "邮箱", example = "member@example.com")
    @Email(message = "邮箱格式不正确")
    @Size(max = 50, message = "邮箱长度不能超过 50 个字符")
    private String email;

    @Schema(description = "用户昵称", requiredMode = Schema.RequiredMode.REQUIRED, example = "李四")
    @NotNull(message = "用户昵称不能为空")
    private String nickname;

    @Schema(description = "头像", requiredMode = Schema.RequiredMode.REQUIRED, example = "https://github.com/jiangtejie/JuLing")
    @URL(message = "头像必须是 URL 格式")
    private String avatar;

    @Schema(description = "用户昵称", example = "李四")
    private String name;

    @Schema(description = "用户性别", example = "1")
    private Integer sex;

    @Schema(description = "所在地编号", example = "4371")
    private Long areaId;

    @Schema(description = "所在地全程", example = "上海上海市普陀区")
    private String areaName;

    @Schema(description = "出生日期", example = "2023-03-12")
    @DateTimeFormat(pattern = FORMAT_YEAR_MONTH_DAY)
    private LocalDateTime birthday;

    @Schema(description = "会员备注", example = "我是小备注")
    private String mark;

    @Schema(description = "会员标签", example = "[1, 2]")
    private List<Long> tagIds;

    @Schema(description = "会员等级编号", example = "1")
    private Long levelId;

    @Schema(description = "用户分组编号", example = "1")
    private Long groupId;

    @Schema(description = "订货主体的所属部门：门店账号=门店部门，代理人账号=代理部门",
            example = "134")
    private Long deptId;

    @Schema(description = "订货主体（门店 / 代理客户）编号：填门店=只管这一家，填代理=可切换名下门店下单",
            example = "1")
    private Long customerId;

}
