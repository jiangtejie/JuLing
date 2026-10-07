package com.lxjl.juling.module.erp.dal.dataobject.pricelist;

import com.lxjl.juling.framework.mybatis.core.dataobject.BaseDO;
import com.baomidou.mybatisplus.annotation.KeySequence;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.*;

import java.math.BigDecimal;

/**
 * ERP 价目表明细 DO（行）
 *
 * <p>一个物料一档价；**同一价目表里同一物料只能有一行**（否则取价结果取决于排序细节）。
 *
 * <p>原先还有「数量区间」做阶梯价，因填了也不生效已去掉，见 sql/local/68 的说明。
 *
 * @author 亚特
 */
@TableName("erp_price_list_item")
@KeySequence("erp_price_list_item_seq")
@Data
@EqualsAndHashCode(callSuper = true)
@ToString(callSuper = true)
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ErpPriceListItemDO extends BaseDO {

    /** 编号 */
    @TableId
    private Long id;
    /** 价目表编号 */
    private Long priceId;
    /** 物料编号 */
    private Long productId;
    /** 单价（**不含税**，权威值）；含税单价是计算值不落库 */
    private BigDecimal price;
    /** 税率(%) */
    private BigDecimal taxPercent;
    /** 备注 */
    private String remark;

}
