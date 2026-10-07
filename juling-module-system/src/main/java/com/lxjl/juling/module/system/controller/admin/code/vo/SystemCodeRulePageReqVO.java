package com.lxjl.juling.module.system.controller.admin.code.vo;

import com.lxjl.juling.framework.common.pojo.PageParam;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.ToString;

/**
 * 管理后台 - 编码规则分页 Request VO
 *
 * @author 亚特
 */
@Schema(description = "管理后台 - 编码规则分页 Request VO")
@Data
@EqualsAndHashCode(callSuper = true)
@ToString(callSuper = true)
public class SystemCodeRulePageReqVO extends PageParam {

    @Schema(description = "规则标识（模糊）", example = "erp_")
    private String ruleKey;

    @Schema(description = "规则名称（模糊）", example = "客户")
    private String name;

}