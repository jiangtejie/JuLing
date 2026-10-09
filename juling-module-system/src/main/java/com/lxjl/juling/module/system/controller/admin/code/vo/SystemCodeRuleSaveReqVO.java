package com.lxjl.juling.module.system.controller.admin.code.vo;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.Data;

/**
 * 管理后台 - 编码规则创建/修改 Request VO
 *
 * @author 亚特
 */
@Schema(description = "管理后台 - 编码规则创建/修改 Request VO")
@Data
public class SystemCodeRuleSaveReqVO {

    @Schema(description = "编号", example = "1")
    private Long id;

    @Schema(description = "规则标识（与主数据对象一一对应，如 erp_customer）",
            requiredMode = Schema.RequiredMode.REQUIRED, example = "erp_customer")
    @NotEmpty(message = "规则标识不能为空")
    @Size(max = 64, message = "规则标识长度不能超过 64 个字符")
    private String ruleKey;

    @Schema(description = "规则名称", requiredMode = Schema.RequiredMode.REQUIRED, example = "客户（门店）编码")
    @NotEmpty(message = "规则名称不能为空")
    @Size(max = 64, message = "规则名称长度不能超过 64 个字符")
    private String name;

    @Schema(description = "编码前缀", requiredMode = Schema.RequiredMode.REQUIRED, example = "KH")
    @NotEmpty(message = "编码前缀不能为空")
    @Size(max = 16, message = "编码前缀长度不能超过 16 个字符")
    private String prefix;

    @Schema(description = "流水号长度（左补零）", requiredMode = Schema.RequiredMode.REQUIRED, example = "6")
    @NotNull(message = "流水号长度不能为空")
    @Min(value = 1, message = "流水号长度至少 1 位")
    @Max(value = 12, message = "流水号长度最多 12 位")
    private Integer seqLength;

    @Schema(description = "当前已分配到的流水值（一般不用手改，改小会发出重复编码）", example = "15")
    private Long currentValue;

    @Schema(description = "备注", example = "门店 / 往来客户")
    @Size(max = 255, message = "备注长度不能超过 255 个字符")
    private String remark;

}