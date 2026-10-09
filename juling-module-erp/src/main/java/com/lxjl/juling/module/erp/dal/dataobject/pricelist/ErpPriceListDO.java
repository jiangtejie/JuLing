package com.lxjl.juling.module.erp.dal.dataobject.pricelist;

import com.lxjl.juling.framework.mybatis.core.dataobject.BaseDO;
import com.baomidou.mybatisplus.annotation.KeySequence;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.*;

import java.time.LocalDate;

/**
 * ERP 价目表 DO（头）
 *
 * <p>采购价目表与配送价目表**共用这一张表**，靠 {@link #priceType} 区分（见 sql/local/69 的评估说明）：
 * 两者除了「适用对象是谁」之外完全同构，取价算法也完全一致，分成两张表只会产生一份要同步维护的重复逻辑。
 *
 * <p>适用对象在 {@link ErpPriceListScopeDO}（一张价目表可适用 N 个对象），明细在 {@link ErpPriceListItemDO}。
 *
 * @author 亚特
 */
@TableName("erp_price_list")
@KeySequence("erp_price_list_seq")
@Data
@EqualsAndHashCode(callSuper = true)
@ToString(callSuper = true)
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ErpPriceListDO extends BaseDO {

    /** 编号 */
    @TableId
    private Long id;
    /** 价目表类型 */
    private String priceType;
    /** 业务编码（编码规则发号：采购 CJJM、配送 PSJM） */
    private String code;
    /** 价目表名称 */
    private String name;
    /**
     * 报价口径：true 表示报的是**含税价**
     *
     * <p>只影响录入方向 —— 明细行上的 price 恒为不含税（权威、无歧义）。
     */
    private Boolean priceIncludesTax;
    /** 定价员编号（与 BaseDO.creator 区分：责任人不等于录入人） */
    private Long pricerUserId;
    /** 状态 {@link com.lxjl.juling.framework.common.enums.CommonStatusEnum}；仅启用中的参与取价 */
    private Integer status;
    /** 生效日期（为空表示不限） */
    private LocalDate effectiveDate;
    /** 失效日期（为空表示长期有效） */
    private LocalDate expiryDate;
    /** 备注 */
    private String remark;

}
