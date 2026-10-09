package com.lxjl.juling.module.erp.controller.admin.stock.vo.batch;

import com.lxjl.juling.framework.common.pojo.PageParam;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.ToString;

import java.util.List;

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

    @Schema(description = "仓库类型：STORE 只看门店仓 / CENTER 只看中心库；不传=全部", example = "STORE")
    private String warehouseType;

    @Schema(description = "门店客户编号：只看这家门店的门店仓库存（门店库存页用）", example = "6")
    private Long customerId;

    /**
     * 仓库编号集合（由 Controller 按 warehouseType 解析后回填，不接受前端直接传）
     */
    @Schema(hidden = true)
    private List<Long> warehouseIds;

}
