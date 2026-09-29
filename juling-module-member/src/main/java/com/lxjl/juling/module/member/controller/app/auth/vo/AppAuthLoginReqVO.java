package com.lxjl.juling.module.member.controller.app.auth.vo;

import cn.hutool.core.util.StrUtil;
import com.lxjl.juling.framework.common.validation.Mobile;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.hibernate.validator.constraints.Length;

import jakarta.validation.constraints.AssertTrue;
import jakarta.validation.constraints.NotEmpty;

@Schema(description = "用户 APP - 订货账号 + 密码登录 Request VO")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class AppAuthLoginReqVO {

    @Schema(description = "手机号（兼容口径：account 为空时用它登录；私域订货场景可留空）", example = "15601691300")
    @Mobile
    private String mobile;

    @Schema(description = "订货账号（私域订货 H5 的登录名，就是订货人名字）", example = "张三")
    private String account;

    @Schema(description = "密码", requiredMode = Schema.RequiredMode.REQUIRED, example = "buzhidao")
    @NotEmpty(message = "密码不能为空")
    @Length(min = 4, max = 16, message = "密码长度为 4-16 位")
    private String password;

    @AssertTrue(message = "账号或手机号至少填一个")
    public boolean isAccountPresent() {
        return StrUtil.isNotBlank(account) || StrUtil.isNotBlank(mobile);
    }

}
