package com.lxjl.juling.module.erp.controller.admin.sale.vo.store;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.Data;

import java.math.BigDecimal;

/**
 * 「建门店」Request VO
 *
 * <p>一次动作同时建**组织节点**（system_dept，dept_type=STORE）与**客户档案**（erp_customer）——
 * 两者强制一对一（organization-architecture-design §7 决策 ④），参见 ErpStoreService。
 *
 * @author 亚特
 */
@Schema(description = "管理后台 - 建门店 Request VO")
@Data
public class ErpStoreSaveReqVO {

    @Schema(description = "门店名称", requiredMode = Schema.RequiredMode.REQUIRED, example = "萍姐鸡煲香水门店")
    @NotEmpty(message = "门店名称不能为空")
    @Size(max = 64, message = "门店名称长度不能超过 64 个字符")
    private String name;

    @Schema(description = "父组织节点编号（应为品牌或公司节点，不能挂在另一个门店下）", requiredMode = Schema.RequiredMode.REQUIRED, example = "119")
    @NotNull(message = "父组织节点不能为空")
    private Long parentId;

    @Schema(description = "店型：DIRECT 直营 / FRANCHISE 加盟（字典 erp_store_type）", requiredMode = Schema.RequiredMode.REQUIRED, example = "FRANCHISE")
    @NotEmpty(message = "店型不能为空")
    private String storeType;

    @Schema(description = "结算方式（字典 erp_settlement_mode）", example = "MONTHLY")
    private String settlementMode;

    @Schema(description = "账期天数", example = "30")
    private Integer creditDays;

    @Schema(description = "授信额度", example = "10000.00")
    private BigDecimal creditLimit;

    @Schema(description = "联系人", example = "张三")
    private String contact;

    @Schema(description = "联系手机", example = "13800138000")
    private String mobile;

}
