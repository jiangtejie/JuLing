package com.lxjl.juling.module.erp.dal.dataobject.purchase;

import com.lxjl.juling.framework.mybatis.core.dataobject.BaseDO;
import com.baomidou.mybatisplus.annotation.KeySequence;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.*;

import java.time.LocalDate;

/**
 * ERP 采购价目表 DO（头）
 *
 * <p>一套报价的容器：可以按供应商、带有效期、支持阶梯价。取价逻辑见
 * {@link com.lxjl.juling.module.erp.service.purchase.ErpPurchasePriceService#matchPrice}。
 *
 * <p>设计取舍见 sql/local/65_purchase_price.sql 的脚本头注释。
 *
 * @author 亚特
 */
@TableName("erp_purchase_price")
@KeySequence("erp_purchase_price_seq")
@Data
@EqualsAndHashCode(callSuper = true)
@ToString(callSuper = true)
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ErpPurchasePriceDO extends BaseDO {

    /**
     * 编号
     */
    @TableId
    private Long id;
    /**
     * 业务编码（编码规则统一发号，建档后只读）
     */
    private String code;
    /**
     * 价目表名称
     */
    private String name;
    /**
     * 供应商编号
     *
     * <p>**为空表示通用价目表**（不限供应商），取价时优先级低于供应商专项价目表。
     * 关联 {@link ErpSupplierDO#getId()}
     */
    private Long supplierId;
    /**
     * 是否默认价目表（同一层级内优先取它）
     */
    private Boolean isDefault;
    /**
     * 状态
     *
     * 枚举 {@link com.lxjl.juling.framework.common.enums.CommonStatusEnum}；仅启用中的价目表参与取价
     */
    private Integer status;
    /**
     * 生效日期（为空表示不限）
     */
    private LocalDate effectiveDate;
    /**
     * 失效日期（为空表示长期有效）
     */
    private LocalDate expiryDate;
    /**
     * 备注
     */
    private String remark;

}
