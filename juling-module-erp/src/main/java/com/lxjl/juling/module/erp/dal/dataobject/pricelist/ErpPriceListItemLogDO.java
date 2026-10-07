package com.lxjl.juling.module.erp.dal.dataobject.pricelist;

import com.lxjl.juling.framework.mybatis.core.dataobject.BaseDO;
import com.baomidou.mybatisplus.annotation.KeySequence;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.*;

import java.math.BigDecimal;

/**
 * 价目表价格变更留痕 DO
 *
 * <p>供核算追溯「某物料在某价目表下的价格变动历史」（见 sql/local/74）。
 *
 * <p>为什么不复用单据平台的 bill_log：它记的是**状态流转**（beforeStatus → afterStatus），
 * 记不下「单价从 10 改成 12」—— 两者是不同维度的事。
 *
 * <p>口径：**只对价格行留痕**。表头字段（名称/备注/有效期）的变更对核算没有价值，
 * 做全字段 diff 是白花钱。操作人与时间复用 BaseDO 的 creator / createTime。
 *
 * @author 亚特
 */
@TableName("erp_price_list_item_log")
@KeySequence("erp_price_list_item_log_seq")
@Data
@EqualsAndHashCode(callSuper = true)
@ToString(callSuper = true)
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ErpPriceListItemLogDO extends BaseDO {

    /** 编号 */
    @TableId
    private Long id;
    /** 价目表编号 */
    private Long priceId;
    /** 明细行编号（更新/删除时有） */
    private Long itemId;
    /** 物料编号 */
    private Long productId;
    /** 变更类型：CREATE 新增行 / UPDATE 价格或税率变化 / DELETE 删行 */
    private String changeType;
    /** 变更前单价（不含税）；新增行为空 */
    private BigDecimal beforePrice;
    /** 变更后单价（不含税）；删除行为空 */
    private BigDecimal afterPrice;
    /** 变更前税率(%) */
    private BigDecimal beforeTaxPercent;
    /** 变更后税率(%) */
    private BigDecimal afterTaxPercent;
    /** 冗余价目表编码：价目表改名/删除后历史仍可读 */
    private String priceCode;
    /** 冗余价目表名称，理由同上 */
    private String priceName;
    /** 备注 */
    private String remark;

}
