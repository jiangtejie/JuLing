package com.lxjl.juling.module.trade.controller.admin.order.vo;

import com.lxjl.juling.framework.common.pojo.PageParam;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.ToString;
import org.springframework.format.annotation.DateTimeFormat;

import java.time.LocalDateTime;

import static com.lxjl.juling.framework.common.util.date.DateUtils.FORMAT_YEAR_MONTH_DAY_HOUR_MINUTE_SECOND;

@Schema(description = "管理后台 - 门店收货单分页 Request VO")
@Data
@EqualsAndHashCode(callSuper = true)
@ToString(callSuper = true)
public class TradeStoreReceiptPageReqVO extends PageParam {

    @Schema(description = "收货单号（模糊匹配）", example = "MDSH20260929000001")
    private String no;

    @Schema(description = "门店要货单号（模糊匹配）", example = "20260929000001")
    private String orderNo;

    @Schema(description = "配送出库单号（模糊匹配）", example = "XSCK20260929000001")
    private String saleOutNo;

    @Schema(description = "门店客户编号", example = "6")
    private Long customerId;

    @Schema(description = "门店部门编号", example = "134")
    private Long deptId;

    @Schema(description = "状态：0 待确认 / 10 已确认 / 20 已作废", example = "0")
    private Integer status;

    @Schema(description = "差异类型：0 无差异 / 1 少收 / 2 多收 / 3 破损 / 4 混合", example = "1")
    private Integer diffType;

    @Schema(description = "收货时间")
    @DateTimeFormat(pattern = FORMAT_YEAR_MONTH_DAY_HOUR_MINUTE_SECOND)
    private LocalDateTime[] receiveTime;

    @Schema(description = "创建时间")
    @DateTimeFormat(pattern = FORMAT_YEAR_MONTH_DAY_HOUR_MINUTE_SECOND)
    private LocalDateTime[] createTime;

}
