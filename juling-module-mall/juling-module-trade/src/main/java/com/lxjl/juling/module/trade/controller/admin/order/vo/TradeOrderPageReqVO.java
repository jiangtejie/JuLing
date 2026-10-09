package com.lxjl.juling.module.trade.controller.admin.order.vo;

import com.lxjl.juling.framework.common.enums.TerminalEnum;
import com.lxjl.juling.framework.common.pojo.PageParam;
import com.lxjl.juling.framework.common.validation.InEnum;
import com.lxjl.juling.framework.common.validation.Mobile;
import com.lxjl.juling.module.trade.enums.order.TradeOrderStatusEnum;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;
import org.springframework.format.annotation.DateTimeFormat;

import java.time.LocalDateTime;
import java.util.List;

import static com.lxjl.juling.framework.common.util.date.DateUtils.FORMAT_YEAR_MONTH_DAY_HOUR_MINUTE_SECOND;

@Schema(description = "管理后台 - 交易订单的分页 Request VO")
@Data
public class TradeOrderPageReqVO extends PageParam {

    @Schema(description = "订单号", example = "88888888")
    private String no;

    @Schema(description = "用户编号", example = "1024")
    private Long userId;

    @Schema(description = "用户昵称", example = "小王")
    private String userNickname;

    @Schema(description = "用户手机号", example = "小王")
    @Mobile
    private String userMobile;

    @Schema(description = "配送方式", example = "1")
    private Integer deliveryType;

    @Schema(description = "发货物流公司编号", example = "1")
    private Long logisticsId;

    @Schema(description = "订单类型", example = "1")
    private Integer type;

    @Schema(description = "订单状态", example = "1")
    @InEnum(value = TradeOrderStatusEnum.class, message = "订单状态必须是 {value}")
    private Integer status;

    @Schema(description = "支付渠道", example = "wx_lite")
    private String payChannelCode;

    @Schema(description = "收款状态（TradeOrderReceiveStatusEnum）：0 未上传凭证、1 待核验、2 已驳回、3 部分收款、4 已收齐", example = "1")
    private Integer paymentProofStatus;

    @Schema(description = "审核状态（TradeOrderAuditStatusEnum）：0 待提交、10 审核中、20 已通过、30 已驳回", example = "10")
    private Integer auditStatus;

    @Schema(description = "下单门店客户编号", example = "1")
    private Long customerId;

    @Schema(description = "下单门店所属部门编号", example = "134")
    private Long deptId;

    @Schema(description = "创建时间")
    @DateTimeFormat(pattern = FORMAT_YEAR_MONTH_DAY_HOUR_MINUTE_SECOND)
    private LocalDateTime[] createTime;

    @Schema(description = "订单来源", example = "10")
    @InEnum(value = TerminalEnum.class, message = "订单来源 {value}")
    private Integer terminal;

}
