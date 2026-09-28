package com.lxjl.juling.module.trade.enums;

import com.lxjl.juling.framework.common.exception.ErrorCode;

/**
 * Trade 错误码枚举类
 * trade 系统，使用 1-011-000-000 段
 *
 * @author 亚特
 * @since 2022-08-26
 */
public interface ErrorCodeConstants {

    // ========== Order 模块 1-011-000-000 ==========
    ErrorCode ORDER_ITEM_NOT_FOUND = new ErrorCode(1_011_000_010, "交易订单项不存在");
    ErrorCode ORDER_NOT_FOUND = new ErrorCode(1_011_000_011, "交易订单不存在");
    ErrorCode ORDER_ITEM_UPDATE_AFTER_SALE_STATUS_FAIL = new ErrorCode(1_011_000_012, "交易订单项更新售后状态失败，请重试");
    ErrorCode ORDER_UPDATE_PAID_STATUS_NOT_UNPAID = new ErrorCode(1_011_000_013, "交易订单更新支付状态失败，订单不是【未支付】状态");
    ErrorCode ORDER_UPDATE_PAID_FAIL_PAY_ORDER_ID_ERROR = new ErrorCode(1_011_000_014, "交易订单更新支付状态失败，支付单编号不匹配");
    ErrorCode ORDER_UPDATE_PAID_FAIL_PAY_ORDER_STATUS_NOT_SUCCESS = new ErrorCode(1_011_000_015, "交易订单更新支付状态失败，支付单状态不是【支付成功】状态");
    ErrorCode ORDER_UPDATE_PAID_FAIL_PAY_PRICE_NOT_MATCH = new ErrorCode(1_011_000_016, "交易订单更新支付状态失败，支付单金额不匹配");
    ErrorCode ORDER_DELIVERY_FAIL_STATUS_NOT_UNDELIVERED = new ErrorCode(1_011_000_017, "交易订单发货失败，订单不是【待发货】状态");
    ErrorCode ORDER_RECEIVE_FAIL_STATUS_NOT_DELIVERED = new ErrorCode(1_011_000_018, "交易订单收货失败，订单不是【待收货】状态");
    ErrorCode ORDER_COMMENT_FAIL_STATUS_NOT_COMPLETED = new ErrorCode(1_011_000_019, "创建交易订单项的评价失败，订单不是【已完成】状态");
    ErrorCode ORDER_COMMENT_STATUS_NOT_FALSE = new ErrorCode(1_011_000_020, "创建交易订单项的评价失败，订单已评价");
    ErrorCode ORDER_DELIVERY_FAIL_REFUND_STATUS_NOT_NONE = new ErrorCode(1_011_000_021, "交易订单发货失败，订单已退款或部分退款");
    ErrorCode ORDER_DELIVERY_FAIL_COMBINATION_RECORD_STATUS_NOT_SUCCESS = new ErrorCode(1_011_000_022, "交易订单发货失败，拼团未成功");
    ErrorCode ORDER_DELIVERY_FAIL_BARGAIN_RECORD_STATUS_NOT_SUCCESS = new ErrorCode(1_011_000_023, "交易订单发货失败，砍价未成功");
    ErrorCode ORDER_DELIVERY_FAIL_DELIVERY_TYPE_NOT_EXPRESS = new ErrorCode(1_011_000_024, "交易订单发货失败，发货类型不是快递");
    ErrorCode ORDER_CANCEL_FAIL_STATUS_NOT_UNPAID = new ErrorCode(1_011_000_025, "交易订单取消失败，订单不是【待支付】状态");
    ErrorCode ORDER_UPDATE_PRICE_FAIL_PAID = new ErrorCode(1_011_000_026, "支付订单调价失败，原因：支付订单已付款,不能调价");
    ErrorCode ORDER_UPDATE_PRICE_FAIL_ALREADY = new ErrorCode(1_011_000_027, "支付订单调价失败，原因：已经修改过价格");
    ErrorCode ORDER_UPDATE_PRICE_FAIL_PRICE_ERROR = new ErrorCode(1_011_000_028, "支付订单调价失败，原因：调整后支付价格不能小于 0.01 元");
    ErrorCode ORDER_DELETE_FAIL_STATUS_NOT_CANCEL = new ErrorCode(1_011_000_029, "交易订单删除失败，订单不是【已取消】状态");
    ErrorCode ORDER_UPDATE_ADDRESS_FAIL_STATUS_NOT_DELIVERED = new ErrorCode(1_011_000_031, "交易订单修改收货地址失败，原因：订单不是【待发货】状态");
    ErrorCode ORDER_CREATE_FAIL_EXIST_UNPAID = new ErrorCode(1_011_000_032, "交易订单创建失败，原因：存在未付款订单");
    ErrorCode ORDER_CANCEL_PAID_FAIL = new ErrorCode(1_011_000_033, "交易订单取消支付失败，原因：订单不是【{}】状态");
    ErrorCode ORDER_UPDATE_PAID_ORDER_REFUNDED_FAIL_REFUND_NOT_FOUND = new ErrorCode(1_011_000_034, "交易订单更新支付订单退款状态失败，原因：退款单不存在");
    ErrorCode ORDER_UPDATE_PAID_ORDER_REFUNDED_FAIL_REFUND_STATUS_NOT_SUCCESS = new ErrorCode(1_011_000_035, "交易订单更新支付订单退款状态失败，原因：退款单状态不是【退款成功】");
    ErrorCode ORDER_CREATE_FAIL_INSUFFICIENT_USER_POINTS = new ErrorCode(1_011_000_038, "交易订单创建失败，原因：用户积分不足");
    ErrorCode ORDER_CREATE_FAIL_RECEIVER_INFO_INCOMPLETE = new ErrorCode(1_011_000_040, "交易订单创建失败，原因：收货信息不完整，请填写收货人、联系电话和收货地址");
    // ========== 门店订货链 S1：归属与审核 ==========
    ErrorCode ORDER_CREATE_FAIL_STORE_NOT_BOUND = new ErrorCode(1_011_000_041, "交易订单创建失败，原因：订货账号未绑定门店，请联系管理员在【会员管理】中配置");
    ErrorCode ORDER_CREATE_FAIL_STORE_NOT_BELONG = new ErrorCode(1_011_000_042, "交易订单创建失败，原因：所选门店不属于当前订货账号");
    ErrorCode ORDER_CREATE_FAIL_STORE_NOT_EXISTS = new ErrorCode(1_011_000_043, "交易订单创建失败，原因：门店不存在或已停用");
    ErrorCode ORDER_AUDIT_FAIL_STATUS = new ErrorCode(1_011_000_044, "交易订单提交审核失败，原因：订单不是【待发货】或【已驳回】状态");
    ErrorCode ORDER_DELIVERY_FAIL_AUDIT_NOT_APPROVE = new ErrorCode(1_011_000_045, "交易订单发货失败，原因：门店要货未通过审核");
    ErrorCode ORDER_AUDIT_UPDATE_FAIL_NOT_PROCESS = new ErrorCode(1_011_000_046, "交易订单更新审核结果失败，原因：订单不处于【审核中】状态");

