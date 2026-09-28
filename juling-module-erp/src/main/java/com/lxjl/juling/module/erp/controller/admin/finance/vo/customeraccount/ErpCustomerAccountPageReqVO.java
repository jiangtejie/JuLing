package com.lxjl.juling.module.erp.controller.admin.finance.vo.customeraccount;

import com.lxjl.juling.framework.common.pojo.PageParam;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.ToString;
import org.springframework.format.annotation.DateTimeFormat;

import java.time.LocalDateTime;

import static com.lxjl.juling.framework.common.util.date.DateUtils.FORMAT_YEAR_MONTH_DAY_HOUR_MINUTE_SECOND;

@Schema(description = "管理后台 - 门店往来台账分页 Request VO")
@Data
@EqualsAndHashCode(callSuper = true)
@ToString(callSuper = true)
public class ErpCustomerAccountPageReqVO extends PageParam {

    @Schema(description = "门店客户编号", example = "6")
    private Long customerId;

    @Schema(description = "门店部门编号", example = "134")
    private Long deptId;

    @Schema(description = "业务类型：1 配送应收 / 2 直拨应收 / 3 收款 / 4 收货差异调整 / 5 退货冲减 / 11 配送应收冲销 / 12 直拨应收冲销", example = "1")
    private Integer bizType;

    @Schema(description = "来源单号（模糊匹配）", example = "XSCK20260929000001")
    private String sourceNo;

    @Schema(description = "业务时间")
    @DateTimeFormat(pattern = FORMAT_YEAR_MONTH_DAY_HOUR_MINUTE_SECOND)
    private LocalDateTime[] billTime;

}
