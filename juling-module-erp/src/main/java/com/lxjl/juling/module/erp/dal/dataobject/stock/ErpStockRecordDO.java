package com.lxjl.juling.module.erp.dal.dataobject.stock;

import com.lxjl.juling.framework.mybatis.core.dataobject.BaseDO;
import com.lxjl.juling.module.erp.dal.dataobject.product.ErpProductDO;
import com.lxjl.juling.module.erp.enums.stock.ErpStockRecordBizTypeEnum;
import com.baomidou.mybatisplus.annotation.KeySequence;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.*;

import java.math.BigDecimal;

/**
 * ERP 产品库存明细 DO
 *
 * @author 亚特
 */
@TableName("erp_stock_record")
@KeySequence("erp_stock_record_seq") // 用于 Oracle、PostgreSQL、Kingbase、DB2、H2 数据库的主键自增。如果是 MySQL 等数据库，可不写。
@Data
@EqualsAndHashCode(callSuper = true)
@ToString(callSuper = true)
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ErpStockRecordDO extends BaseDO {

    /**
     * 编号
     */
    @TableId
    private Long id;
    /**
     * 产品编号
     *
     * 关联 {@link ErpProductDO#getId()}
     */
    private Long productId;
    /**
     * 仓库编号
     *
     * 关联 {@link ErpWarehouseDO#getId()}
     */
    private Long warehouseId;
    /**
     * 出入库数量
     *
     * 正数，表示入库；负数，表示出库
     */
    private BigDecimal count;
    /**
     * 总库存量
     *
     * 出入库之后，目前的库存量
     */
    private BigDecimal totalCount;
    /**
     * 业务类型
     *
     * 枚举 {@link ErpStockRecordBizTypeEnum}
     */
    private Integer bizType;
    /**
     * 业务编号
     *
     * 例如说：{@link ErpStockInDO#getId()}
     */
    private Long bizId;
    /**
     * 业务项编号
     *
     * 例如说：{@link ErpStockInItemDO#getId()}
     */
    private Long bizItemId;
    /**
     * 业务单号
     *
     * 例如说：{@link ErpStockInDO#getNo()}
     */
    private String bizNo;

    /**
     * 批次号
     *
     * 出库按 FIFO 拆批后，一行流水对应一个批次；为空表示启用批次管理之前的老流水
     */
    private String batchNo;
    /**
     * 库存状态
     *
     * 枚举 {@link com.lxjl.juling.module.erp.service.stock.ErpStockBatchService} 的 STATE_*
     */
    private String stockState;
    /**
     * 批次单位成本
     */
    private BigDecimal unitCost;
    /**
     * 本行成本金额 = count × unitCost（出库为负，即结转成本）
     */
    private BigDecimal totalCost;
    /**
     * SKU 编号（预留）：空/0 表示按物料记账
     */
    private Long skuId;

}