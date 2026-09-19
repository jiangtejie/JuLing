package com.lxjl.juling.module.member.controller.app.social.vo;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

@Schema(description = "用户 APP - 社交用户 Response VO")
@Data
public class AppSocialUserRespVO {

    @Schema(description = "社交用户的 openid", requiredMode = Schema.RequiredMode.REQUIRED, example = "IPRmJ0wvBptiPIlGEZiPewGwiEiE")
    private String openid;

    @Schema(description = "社交用户的昵称", requiredMode = Schema.RequiredMode.REQUIRED, example = "棱信矩灵")
    private String nickname;

    @Schema(description = "社交用户的头像", requiredMode = Schema.RequiredMode.REQUIRED, example = "https://github.com/jiangtejie/JuLing")
    private String avatar;

}
