package com.lxjl.juling.module.erp.controller.admin.stock.vo.batch;

import com.lxjl.juling.framework.common.pojo.PageParam;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.ToString;

@Schema(description = "管理后台 - ERP 批次库存分页 Request VO")
@Data
@EqualsAndHashCode(callSuper = true)
@ToString(callSuper = true)
public class ErpStockBatchPageReqVO extends PageParam {

    @Schema(description = "仓库编号", example = "2")
    private Long warehouseId;

    @Schema(description = "物料编号", example = "6")
    private Long productId;

    @Schema(description = "批次号（模糊匹配）", example = "IN20260910-101")
    private String batchNo;

    @Schema(description = "来源单号（模糊匹配）", example = "QTRK20260928000001")
    private String sourceBizNo;

}
