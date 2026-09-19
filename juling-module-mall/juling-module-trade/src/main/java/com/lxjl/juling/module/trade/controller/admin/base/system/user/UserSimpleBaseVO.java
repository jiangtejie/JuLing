package com.lxjl.juling.module.trade.controller.admin.base.system.user;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

@Schema(description = "用户精简信息 VO")
@Data
public class UserSimpleBaseVO {

    @Schema(description = "用户编号", requiredMode = Schema.RequiredMode.REQUIRED, example = "1")
    private Long id;

    @Schema(description = "用户昵称", requiredMode = Schema.RequiredMode.REQUIRED, example = "棱信矩灵")
    private String nickname;

    @Schema(description = "用户头像", example = "https://github.com/jiangtejie/JuLing")
    private String avatar;

}