package com.lxjl.juling.module.trade.controller.app.order.vo;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

/**
 * 用户 App - 可下单门店 Response VO
 *
 * 门店订货链 S1：H5 门店切换器使用。
 *
 * @author 亚特
 */
@Schema(description = "用户 App - 可下单门店 Response VO")
@Data
public class AppTradeOrderStoreRespVO {

    @Schema(description = "门店客户编号", requiredMode = Schema.RequiredMode.REQUIRED, example = "1")
    private Long customerId;

    @Schema(description = "门店名称", requiredMode = Schema.RequiredMode.REQUIRED, example = "耙二哥双碑店")
    private String customerName;

    @Schema(description = "门店所属部门编号", example = "134")
    private Long deptId;

    @Schema(description = "结算模式（PREPAID 先款后货 / MONTHLY 月结）", example = "PREPAID")
    private String settlementMode;

}
