package com.lxjl.juling.module.erp.api.stock.dto;

import lombok.Data;
import lombok.experimental.Accessors;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

/**
 * 门店收货入库请求 DTO（门店确认收货 → 门店仓入库）
 *
 * @author 亚特
 */
@Data
@Accessors(chain = true)
public class ErpStoreReceiptInReqDTO {

    /**
     * 收货单编号（trade_order_receipt.id）
     */
    private Long receiptId;
    /**
     * 收货单号
     */
    private String receiptNo;
    /**
     * 门店客户编号
     */
    private Long customerId;
    /**
     * 门店部门编号
     */
    private Long deptId;
    /**
     * 收货时间
     */
    private LocalDateTime receiptTime;
    /**
     * 收货明细
     */
    private List<Item> items;

    /**
     * 收货明细行：一行 = 一条门店仓批次入库
     */
    @Data
    @Accessors(chain = true)
    public static class Item {

        /**
         * 收货单行编号（幂等键：STORE_RECEIPT + receiptItemId）
         */
        private Long receiptItemId;
        /**
         * 物料编号（erp_product.id；为空则跳过该行）
         */
        private Long productId;
        /**
         * 门店要货单行编号（血缘，仅留痕）
         */
        private Long orderItemId;
        /**
         * 实收数量（<= 0 跳过）
         */
        private BigDecimal count;
        /**
         * 单位成本（配送价，门店的进货成本）
         */
        private BigDecimal unitCost;
        /**
         * 批次号（空则按 IN{yyyyMMdd}-{收货单行 id} 生成）
         */
        private String batchNo;
        /**
         * 生产日期
         */
        private LocalDate productionDate;
        /**
         * 到期日期
         */
        private LocalDate expiryDate;
        /**
         * 备注
         */
        private String remark;

    }

}
