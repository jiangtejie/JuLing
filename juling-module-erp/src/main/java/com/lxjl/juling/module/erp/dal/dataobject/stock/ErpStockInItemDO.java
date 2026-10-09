package com.lxjl.juling.module.erp.dal.dataobject.stock;

import com.lxjl.juling.framework.mybatis.core.dataobject.BaseDO;
import com.lxjl.juling.module.erp.dal.dataobject.product.ErpProductDO;
import com.baomidou.mybatisplus.annotation.KeySequence;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.*;

import java.math.BigDecimal;

/**
 * ERP 其它入库单项 DO
 *
 * @author 亚特
 */
@TableName("erp_stock_in_item")
@KeySequence("erp_stock_in_item_seq") // 用于 Oracle、PostgreSQL、Kingbase、DB2、H2 数据库的主键自增。如果是 MySQL 等数据库，可不写。
@Data
@EqualsAndHashCode(callSuper = true)
@ToString(callSuper = true)
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ErpStockInItemDO extends BaseDO {

    /**
     * 入库项编号
     */
    @TableId
    private Long id;
    /**
     * 入库编号
     *
     * 关联 {@link ErpStockInDO#getId()}
     */
    private Long inId;
    /**
     * 仓库编号
     *
     * 关联 {@link ErpWarehouseDO#getId()}
     */
    private Long warehouseId;
    /**
     * 物料编号
     *
     * 关联 {@link ErpProductDO#getId()}
     */
    private Long productId;
    /**
     * 物料单位编号
     *
     * 冗余 {@link ErpProductDO#getUnitId()}
     */
    private Long productUnitId;
    /**
     * 物料单价
     */
    private BigDecimal productPrice;
    /**
     * 物料数量
     */
    private BigDecimal count;
    /**
     * 合计金额，单位：元
     */
    private BigDecimal totalPrice;
    /**
     * 备注
     */
    private String remark;
    /**
     * 批次号
     *
     * 为空时，审核入库按 IN{yyyyMMdd}-{项id} 自动生成
     */
    private String batchNo;
    /**
     * 生产日期
     */
    private java.time.LocalDate productionDate;
    /**
     * 到期日期
     *
     * 效期预警口径；FIFO 的次级排序键
     */
    private java.time.LocalDate expiryDate;

}