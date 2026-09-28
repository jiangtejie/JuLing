import type { PageParam, PageResult } from '@vben/request';

import { requestClient } from '#/api/request';

export namespace ErpStockBatchApi {
  /** 效期状态：EXPIRED 已过期 / WARNING 临期 / NORMAL 正常 / NONE 无有效期 */
  export type ExpiryStatus = 'EXPIRED' | 'NONE' | 'NORMAL' | 'WARNING';

  /** 可登记的状态：IN_TRANSIT 在途 / OCCUPIED 占用 / INSPECTING 待检（在仓只能由出入库产生） */
  export type StockState = 'IN_TRANSIT' | 'INSPECTING' | 'OCCUPIED';

  /** 批次库存（维度：仓库 × 物料 × 批次） */
  export interface StockBatch {
    id?: number; // 批次库存编号
    warehouseId: number; // 仓库编号
    warehouseName?: string; // 仓库名称
    productId: number; // 物料编号
    productName?: string; // 物料名称
    skuId?: number; // SKU 编号（预留，0 = 按物料记账）
    batchNo: string; // 批次号
    // 注意：后端把 java.time.LocalDate 序列化成数组（如 [2026,9,25]），
    // 展示前必须过 formatBatchDate（见 views/erp/stock/batch/data.ts）
    productionDate?: number[] | string; // 生产日期
    expiryDate?: number[] | string; // 到期日期
    inDate?: number[] | string; // 入库日期（FIFO 主排序键）
    count: number; // 在仓数量
    transitCount: number; // 在途数量
    occupiedCount: number; // 占用数量
    inspectingCount: number; // 待检数量
    availableCount: number; // 可用量 = 在仓 − 占用 + 在途
    unitCost: number; // 批次单位成本
    totalCost: number; // 批次在仓成本 = 在仓 × 单位成本
    sourceBizType?: number; // 来源业务类型（字典 erp_stock_record_biz_type）
    sourceBizNo?: string; // 来源单号
    sourceReversed?: number; // 来源是否已冲销：0 否 / 1 是
    expiryStatus?: ExpiryStatus; // 效期状态（后端按「今天」计算）
    expiryDays?: number; // 距到期天数（负数 = 已过期天数）
    remark?: string; // 备注
    createTime?: string; // 创建时间
  }

  /** 批次库存分页查询参数（后端 ErpStockBatchPageReqVO 支持的字段） */
  export interface StockBatchPageReqVO extends PageParam {
    warehouseId?: number; // 仓库编号
    productId?: number; // 物料编号
    batchNo?: string; // 批次号（模糊）
    sourceBizNo?: string; // 来源单号（模糊）
  }

  /** 临期 / 过期批次查询参数 */
  export interface StockBatchExpiryReqVO {
    warehouseId?: number; // 仓库编号
    productId?: number; // 物料编号
    warnDays?: number; // 临期预警天数，默认 30
    expiredOnly?: boolean; // true 只列已过期；false 列出已过期 + 临期
  }

  /** 状态数量登记参数 */
  export interface StockBatchStateReqVO {
    warehouseId: number; // 仓库编号
    productId: number; // 物料编号
    batchNo: string; // 批次号
    state: StockState; // 状态：IN_TRANSIT / OCCUPIED / INSPECTING
    delta: number; // 增量数量：正数增加、负数减少
    remark?: string; // 备注
  }
}

/** 查询批次库存分页（后端按 仓库 → 物料 → 入库日期 → 到期日期 → id 排序） */
export function getStockBatchPage(params: ErpStockBatchApi.StockBatchPageReqVO) {
  return requestClient.get<PageResult<ErpStockBatchApi.StockBatch>>(
    '/erp/stock-batch/page',
    { params },
  );
}

/** 获得临期 / 过期批次列表（后端只返回在仓 > 0 且有到期日期的批次，按到期日期升序） */
export function getStockBatchExpiryList(
  params: ErpStockBatchApi.StockBatchExpiryReqVO,
) {
  return requestClient.get<ErpStockBatchApi.StockBatch[]>(
    '/erp/stock-batch/expiry-list',
    { params },
  );
}

/** 登记批次状态数量（在途 / 占用 / 待检）；后端鉴权码是 erp:stock:update */
export function updateStockBatchState(
  data: ErpStockBatchApi.StockBatchStateReqVO,
) {
  return requestClient.post<ErpStockBatchApi.StockBatch>(
    '/erp/stock-batch/update-state',
    data,
  );
}
