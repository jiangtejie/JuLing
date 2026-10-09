package com.lxjl.juling.module.system.controller.admin.code.vo;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * 管理后台 - 编码规则 Response VO
 *
 * @author 亚特
 */
@Schema(description = "管理后台 - 编码规则 Response VO")
@Data
public class SystemCodeRuleRespVO {

    @Schema(description = "编号", example = "1")
    private Long id;

    @Schema(description = "规则标识", example = "erp_customer")
    private String ruleKey;

    @Schema(description = "规则名称", example = "客户（门店）编码")
    private String name;

    @Schema(description = "编码前缀", example = "KH")
    private String prefix;

    @Schema(description = "流水号长度", example = "6")
    private Integer seqLength;

    @Schema(description = "当前已分配到的流水值", example = "15")
    private Long currentValue;

    @Schema(description = "下一个编码预览（= 前缀 + 当前值+1 左补零）", example = "KH000016")
    private String nextCode;

    @Schema(description = "备注")
    private String remark;

    @Schema(description = "创建时间")
    private LocalDateTime createTime;

}