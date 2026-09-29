package com.lxjl.juling.module.trade.dal.dataobject.order;

import com.lxjl.juling.framework.common.enums.TerminalEnum;
import com.lxjl.juling.framework.mybatis.core.dataobject.BaseDO;
import com.lxjl.juling.module.trade.dal.dataobject.delivery.DeliveryExpressDO;
import com.lxjl.juling.module.trade.enums.delivery.DeliveryTypeEnum;
import com.lxjl.juling.module.trade.enums.order.TradeOrderCancelTypeEnum;
import com.lxjl.juling.module.trade.enums.order.TradeOrderRefundStatusEnum;
import com.lxjl.juling.module.trade.enums.order.TradeOrderStatusEnum;
import com.lxjl.juling.module.trade.enums.order.TradeOrderTypeEnum;
import com.baomidou.mybatisplus.annotation.KeySequence;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.*;

import java.time.LocalDateTime;

/**
 * 交易订单 DO
 *
 * @author 亚特
 */
@TableName(value = "trade_order", autoResultMap = true)
@KeySequence("trade_order_seq") // 用于 Oracle、PostgreSQL、Kingbase、DB2、H2 数据库的主键自增。如果是 MySQL 等数据库，可不写。
@Data
@EqualsAndHashCode(callSuper = true)
@ToString(callSuper = true)
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class TradeOrderDO extends BaseDO {

    /**
     * 发货物流公司编号 - 空（无需发货）
     */
    public static final Long LOGISTICS_ID_NULL = 0L;

    // ========== 订单基本信息 ==========
    /**
     * 订单编号，主键自增
     */
    private Long id;
    /**
     * 订单流水号
     *
     * 例如说，1146347329394184195
     */
    private String no;
    /**
     * 订单类型
     *
     * 枚举 {@link TradeOrderTypeEnum}
     */
    private Integer type;
    /**
     * 订单来源
     *
     * 枚举 {@link TerminalEnum}
     */
    private Integer terminal;
    /**
     * 用户编号
     *
     * 关联 MemberUserDO 的 id 编号
     */
    private Long userId;
    /**
     * 用户 IP
     */
    private String userIp;
    /**
     * 用户备注
     */
    private String userRemark;
    /**
     * 订单状态
     *
     * 枚举 {@link TradeOrderStatusEnum}
     */
    private Integer status;
    /**
     * 购买的商品数量
     */
    private Integer productCount;
    /**
     * 订单完成时间
     */
    private LocalDateTime finishTime;
    /**
     * 订单取消时间
     */
    private LocalDateTime cancelTime;
    /**
     * 取消类型
     *
     * 枚举 {@link TradeOrderCancelTypeEnum}
     */
    private Integer cancelType;
    /**
     * 商家备注
     */
    private String remark;

    // ========== 价格 + 支付基本信息 ==========

    // 价格文档 - 淘宝：https://open.taobao.com/docV3.htm?docId=108471&docType=1
    // 价格文档 - 京东到家：https://openo2o.jddj.com/api/getApiDetail/182/4d1494c5e7ac4679bfdaaed950c5bc7f.htm
    // 价格文档 - 有赞：https://doc.youzanyun.com/detail/API/0/906

    /**
     * 支付订单编号
     *
     * 对接 pay-module-biz 支付服务的支付订单编号，即 PayOrderDO 的 id 编号
     */
    private Long payOrderId;
    /**
     * 是否已支付
     *
     * true - 已经支付过
     * false - 没有支付过
     */
    private Boolean payStatus;
    /**
     * 付款时间
     */
    private LocalDateTime payTime;
    /**
     * 支付渠道
     *
     * 对应 PayChannelEnum 枚举
     */
    private String payChannelCode;
    /**
     * 已确认收款金额，单位：分
     *
     * 线下收款：付款凭证核验通过后的累计金额；收满 {@link #payPrice} 即视为已收款
     */
    private Integer paidAmount;
    /**
     * 收款状态
     *
     * 枚举 {@link com.lxjl.juling.module.trade.enums.order.TradeOrderReceiveStatusEnum}；对应字典 trade_payment_proof_status
     */
    private Integer paymentProofStatus;

    // ========== 门店订货归属 + 供应链审核基本信息（门店订货链 S1） ==========
    /**
     * 下单门店所属部门编号（快照）
     *
     * 关联 system_dept.id；一店三面：组织面
     */
    private Long deptId;
    /**
     * 下单门店客户编号（快照）
     *
     * 关联 erp_customer.id；一店三面：经营面
     */
    private Long customerId;
    /**
     * 代理客户编号（快照）
     *
     * 代理账号切换门店下单时，记录代理客户；门店自身下单时为空
     */
    private Long agentCustomerId;
    /**
     * 结算模式快照
     *
     * 枚举 {@link com.lxjl.juling.module.trade.enums.order.TradeSettlementModeEnum}
     */
    private String settlementMode;
    /**
     * 店型快照：DIRECT 直营 / FRANCHISE 加盟
     *
     * 门店订货链：加盟店需审核（auditStatus 必须 20）才进订单工作台；直营店免审。
     * 快照后可避免订单列表/工作台查询跨模块 join erp_customer。
     */
    private String storeType;
    /**
     * 审核状态
     *
     * 枚举 {@link com.lxjl.juling.module.trade.enums.order.TradeOrderAuditStatusEnum}
     */
    private Integer auditStatus;
    /**
     * 审核人编号（审核结束时写入）
     */
    private Long auditUserId;
    /**
     * 审核时间
     */
    private LocalDateTime auditTime;
    /**
     * 审核意见（驳回原因等）
     */
    private String auditRemark;
    /**
     * BPM 审批流程实例编号
     */
    private String processInstanceId;

    /**
     * 商品原价，单位：分
     *
     * totalPrice = {@link TradeOrderItemDO#getPrice()} * {@link TradeOrderItemDO#getCount()} 求和
     *
     * 对应 taobao 的 trade.total_fee 字段
     */
    private Integer totalPrice;
    /**
     * 优惠金额，单位：分
     *
     * 对应 taobao 的 order.discount_fee 字段
     */
    private Integer discountPrice;
    /**
     * 运费金额，单位：分
     */
    private Integer deliveryPrice;
    /**
     * 订单调价，单位：分
     *
     * 正数，加价；负数，减价
     */
    private Integer adjustPrice;
    /**
     * 应付金额（总），单位：分
     *
     * = {@link #totalPrice}
     * - {@link #discountPrice}
     * + {@link #deliveryPrice}
     * + {@link #adjustPrice}
     */
    private Integer payPrice;

    // ========== 收件 + 物流基本信息 ==========
    /**
     * 配送方式
     *
     * 枚举 {@link DeliveryTypeEnum}
     */
    private Integer deliveryType;
    /**
     * 发货物流公司编号
     *
     * 如果无需发货，则 logisticsId 设置为 0。原因是，不想再添加额外字段
     *
     * 关联 {@link DeliveryExpressDO#getId()}
     */
    private Long logisticsId;
    /**
     * 发货物流单号
     *
     * 如果无需发货，则 logisticsNo 设置 ""。原因是，不想再添加额外字段
     */
    private String logisticsNo;
    /**
     * 发货时间
     */
    private LocalDateTime deliveryTime;

    /**
     * 收货时间
     */
    private LocalDateTime receiveTime;
    /**
     * 收货状态（订单维度聚合）
     *
     * 枚举 {@link com.lxjl.juling.module.trade.enums.order.TradeOrderReceiptStatusEnum}：
     * 0 未收货 / 10 部分收货 / 20 已收货。由门店在 H5 确认收货（trade_order_receipt）后聚合回写。
     */
    private Integer receiptStatus;
    /**
     * 收件人名称
     */
    private String receiverName;
    /**
     * 收件人手机
     */
    private String receiverMobile;
    /**
     * 收件人地区编号
     */
    private Integer receiverAreaId;
    /**
     * 收件人详细地址
     */
    private String receiverDetailAddress;

    // ========== 售后基本信息 ==========
    /**
     * 售后状态
     *
     * 枚举 {@link TradeOrderRefundStatusEnum}
     */
    private Integer refundStatus;
    /**
     * 退款金额，单位：分
     *
     * 注意，退款并不会影响 {@link #payPrice} 实际支付金额
     * 也就说，一个订单最终产生多少金额的收入 = payPrice - refundPrice
     */
    private Integer refundPrice;

}
