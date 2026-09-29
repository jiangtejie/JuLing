package com.lxjl.juling.module.member.controller.app.user.vo;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Schema(description = "用户 APP - 订货账号个人信息 Response VO")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class AppMemberUserInfoRespVO {

    @Schema(description = "用户编号", requiredMode = Schema.RequiredMode.REQUIRED, example = "1")
    private Long id;

    @Schema(description = "用户昵称", requiredMode = Schema.RequiredMode.REQUIRED, example = "亚特")
    private String nickname;

    @Schema(description = "用户头像", requiredMode = Schema.RequiredMode.REQUIRED, example = "https://github.com/jiangtejie/JuLing")
    private String avatar;

    @Schema(description = "订货账号（订货人的登录名，就是订货人名字）", example = "张三")
    private String username;

    @Schema(description = "手机号（私域订货场景可为空）", example = "15601691300")
    private String mobile;

    @Schema(description = "邮箱", example = "member@example.com")
    private String email;

    @Schema(description = "用户性别", requiredMode = Schema.RequiredMode.REQUIRED, example = "1")
    private Integer sex;

}
