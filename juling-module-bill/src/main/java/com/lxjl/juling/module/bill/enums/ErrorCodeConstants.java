package com.lxjl.juling.module.bill.enums;

import com.lxjl.juling.framework.common.exception.ErrorCode;

/**
 * 单据平台错误码（1-100-000-000 段）
 *
 * @author 亚特
 */
public interface ErrorCodeConstants {

    ErrorCode BILL_TYPE_NOT_EXISTS = new ErrorCode(1_100_000_001, "单据类型({})不存在，请先在 bill_type 注册");
    ErrorCode BILL_STATUS_TRANSFER_ILLEGAL = new ErrorCode(1_100_000_002, "单据状态不允许从【{}】变更为【{}】");
    ErrorCode BILL_RELATION_DUPLICATE = new ErrorCode(1_100_000_003, "单据已下推过，不能重复下推");
    ErrorCode BILL_EXT_DUPLICATE = new ErrorCode(1_100_000_004, "单据扩展字段({})写入冲突，请重试");

}
