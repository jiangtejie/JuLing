package com.lxjl.juling.module.erp.dal.dataobject.pricelist;

import com.lxjl.juling.framework.mybatis.core.dataobject.BaseDO;
import com.baomidou.mybatisplus.annotation.KeySequence;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.*;

/**
 * ERP 价目表适用范围 DO
 *
 * <p>一张价目表可以适用 N 个对象：采购 = 供应商，配送 = 门店（用户明确要求「配送价格可以选择针对哪些门店生效」）。
 *
 * <p>{@link #partnerId} 为空表示**通用范围**（不限对象，取价时优先级最低）。
 *
 * <p>{@link #isDefault} 放在范围行而不是头上（对齐金蝶）：同一张价目表只对**部分**门店默认时粒度更准；
 * 放在头上只能整张表一刀切。
 *
 * @author 亚特
 */
@TableName("erp_price_list_scope")
@KeySequence("erp_price_list_scope_seq")
@Data
@EqualsAndHashCode(callSuper = true)
@ToString(callSuper = true)
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ErpPriceListScopeDO extends BaseDO {

    /** 编号 */
    @TableId
    private Long id;
    /** 价目表编号 */
    private Long priceId;
    /** 适用对象编号；**为空 = 通用范围**。采购 = erp_supplier.id，配送 = erp_customer.id（门店） */
    private Long partnerId;
    /** 该对象下的默认价目表 */
    private Boolean isDefault;
    /** 备注 */
    private String remark;

}
