package com.lxjl.juling.module.erp.service.stock;

import com.lxjl.juling.framework.common.exception.ErrorCode;

/**
 * 库存中心（批次/效期/FIFO）错误码
 *
 * 为什么不直接加到 module-erp 的 {@code ErrorCodeConstants}：该文件由并行的其它切片同时维护，
 * 本切片刻意把新增错误码收在自己的包里（码段 1_030_405_xxx，ERP 库存域 1_030_4xx 下的新子段），
 * 避免多会话同时改一个文件产生冲突。
 *
 * @author 亚特
 */
public interface ErpStockBatchErrorCodeConstants {

    // ========== 批次库存 1_030_405_000 ==========
    ErrorCode STOCK_BATCH_NOT_EXISTS = new ErrorCode(1_030_405_000, "批次库存不存在：仓库({}) 物料({}) 批次({})");
    ErrorCode STOCK_BATCH_COUNT_ILLEGAL = new ErrorCode(1_030_405_001, "批次数量必须大于 0，当前：{}");
    ErrorCode STOCK_BATCH_NOT_ENOUGH = new ErrorCode(1_030_405_002,
            "批次库存不足：物料({}) 仓库({}) 需要 {}，实际可出 {}；请先按批次入库（采购入库/其它入库审核）");
    ErrorCode STOCK_BATCH_CONCURRENT_MODIFY = new ErrorCode(1_030_405_003, "批次({})库存已被并发修改，请重试");
    ErrorCode STOCK_BATCH_REVERSE_FAIL_ISSUED = new ErrorCode(1_030_405_004,
            "批次({})已发生出库，剩余 {} 小于待冲销 {}，无法反审核入库单");
    ErrorCode STOCK_BATCH_STATE_ILLEGAL = new ErrorCode(1_030_405_005, "库存状态不合法：{}");
    ErrorCode STOCK_BATCH_STATE_NOT_ADJUSTABLE = new ErrorCode(1_030_405_006,
            "在仓数量不能通过状态登记修改（{}），请走出入库单（要同步 erp_stock 与库存流水）");

}
