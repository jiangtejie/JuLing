package com.lxjl.juling.module.member.controller.admin.user.vo;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import lombok.Data;
import org.hibernate.validator.constraints.Length;

/**
 * 管理后台 - 开订货账号 Request VO
 *
 * 私域订货场景：由后台给加盟客户开账号（账号名通常就是门店名）+ 初始密码 + 绑定门店。
 * 刻意**不继承** {@link MemberUserBaseVO}：C 端那套「昵称/头像/性别/生日/等级」对订货账号没意义，
 * 也不想把父类的 @NotNull 校验（如昵称）强加给开账号流程。
 *
 * @author 亚特
 */
@Schema(description = "管理后台 - 开订货账号 Request VO")
@Data
public class MemberUserCreateReqVO {

    @Schema(description = "订货账号（登录名，通常就是门店名）", requiredMode = Schema.RequiredMode.REQUIRED, example = "耙二哥双碑店")
    @NotEmpty(message = "订货账号不能为空")
    @Length(min = 2, max = 64, message = "订货账号长度为 2-64 位")
    private String username;

    @Schema(description = "初始密码", requiredMode = Schema.RequiredMode.REQUIRED, example = "yt@123456")
    @NotEmpty(message = "初始密码不能为空")
    @Length(min = 6, max = 32, message = "密码长度为 6-32 位")
    private String password;

    @Schema(description = "所属客户（门店/代理）编号", requiredMode = Schema.RequiredMode.REQUIRED, example = "6")
    @NotNull(message = "所属客户（门店）不能为空")
    private Long customerId;

    @Schema(description = "所属部门（门店节点）编号", example = "134")
    private Long deptId;

    @Schema(description = "联系人 / 显示名（为空时取订货账号）", example = "李店长")
    private String nickname;

    @Schema(description = "手机号（可选，不填则只能用订货账号登录）", example = "13900000006")
    private String mobile;

    @Schema(description = "邮箱", example = "store@example.com")
    private String email;

    @Schema(description = "状态：0 开启 / 1 关闭，默认开启", example = "0")
    private Integer status;

    @Schema(description = "备注", example = "双碑店订货账号")
    private String mark;

}
