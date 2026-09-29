package com.lxjl.juling.module.trade.controller.admin.order.vo;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

@Schema(description = "管理后台 - 门店收货单代录 Request VO")
@Data
public class TradeStoreReceiptCreateReqVO {

    @Schema(description = "门店要货单编号", requiredMode = Schema.RequiredMode.REQUIRED, example = "1")
    @NotNull(message = "门店要货单编号不能为空")
    private Long orderId;

    @Schema(description = "收货人", example = "张三")
    private String receiverName;

    @Schema(description = "收货人手机号", example = "13800000000")
    private String receiverMobile;

    @Schema(description = "收货凭证图片")
    private List<String> fileUrls;

    @Schema(description = "备注")
    private String remark;

    @Schema(description = "收货明细（为空表示按发货数量全额收货）")
    @Valid
    private List<Item> items;

    @Schema(description = "管理后台 - 门店收货明细")
    @Data
    public static class Item {

        @Schema(description = "门店要货单行编号", requiredMode = Schema.RequiredMode.REQUIRED, example = "1")
        @NotNull(message = "门店要货单行编号不能为空")
        private Long orderItemId;

        @Schema(description = "实收数量", requiredMode = Schema.RequiredMode.REQUIRED, example = "48")
        @NotNull(message = "实收数量不能为空")
        private BigDecimal receiptCount;

        @Schema(description = "差异原因（实收 ≠ 发货时必须填写）", example = "少一箱")
        private String diffReason;

        @Schema(description = "批次号", example = "B20260901")
        private String batchNo;

        @Schema(description = "生产日期")
        private LocalDate productionDate;

        @Schema(description = "到期日期")
        private LocalDate expiryDate;

        @Schema(description = "备注")
        private String remark;

    }

}
