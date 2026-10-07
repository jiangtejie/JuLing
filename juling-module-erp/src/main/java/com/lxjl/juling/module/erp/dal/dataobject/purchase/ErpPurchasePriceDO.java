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
 * <p>一套报价的容器：可以按供应商、带有效期。取价逻辑见
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
     * 报价口径：true 表示供应商报的是**含税价**
     *
     * <p>**只影响录入方向** —— 明细行上的 {@code price} 恒为不含税（权威、无歧义），
     * 这个标记记录的是「报价方当时怎么说的」，界面据此决定让用户录含税还是不含税。
     */
    private Boolean priceIncludesTax;
    /**
     * 定价员编号
     *
     * <p>与 BaseDO 的 creator 区分：常见是采购经理定价、文员录入，**责任人不等于录入人**。
     * 关联 {@link com.lxjl.juling.module.system.dal.dataobject.user.AdminUserDO#getId()}
     */
    private Long pricerUserId;
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
