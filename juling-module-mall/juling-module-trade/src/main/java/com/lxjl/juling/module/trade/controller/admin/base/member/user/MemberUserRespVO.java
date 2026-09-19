package com.lxjl.juling.module.trade.controller.admin.base.member.user;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

@Schema(description = "管理后台 - 会员用户 Response VO")
@Data
public class MemberUserRespVO {

    @Schema(description = "用户 ID", requiredMode = Schema.RequiredMode.REQUIRED, example = "1")
    private Long id;

    @Schema(description = "用户昵称", requiredMode = Schema.RequiredMode.REQUIRED, example = "棱信矩灵")
    private String nickname;

    @Schema(description = "用户头像", example = "https://github.com/jiangtejie/JuLing")
    private String avatar;

}
