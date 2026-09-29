package com.lxjl.juling.module.erp.controller.admin.finance.vo.customeraccount;

import cn.idev.excel.annotation.ExcelIgnoreUnannotated;
import cn.idev.excel.annotation.ExcelProperty;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Schema(description = "管理后台 - 门店往来台账 Response VO")
@Data
@ExcelIgnoreUnannotated
public class ErpCustomerAccountRespVO {

    @Schema(description = "编号", requiredMode = Schema.RequiredMode.REQUIRED, example = "1024")
    @ExcelProperty("编号")
    private Long id;

    @Schema(description = "门店客户编号", requiredMode = Schema.RequiredMode.REQUIRED, example = "6")
    @ExcelProperty("门店客户编号")
    private Long customerId;

    @Schema(description = "门店名称", example = "耙二哥双碑店")
    @ExcelProperty("门店名称")
    private String customerName;

    @Schema(description = "门店部门编号", example = "134")
    private Long deptId;

    @Schema(description = "门店部门名称", example = "耙二哥双碑店")
    @ExcelProperty("部门")
    private String deptName;

    @Schema(description = "业务类型", requiredMode = Schema.RequiredMode.REQUIRED, example = "1")
    private Integer bizType;

    @Schema(description = "业务类型名称", example = "配送应收")
    @ExcelProperty("业务类型")
    private String bizTypeName;

    @Schema(description = "金额（正数=门店欠总部增加）", requiredMode = Schema.RequiredMode.REQUIRED, example = "1000.00")
    @ExcelProperty("金额")
    private BigDecimal amount;

    @Schema(description = "记账后余额（正数=门店欠总部）", requiredMode = Schema.RequiredMode.REQUIRED, example = "1000.00")
    @ExcelProperty("余额")
    private BigDecimal balance;

    @Schema(description = "业务时间", requiredMode = Schema.RequiredMode.REQUIRED)
    @ExcelProperty("业务时间")
    private LocalDateTime billTime;

    @Schema(description = "来源单据类型", example = "DELIVERY_OUT")
    @ExcelProperty("来源类型")
    private String sourceType;

    @Schema(description = "来源单号", example = "XSCK20260929000001")
    @ExcelProperty("来源单号")
    private String sourceNo;

    @Schema(description = "备注")
    @ExcelProperty("备注")
    private String remark;

    @Schema(description = "创建时间", requiredMode = Schema.RequiredMode.REQUIRED)
    private LocalDateTime createTime;

}