    // ========== After Sale 模块 1-011-000-100 ==========
    ErrorCode AFTER_SALE_NOT_FOUND = new ErrorCode(1_011_000_100, "售后单不存在");
    ErrorCode AFTER_SALE_CREATE_FAIL_REFUND_PRICE_ERROR = new ErrorCode(1_011_000_101, "申请退款金额错误");
    ErrorCode AFTER_SALE_CREATE_FAIL_ORDER_STATUS_CANCELED = new ErrorCode(1_011_000_102, "订单已关闭，无法申请售后");
    ErrorCode AFTER_SALE_CREATE_FAIL_ORDER_STATUS_NO_PAID = new ErrorCode(1_011_000_103, "订单未支付，无法申请售后");
    ErrorCode AFTER_SALE_CREATE_FAIL_ORDER_STATUS_NO_DELIVERED = new ErrorCode(1_011_000_104, "订单未发货，无法申请【退货退款】售后");
    ErrorCode AFTER_SALE_CREATE_FAIL_ORDER_ITEM_APPLIED = new ErrorCode(1_011_000_105, "订单项已申请售后，无法重复申请");
    ErrorCode AFTER_SALE_AUDIT_FAIL_STATUS_NOT_APPLY = new ErrorCode(1_011_000_106, "审批失败，售后状态不处于审批中");
    ErrorCode AFTER_SALE_UPDATE_STATUS_FAIL = new ErrorCode(1_011_000_107, "操作售后单失败，请刷新后重试");
    ErrorCode AFTER_SALE_DELIVERY_FAIL_STATUS_NOT_SELLER_AGREE = new ErrorCode(1_011_000_108, "退货失败，售后单状态不处于【待买家退货】");
    ErrorCode AFTER_SALE_CONFIRM_FAIL_STATUS_NOT_BUYER_DELIVERY = new ErrorCode(1_011_000_109, "确认收货失败，售后单状态不处于【待确认收货】");
    ErrorCode AFTER_SALE_REFUND_FAIL_STATUS_NOT_WAIT_REFUND = new ErrorCode(1_011_000_110, "退款失败，售后单状态不是【待退款】");
    ErrorCode AFTER_SALE_REFUND_FAIL_REFUND_NOT_FOUND = new ErrorCode(1_011_000_111, "退款失败，退款单不存在");
    ErrorCode AFTER_SALE_REFUND_FAIL_REFUND_NOT_SUCCESS_OR_FAILURE = new ErrorCode(1_011_000_112, "退款失败，退款单未退款");
    ErrorCode AFTER_SALE_REFUND_FAIL_REFUND_PRICE_NOT_MATCH = new ErrorCode(1_011_000_113, "退款失败，退款金额不匹配");
    ErrorCode AFTER_SALE_REFUND_FAIL_REFUND_ORDER_ID_ERROR = new ErrorCode(1_011_000_114, "退款失败，退款单不匹配");
    ErrorCode AFTER_SALE_CANCEL_FAIL_STATUS_NOT_APPLY_OR_AGREE_OR_BUYER_DELIVERY =
            new ErrorCode(1_011_000_115, "取消售后单失败，售后单状态不是【待审核】或【卖家同意】或【商家待收货】");
    ErrorCode AFTER_SALE_CREATE_FAIL_ORDER_STATUS_COMBINATION_IN_PROGRESS = new ErrorCode(1_011_000_116, "订单拼团中，无法申请售后");

