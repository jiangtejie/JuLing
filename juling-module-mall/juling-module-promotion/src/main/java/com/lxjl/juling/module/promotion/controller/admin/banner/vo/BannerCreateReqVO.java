package com.lxjl.juling.module.promotion.controller.admin.banner.vo;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.ToString;

/**
 * @author 棱信矩灵
 */
@Schema(description = "管理后台 - Banner 创建 Request VO")
@Data
@EqualsAndHashCode(callSuper = true)
@ToString(callSuper = true)
public class BannerCreateReqVO extends BannerBaseVO {

}
