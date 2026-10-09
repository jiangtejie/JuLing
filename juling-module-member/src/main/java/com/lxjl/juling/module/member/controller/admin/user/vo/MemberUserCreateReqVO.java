package com.lxjl.juling.module.member.controller.admin.user.vo;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import lombok.Data;
import org.hibernate.validator.constraints.Length;

import java.util.List;

/**
 * 管理后台 - 开订货账号 Request VO
 *
 * 私域订货场景：由后台给订货人开账号（账号名填订货人名字）+ 初始密码 + **授权门店**。
 * 授权门店有两种口径：
 *   · 一家门店 → 加盟店自己的订货账号；
 *   · 多家门店 → 片区订货管理人（业务口中的「代理人」，只是帮忙下单，不承担账期与结算）。
 * 刻意**不继承** {@link MemberUserBaseVO}：C 端那套「昵称/头像/性别/生日/等级」对订货账号没意义，
 * 也不想把父类的 @NotNull 校验（如昵称）强加给开账号流程。
 *
 * @author 亚特
 */
@Schema(description = "管理后台 - 开订货账号 Request VO")
@Data
public class MemberUserCreateReqVO {

    @Schema(description = "订货账号（订货人的登录名，填订货人名字）", requiredMode = Schema.RequiredMode.REQUIRED, example = "张三")
    @NotEmpty(message = "订货账号不能为空")
    @Length(min = 2, max = 64, message = "订货账号长度为 2-64 位")
    private String username;

    @Schema(description = "初始密码", requiredMode = Schema.RequiredMode.REQUIRED, example = "yt@123456")
    @NotEmpty(message = "初始密码不能为空")
    @Length(min = 6, max = 32, message = "密码长度为 6-32 位")
    private String password;

    @Schema(description = "授权门店编号列表：账号可给哪些门店下单（至少一个；一家店填一条，片区管理人多条）",
            requiredMode = Schema.RequiredMode.REQUIRED, example = "[6]")
    @NotEmpty(message = "至少授权一个门店")
    private List<Long> storeCustomerIds;

    @Schema(description = "默认门店编号（H5 首次进入用它）；不填或不在授权范围内时取第一家", example = "6")
    private Long defaultStoreCustomerId;

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