    // ========== Cart 模块 1-011-002-000 ==========
    ErrorCode CARD_ITEM_NOT_FOUND = new ErrorCode(1_011_002_000, "购物车项不存在");

    // ========== Price 相关 1-011-003-000 ============
    ErrorCode PRICE_CALCULATE_PAY_PRICE_ILLEGAL = new ErrorCode(1_011_003_000, "支付价格计算异常，原因：价格小于等于 0");
    ErrorCode PRICE_CALCULATE_DELIVERY_PRICE_TEMPLATE_NOT_FOUND = new ErrorCode(1_011_003_001, "计算快递运费异常，找不到对应的运费模板");
    ErrorCode PRICE_CALCULATE_COUPON_NOT_MATCH_NORMAL_ORDER = new ErrorCode(1_011_003_002, "参与秒杀、拼团、砍价的营销商品，无法使用优惠劵");
    ErrorCode PRICE_CALCULATE_SECKILL_TOTAL_LIMIT_COUNT = new ErrorCode(1_011_003_003, "参与秒杀的商品，超过了秒杀总限购数量");
    ErrorCode PRICE_CALCULATE_POINT_TOTAL_LIMIT_COUNT = new ErrorCode(1_011_003_004, "参与积分活动的商品，超过了积分活动商品总限购数量");
    ErrorCode PRICE_CALCULATE_DELIVERY_PRICE_TYPE_ILLEGAL = new ErrorCode(1_011_003_005, "计算快递运费异常，配送方式不匹配");
    ErrorCode PRICE_CALCULATE_COUPON_CAN_NOT_USE = new ErrorCode(1_011_003_006, "该优惠劵无法使用，原因：{}」");

    // ========== 物流 Express 模块 1-011-004-000 ==========
    ErrorCode EXPRESS_NOT_EXISTS = new ErrorCode(1_011_004_000, "快递公司不存在");
    ErrorCode EXPRESS_CODE_DUPLICATE = new ErrorCode(1_011_004_001, "已经存在该编码的快递公司");
    ErrorCode EXPRESS_CLIENT_NOT_PROVIDE = new ErrorCode(1_011_004_002, "需要接入快递服务商，比如【快递100】");
    ErrorCode EXPRESS_STATUS_NOT_ENABLE = new ErrorCode(1_011_004_003, "快递公司未启用");

    ErrorCode EXPRESS_API_QUERY_ERROR = new ErrorCode(1_011_004_101, "快递查询接口异常");
    ErrorCode EXPRESS_API_QUERY_FAILED = new ErrorCode(1_011_004_102, "快递查询返回失败，原因：{}");

    // ========== 物流 Template 模块 1-011-005-000 ==========
    ErrorCode EXPRESS_TEMPLATE_NAME_DUPLICATE = new ErrorCode(1_011_005_000, "已经存在该运费模板名");
    ErrorCode EXPRESS_TEMPLATE_NOT_EXISTS = new ErrorCode(1_011_005_001, "运费模板不存在");


    // ========== Order 付款凭证（线下收款）1-011-000-000 ==========
    // 注意：付款凭证的错误码从 040 起，避免与上面订单的 020-039 撞号
    ErrorCode ORDER_PAYMENT_PROOF_NOT_EXISTS = new ErrorCode(1_011_000_040, "交易订单付款凭证不存在");
    ErrorCode ORDER_PAYMENT_PROOF_STATUS_NOT_PENDING = new ErrorCode(1_011_000_041, "付款凭证不是【待核验】状态，无法重复核验");
    ErrorCode ORDER_PAYMENT_PROOF_NOT_BELONG_TO_USER = new ErrorCode(1_011_000_042, "付款凭证不属于当前用户");
    ErrorCode ORDER_PAYMENT_PROOF_ORDER_ALREADY_PAID = new ErrorCode(1_011_000_043, "订单已收齐，无法再上传付款凭证");
    ErrorCode ORDER_CANCEL_FAIL_HAS_PENDING_PAYMENT_PROOF = new ErrorCode(1_011_000_044, "订单已提交付款凭证，核验中暂不能取消，如需取消请联系客服");

}
