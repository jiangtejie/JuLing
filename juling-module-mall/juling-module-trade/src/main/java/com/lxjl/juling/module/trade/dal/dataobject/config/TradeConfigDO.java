package com.lxjl.juling.module.trade.dal.dataobject.config;

import com.lxjl.juling.framework.mybatis.core.dataobject.BaseDO;
import com.baomidou.mybatisplus.annotation.KeySequence;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import com.baomidou.mybatisplus.extension.handlers.JacksonTypeHandler;
import lombok.*;

import java.util.List;

/**
 * 交易中心配置 DO
 *
 * @author 亚特
 */
@TableName(value = "trade_config", autoResultMap = true)
@KeySequence("trade_config_seq") // 用于 Oracle、PostgreSQL、Kingbase、DB2、H2 数据库的主键自增。如果是 MySQL 等数据库，可不写。
@Data
@EqualsAndHashCode(callSuper = true)
@ToString(callSuper = true)
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class TradeConfigDO extends BaseDO {

    /**
     * 自增主键
     */
    @TableId
    private Long id;

    // ========== 售后相关 ==========

    /**
     * 售后的退款理由
     */
    @TableField(typeHandler = JacksonTypeHandler.class)
    private List<String> afterSaleRefundReasons;
    /**
     * 售后的退货理由
     */
    @TableField(typeHandler = JacksonTypeHandler.class)
    private List<String> afterSaleReturnReasons;

    // ========== 配送相关 ==========

    /**
     * 是否启用全场包邮
     */
    private Boolean deliveryExpressFreeEnabled;
    /**
     * 全场包邮的最小金额，单位：分
     */
    private Integer deliveryExpressFreePrice;

}
