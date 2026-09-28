package com.lxjl.juling.module.erp.controller.admin.finance.vo.customeraccount;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import java.math.BigDecimal;

@Schema(description = "管理后台 - 门店往来余额汇总 Response VO")
@Data
public class ErpCustomerAccountSummaryRespVO {

    @Schema(description = "门店客户编号", requiredMode = Schema.RequiredMode.REQUIRED, example = "6")
    private Long customerId;

    @Schema(description = "门店名称", example = "耙二哥双碑店")
    private String customerName;

    @Schema(description = "门店部门编号", example = "134")
    private Long deptId;

    @Schema(description = "门店部门名称", example = "耙二哥双碑店")
    private String deptName;

    @Schema(description = "累计应收", example = "1000.00")
    private BigDecimal totalReceivable;

    @Schema(description = "累计已收 / 冲减", example = "800.00")
    private BigDecimal totalReceived;

    @Schema(description = "当前余额（正数=门店欠总部）", example = "200.00")
    private BigDecimal balance;

}
