package com.lxjl.juling.module.trade.dal.dataobject.order;

import com.baomidou.mybatisplus.annotation.KeySequence;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import com.lxjl.juling.framework.mybatis.core.dataobject.BaseDO;
import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDate;

/**
 * 门店收货单明细 DO
 *
 * 一行对应一条要货单行（order_item_id）：应收数量 = ERP 配送出库单实际发出的数量，
 * 实收数量由门店填写，差异 = 实收 − 应收。
 * 确认收货时按「一行一条批次」记入门店仓（sourceBizItemId = 本行 id，天然幂等）。
 *
 * @author 亚特
 */
@TableName("trade_order_receipt_item")
@KeySequence("trade_order_receipt_item_seq") // 用于 Oracle、PostgreSQL、Kingbase、DB2、H2 数据库的主键自增。如果是 MySQL 等数据库，可不写。
@Data
@EqualsAndHashCode(callSuper = true)
@ToString(callSuper = true)
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class TradeOrderReceiptItemDO extends BaseDO {

    /**
     * 编号
     */
    @TableId
    private Long id;
    /**
     * 收货单编号
     */
    private Long receiptId;
    /**
     * 门店要货单行编号
     *
     * 关联 {@link TradeOrderItemDO#getId()}
     */
    private Long orderItemId;
    /**
     * 商品 SPU 编号
     */
    private Long spuId;
    /**
     * 商品 SKU 编号
     */
    private Long skuId;
    /**
     * 商品名称（快照）
     */
    private String spuName;
    /**
     * 商品属性（快照）
     */
    private String properties;
    /**
     * 商品图片（快照）
     */
    private String picUrl;
    /**
     * ERP 物料编号（用于门店仓入库；为空表示该行未对应 ERP 物料）
     */
    private Long productId;
    /**
     * 配送单价（门店进货成本；门店库存的批次单位成本）
     *
     * <p>**单位：元**。注意与 {@code trade_order_item.price}（单位：分）区分 ——
     * 本字段在下推 ERP 之前**已经由调用方换算成元**（见 TradeOrderWorkbenchServiceImpl#unitPriceOf），
     * 并直接作为 ERP 的 unitCost / 往来账金额使用，**此处不得再换算第二次**。
     */
    private BigDecimal price;
    /**
     * 应收（发货）数量
     */
    private BigDecimal expectCount;
    /**
     * 实收数量
     */
    private BigDecimal receiptCount;
    /**
     * 差异数量（实收 − 应收，正数 = 多收）
     */
    private BigDecimal diffCount;
    /**
     * 差异金额
     */
    private BigDecimal diffAmount;
    /**
     * 差异原因（实收 ≠ 应收时必填）
     */
    private String diffReason;
    /**
     * 批次号（空则入库时按 IN{yyyyMMdd}-{收货单行 id} 生成）
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
