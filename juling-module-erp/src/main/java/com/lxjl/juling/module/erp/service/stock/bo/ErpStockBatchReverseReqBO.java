package com.lxjl.juling.module.erp.service.stock.bo;

import lombok.Data;
import lombok.experimental.Accessors;

/**
 * 批次冲销 Request BO（反审核用）
 *
 * @author 亚特
 */
@Data
@Accessors(chain = true)
public class ErpStockBatchReverseReqBO {

    /**
     * 原业务类型：用于定位来源批次 / 原出库流水
     */
    private Integer sourceBizType;
    /**
     * 原业务项编号：定位来源批次 / 原出库流水
     */
    private Long sourceBizItemId;
    /**
     * 冲销业务类型（写流水用），例如 OTHER_IN_CANCEL
     */
    private Integer targetBizType;
    /**
     * 业务编号（原单编号）
     */
    private Long bizId;
    /**
     * 业务单号（原单号）
     */
    private String bizNo;
    /**
     * 备注
     */
    private String remark;

}
