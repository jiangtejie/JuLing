package com.lxjl.juling.module.trade.dal.dataobject.order;

import com.baomidou.mybatisplus.annotation.KeySequence;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import com.lxjl.juling.framework.mybatis.core.dataobject.BaseDO;
import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * 门店收货单 DO
 *
 * 何时产生：ERP「配送出库单」（统配下推生成 XSCK…）审核通过后，由
 * {@link com.lxjl.juling.module.erp.api.storealloc.event.ErpStoreDeliveryAuditedEvent} 同步事件生成，
 * 此时收货单是「待确认」；门店在 H5 逐行填实收数量并提交后变为「已确认」，
 * 实收数量同时按批次记入该门店的门店仓（门店库存账）。
 *
 * 差异（实收 − 应收）是这一版的核心：门店少收/破损、中心库多发都在这里留痕，
 * 并同步生成门店往来台账的调整分录（见 docs/store-receipt-and-receivables-design.md）。
 *
 * @author 亚特
 */
@TableName("trade_order_receipt")
@KeySequence("trade_order_receipt_seq") // 用于 Oracle、PostgreSQL、Kingbase、DB2、H2 数据库的主键自增。如果是 MySQL 等数据库，可不写。
@Data
@EqualsAndHashCode(callSuper = true)
@ToString(callSuper = true)
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class TradeOrderReceiptDO extends BaseDO {

    /**
     * 编号
     */
    @TableId
    private Long id;
    /**
     * 收货单号（单据平台 STORE_RECEIPT → MDSH + yyyyMMdd + 6 位流水）
     */
    private String no;
    /**
     * 门店要货单编号
     *
     * 关联 {@link TradeOrderDO#getId()}
     */
    private Long orderId;
    /**
     * 门店要货单号
     */
    private String orderNo;
    /**
     * 门店客户编号
     */
    private Long customerId;
    /**
     * 门店部门编号
     */
    private Long deptId;
    /**
     * 提交收货的会员编号（后台代录时为空）
     */
    private Long memberUserId;
    /**
     * 门店仓编号（erp_warehouse.id，仓库类型 STORE）
     */
    private Long warehouseId;
    /**
     * 配送出库单编号（erp_sale_out.id）
     */
    private Long saleOutId;
    /**
     * 配送出库单号
     */
    private String saleOutNo;
    /**
     * 状态
     *
     * 枚举 {@link com.lxjl.juling.module.trade.enums.order.TradeStoreReceiptStatusEnum}
     */
    private Integer status;
    /**
     * 差异类型
     *
     * 枚举 {@link com.lxjl.juling.module.trade.enums.order.TradeStoreReceiptDiffTypeEnum}
     */
    private Integer diffType;
    /**
     * 应收数量合计
     */
    private BigDecimal totalCount;
    /**
     * 实收数量合计
     */
    private BigDecimal receiptCount;
    /**
     * 差异数量合计（实收 − 应收，正数 = 多收）
     */
    private BigDecimal diffCount;
    /**
     * 应收金额合计（按配送价）
     */
    private BigDecimal totalPrice;
    /**
     * 实收金额合计（按配送价）
     */
    private BigDecimal receiptPrice;
    /**
     * 差异金额合计（正数 = 多收）
     */
    private BigDecimal diffAmount;
    /**
     * 收货时间
     */
    private LocalDateTime receiveTime;
    /**
     * 收货人
     */
    private String receiverName;
    /**
     * 收货人手机号
     */
    private String receiverMobile;
    /**
     * 收货凭证图片（JSON 数组字符串）
     */
    private String fileUrls;
    /**
     * 备注
     */
    private String remark;
    /**
     * 作废人编号
     */
    private Long cancelUserId;
    /**
     * 作废时间
     */
    private LocalDateTime cancelTime;
    /**
     * 作废原因
     */
    private String cancelReason;

}
