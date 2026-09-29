package com.lxjl.juling.module.trade.controller.app.order.vo;

import com.lxjl.juling.framework.common.pojo.PageParam;
import com.lxjl.juling.framework.common.validation.InEnum;
import com.lxjl.juling.module.trade.enums.order.TradeOrderStatusEnum;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

@Schema(description = "交易订单分页 Request VO")
@Data
public class AppTradeOrderPageReqVO extends PageParam {

    @Schema(description = "订单状态", example = "1")
    @InEnum(value = TradeOrderStatusEnum.class, message = "订单状态必须是 {value}")
    private Integer status;

    /**
     * 是否已通过门店要货审核（两级审批：供应链 → 财务出纳）
     *
     * - true：audit_status = 20（已通过，或直营门店免审）→ 门店端「待发货」
     * - false：审核未完成（待提交 0 / 审核中 10 / 已驳回 30）→ 门店端「处理中」
     * - 不传：不限（与 status 组合使用，例如 status=10 时区分这两类）
     */
    @Schema(description = "是否已通过门店要货审核", example = "true")
    private Boolean auditPassed;

}
