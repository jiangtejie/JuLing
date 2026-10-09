package com.lxjl.juling.module.erp.dal.dataobject.product;

import com.lxjl.juling.framework.mybatis.core.dataobject.BaseDO;
import com.baomidou.mybatisplus.annotation.KeySequence;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.*;

import java.math.BigDecimal;

/**
 * ERP 物料 DO
 *
 * @author 亚特
 */
@TableName("erp_product")
@KeySequence("erp_product_seq") // 用于 Oracle、PostgreSQL、Kingbase、DB2、H2 数据库的主键自增。如果是 MySQL 等数据库，可不写。
@Data
@EqualsAndHashCode(callSuper = true)
@ToString(callSuper = true)
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ErpProductDO extends BaseDO {

    /**
     * 物料编号
     */
    @TableId
    private Long id;
    /**
     * 物料编码（编码规则统一发号，建档后只读）
     */
    private String code;
    /**
     * 物料名称
     */
    private String name;
    /**
     * 物料条码
     */
    private String barCode;
    /**
     * 物料分类编号
     *
     * 关联 {@link ErpProductCategoryDO#getId()}
     */
    private Long categoryId;
    /**
     * 单位编号
     *
     * 关联 {@link ErpProductUnitDO#getId()}
     */
    private Long unitId;
    /**
     * 物料状态
     *
     * 枚举 {@link com.lxjl.juling.framework.common.enums.CommonStatusEnum}
     */
    private Integer status;
    /**
     * 物料规格
     */
    private String standard;
    /**
     * 物料备注
     */
    private String remark;
    /**
     * 保质期天数
     */
    private Integer expiryDay;
    /**
     * 基础重量（kg）
     */
    private BigDecimal weight;
    /**
     * 采购价格，单位：元
     */
    private BigDecimal purchasePrice;
    /**
     * 销售价格，单位：元
     */
    private BigDecimal salePrice;
    /**
     * 最低价格，单位：元
     */
    private BigDecimal minPrice;

    // ========== 分料属性（门店订货链：订单工作台） ==========

    /**
     * 是否允许统配
     *
     * 统配 = 中心库配送出库 → 门店收货；工作台只能选「统配」下推配送出库单。
     */
    private Boolean allowCentral;
    /**
     * 是否允许直拨
     *
     * 直拨（直配）= 中心库向供应商下采购订单，供应商直送门店（不入中心库）；
     * 工作台只能选「直拨」下推采购订单。
     */
    private Boolean allowDirect;

}