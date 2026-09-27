package com.lxjl.juling.module.trade.dal.dataobject.order;

import com.lxjl.juling.framework.mybatis.core.dataobject.BaseDO;
import com.baomidou.mybatisplus.annotation.KeySequence;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import com.baomidou.mybatisplus.extension.handlers.JacksonTypeHandler;
import lombok.*;

import java.time.LocalDateTime;
import java.util.List;

/**
 * 交易订单 - 付款凭证 DO
 *
 * 线下收款：客户一次上传 = 一行，支持多图、多次上传与驳回重传；
 * 后台核验时给出 confirmedAmount（与实际到账不一致时以核定金额为准）。
 *
 * @author 亚特
 */
@TableName(value = "trade_order_payment_proof", autoResultMap = true)
@KeySequence("trade_order_payment_proof_seq") // 用于 Oracle、PostgreSQL、Kingbase、DB2、H2 数据库的主键自增
@Data
@EqualsAndHashCode(callSuper = true)
@ToString(callSuper = true)
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class TradeOrderPaymentProofDO extends BaseDO {

    /**
     * 编号
     */
    @TableId
    private Long id;
    /**
     * 交易订单编号
     *
     * 关联 {@link TradeOrderDO#getId()}
     */
    private Long orderId;
    /**
     * 付款凭证图片地址（多图）
     */
    @TableField(typeHandler = JacksonTypeHandler.class)
    private List<String> urls;
    /**
     * 客户申报的收款金额，单位：分
     */
    private Integer amount;
    /**
     * 后台核定的收款金额，单位：分；金额不符时与 {@link #amount} 不同
     */
    private Integer confirmedAmount;
    /**
     * 付款人姓名
     */
    private String payerName;
    /**
     * 收款渠道，对应字典 pay_channel_code 的线下值（offline_transfer / offline_cash / offline_wx / offline_alipay）
     */
    private String payChannelCode;
    /**
     * 客户转账时间
     */
    private LocalDateTime transferTime;
    /**
     * 客户备注
     */
    private String remark;
    /**
     * 状态
     *
     * 枚举 {@link com.lxjl.juling.module.trade.enums.order.TradeOrderPaymentProofStatusEnum}
     */
    private Integer status;
    /**
     * 核验人编号（后台管理员）
     */
    private Long auditUserId;
    /**
     * 核验时间
     */
    private LocalDateTime auditTime;
    /**
     * 核验意见（驳回时必填，例如「金额与截图不符」）
     */
    private String auditRemark;

}
