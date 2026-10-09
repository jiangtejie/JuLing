package com.lxjl.juling.module.erp.service.stock.bo;

import lombok.Data;
import lombok.experimental.Accessors;

import java.math.BigDecimal;

/**
 * 批次出库（FIFO 扣减）Request BO
 *
 * @author 亚特
 */
@Data
@Accessors(chain = true)
public class ErpStockBatchOutReqBO {

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
     * 出库数量（正数）
     */
    private BigDecimal count;

    /**
     * 业务类型
     *
     * 枚举 {@link com.lxjl.juling.module.erp.enums.stock.ErpStockRecordBizTypeEnum}
     */
    private Integer bizType;
    /**
     * 业务编号
     */
    private Long bizId;
    /**
     * 业务项编号
     */
    private Long bizItemId;
    /**
     * 业务单号
     */
    private String bizNo;
    /**
     * 备注
     */
    private String remark;

}
