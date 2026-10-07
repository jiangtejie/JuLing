package com.lxjl.juling.module.erp.dal.dataobject.purchase;

import com.lxjl.juling.framework.mybatis.core.dataobject.BaseDO;
import com.baomidou.mybatisplus.annotation.KeySequence;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.*;

import java.math.BigDecimal;

/**
 * ERP 采购价目表明细 DO（行）
 *
 * <p>一个物料一档价；用 {@link #fromQty} / {@link #toQty} 表达数量区间做阶梯价。
 *
 * @author 亚特
 */
@TableName("erp_purchase_price_item")
@KeySequence("erp_purchase_price_item_seq")
@Data
@EqualsAndHashCode(callSuper = true)
@ToString(callSuper = true)
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ErpPurchasePriceItemDO extends BaseDO {

    /**
     * 编号
     */
    @TableId
    private Long id;
    /**
     * 价目表编号
     *
     * 关联 {@link ErpPurchasePriceDO#getId()}
     */
    private Long priceId;
    /**
     * 物料编号
     *
     * 关联 {@link com.lxjl.juling.module.erp.dal.dataobject.product.ErpProductDO#getId()}
     */
    private Long productId;
    /**
     * 数量区间起（含）；为空表示不限下界
     */
    private BigDecimal fromQty;
    /**
     * 数量区间止（不含）；为空表示不限上界
     */
    private BigDecimal toQty;
    /**
     * 单价（**不含税**，权威值）
     *
     * <p>含税单价 = price × (1 + taxPercent/100)，是计算值，不落库（避免两处漂移）。
     */
    private BigDecimal price;
    /**
     * 税率(%)，如 13
     */
    private BigDecimal taxPercent;
    /**
     * 备注
     */
    private String remark;

}
