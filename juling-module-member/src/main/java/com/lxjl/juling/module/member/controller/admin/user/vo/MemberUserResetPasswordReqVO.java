package com.lxjl.juling.module.member.controller.admin.user.vo;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import lombok.Data;
import org.hibernate.validator.constraints.Length;

/**
 * 管理后台 - 重置订货账号密码 Request VO
 *
 * 私域订货不接短信渠道，所以「忘记密码」由后台重置，不需要验证码。
 *
 * @author 亚特
 */
@Schema(description = "管理后台 - 重置订货账号密码 Request VO")
@Data
public class MemberUserResetPasswordReqVO {

    @Schema(description = "会员编号", requiredMode = Schema.RequiredMode.REQUIRED, example = "3")
    @NotNull(message = "会员编号不能为空")
    private Long id;

    @Schema(description = "新密码", requiredMode = Schema.RequiredMode.REQUIRED, example = "yt@123456")
    @NotEmpty(message = "新密码不能为空")
    @Length(min = 6, max = 32, message = "密码长度为 6-32 位")
    private String password;

}
