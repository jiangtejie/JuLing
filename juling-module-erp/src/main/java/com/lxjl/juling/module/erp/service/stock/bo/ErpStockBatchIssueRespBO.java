package com.lxjl.juling.module.erp.service.stock.bo;

import lombok.Data;
import lombok.experimental.Accessors;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;

/**
 * 批次出库（FIFO 扣减）Response BO：扣减明细 + 结转成本
 *
 * @author 亚特
 */
@Data
@Accessors(chain = true)
public class ErpStockBatchIssueRespBO {

    /**
     * 实际扣减数量
     */
    private BigDecimal totalCount;
    /**
     * 结转成本合计（= Σ 明细 totalCost）
     */
    private BigDecimal totalCost;
    /**
     * 扣减明细（每个批次一行，即 FIFO 的发出顺序）
     */
    private List<Detail> details = new ArrayList<>();

    /**
     * 单条批次扣减明细
     */
    @Data
    @Accessors(chain = true)
    public static class Detail {

        /**
         * 批次库存编号
         */
        private Long batchId;
        /**
         * 批次号
         */
        private String batchNo;
        /**
         * 到期日期
         */
        private LocalDate expiryDate;
        /**
         * 入库日期
         */
        private LocalDate inDate;
        /**
         * 本批次扣减数量
         */
        private BigDecimal count;
        /**
         * 本批次单位成本
         */
        private BigDecimal unitCost;
        /**
         * 本批次结转成本
         */
        private BigDecimal totalCost;

    }

}
