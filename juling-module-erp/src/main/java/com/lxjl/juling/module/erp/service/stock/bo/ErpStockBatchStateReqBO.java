package com.lxjl.juling.module.erp.service.stock.bo;

import lombok.Data;
import lombok.experimental.Accessors;

import java.math.BigDecimal;

/**
 * 批次状态数量登记 Request BO（在途 / 占用 / 待检）
 *
 * 可用量 = 在仓 − 占用 + 在途，本 BO 是「占用/在途/待检」三类数量的登记入口：
 * 订单占用、采购在途、到货待检等场景都通过它增减对应状态的数量。
 *
 * @author 亚特
 */
@Data
@Accessors(chain = true)
public class ErpStockBatchStateReqBO {

    /**
     * 仓库编号
     */
    private Long warehouseId;
    /**
     * 物料编号
     */
    private Long productId;
    /**
     * SKU 编号（预留，为空按 0 处理）
     */
    private Long skuId;
    /**
     * 批次号：批次不存在时按此号新建一条空批次
     */
    private String batchNo;
    /**
     * 状态：IN_STOCK 在仓 / IN_TRANSIT 在途 / OCCUPIED 占用 / INSPECTING 待检
     */
    private String state;
    /**
     * 增量数量：正数增加、负数减少
     */
    private BigDecimal delta;
    /**
     * 备注
     */
    private String remark;

}
