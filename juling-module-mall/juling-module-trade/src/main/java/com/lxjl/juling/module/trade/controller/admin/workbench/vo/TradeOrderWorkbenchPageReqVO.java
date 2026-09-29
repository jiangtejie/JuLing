package com.lxjl.juling.module.trade.controller.admin.workbench.vo;

import com.lxjl.juling.framework.common.pojo.PageParam;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;
import org.springframework.format.annotation.DateTimeFormat;

import java.time.LocalDateTime;

import static com.lxjl.juling.framework.common.util.date.DateUtils.FORMAT_YEAR_MONTH_DAY_HOUR_MINUTE_SECOND;

/**
 * 订单工作台 - 待处理要货单分页 Request VO
 *
 * 口径（与"门店要货→审核→工作台"流程对齐）：
 *   · 订单状态 = 待发货(10)；
 *   · 审核闸门：加盟店 audit_status = 20（已通过），直营店免审；
 *   · 至少有一行未分料（alloc_mode IS NULL）。
 *
 * @author 亚特
 */
@Schema(description = "管理后台 - 订单工作台待处理要货单分页 Request VO")
@Data
public class TradeOrderWorkbenchPageReqVO extends PageParam {

    @Schema(description = "要货单号", example = "o202609280001")
    private String no;

    @Schema(description = "下单门店客户编号", example = "9")
    private Long customerId;

    @Schema(description = "创建时间")
    @DateTimeFormat(pattern = FORMAT_YEAR_MONTH_DAY_HOUR_MINUTE_SECOND)
    private LocalDateTime[] createTime;

}
