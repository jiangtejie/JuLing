package com.lxjl.juling.module.member.controller.app.user.vo;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotEmpty;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.hibernate.validator.constraints.Length;

/**
 * 用户 APP - 用原密码修改密码 Request VO
 *
 * 与 {@link AppMemberUserUpdatePasswordReqVO} 的区别：那个要短信验证码（私域订货没有短信渠道，
 * 发不出码），这个校验原密码，订货账号在 H5 自助改密走这条路。
 *
 * @author 亚特
 */
@Schema(description = "用户 APP - 用原密码修改密码 Request VO")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class AppMemberUserUpdatePasswordByOldReqVO {

    @Schema(description = "原密码", requiredMode = Schema.RequiredMode.REQUIRED, example = "yt@123456")
    @NotEmpty(message = "原密码不能为空")
    private String oldPassword;

    @Schema(description = "新密码", requiredMode = Schema.RequiredMode.REQUIRED, example = "yt@654321")
    @NotEmpty(message = "新密码不能为空")
    @Length(min = 6, max = 32, message = "密码长度为 6-32 位")
    private String newPassword;

}
