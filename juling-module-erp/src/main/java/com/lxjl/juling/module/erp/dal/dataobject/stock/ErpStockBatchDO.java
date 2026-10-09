package com.lxjl.juling.module.erp.dal.dataobject.stock;

import com.baomidou.mybatisplus.annotation.KeySequence;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import com.lxjl.juling.framework.mybatis.core.dataobject.BaseDO;
import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDate;

/**
 * ERP 批次库存 DO
 *
 * 维度：仓库 × 物料 × 批次（sku_id 预留，0 = 按物料记账）。
 * 状态用「数量分列」表达四态（在仓 count / 在途 transitCount / 占用 occupiedCount / 待检 inspectingCount），
 * 理由见 sql/local/35_stock_center.sql 与 docs/stock-center.md：批次是 FIFO 的发出单元、也是成本载体，
 * 把状态做进主键会让同一批次的成本/效期在 4 行里漂移。
 *
 * 可用量 = count − occupiedCount + transitCount
 *
 * @author 亚特
 */
@TableName("erp_stock_batch")
@KeySequence("erp_stock_batch_seq") // 用于 Oracle、PostgreSQL、Kingbase、DB2、H2 数据库的主键自增。如果是 MySQL 等数据库，可不写。
@Data
@EqualsAndHashCode(callSuper = true)
@ToString(callSuper = true)
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ErpStockBatchDO extends BaseDO {

    /**
     * 编号
     */
    @TableId
    private Long id;
    /**
     * 仓库编号
     *
     * 关联 {@link ErpWarehouseDO#getId()}
     */
    private Long warehouseId;
    /**
     * 物料编号
     *
     * 关联 {@link com.lxjl.juling.module.erp.dal.dataobject.product.ErpProductDO#getId()}
     */
    private Long productId;
    /**
     * SKU 编号（预留）
     *
     * 本切片恒为 0L，表示按物料记账；SKU 统一是后续工作
     */
    private Long skuId;
    /**
     * 批次号
     */
    private String batchNo;
    /**
     * 生产日期
     */
    private LocalDate productionDate;
    /**
     * 到期日期
     *
     * 效期预警口径；FIFO 的次级排序键（同入库日期时先到期先出）
     */
    private LocalDate expiryDate;
    /**
     * 入库日期
     *
     * FIFO 主排序键：先入库先出
     */
    private LocalDate inDate;
    /**
     * 在仓数量
     *
     * 含被占用的部分，与 {@link ErpStockDO#getCount()} 同一口径
     */
    private BigDecimal count;
    /**
     * 在途数量
     */
    private BigDecimal transitCount;
    /**
     * 占用数量
     *
     * 在仓数量的子集：已被单据锁定、尚未出库
     */
    private BigDecimal occupiedCount;
    /**
     * 待检数量
     */
    private BigDecimal inspectingCount;
    /**
     * 批次单位成本（= 入库单价）
     */
    private BigDecimal unitCost;
    /**
     * 批次在仓成本 = count × unitCost
     */
    private BigDecimal totalCost;
    /**
     * 来源业务类型
     *
     * 枚举 {@link com.lxjl.juling.module.erp.enums.stock.ErpStockRecordBizTypeEnum}
     */
    private Integer sourceBizType;
    /**
     * 来源单据编号
     */
    private Long sourceBizId;
    /**
     * 来源单据项编号
     *
     * 与 {@link #sourceBizType} 一起构成入库记账的幂等键
     */
    private Long sourceBizItemId;
    /**
     * 来源单号
     */
    private String sourceBizNo;
    /**
     * 来源是否已反审核冲销：0 否 / 1 是
     */
    private Integer sourceReversed;
    /**
     * 备注
     */
    private String remark;

}
