import type { PageParam, PageResult } from '@vben/request';

import { requestClient } from '#/api/request';

export namespace ErpPurchasePriceApi {
  /** 采购价目表（头） */
  export interface Price {
    id?: number;
    code?: string; // 业务编码（编码规则发号）
    name?: string; // 价目表名称
    supplierId?: number; // 供应商编号；为空表示通用价目表
    supplierName?: string; // 供应商名称（通用价目表为空）
    isDefault?: boolean; // 是否默认价目表
    status?: number; // 状态：0 启用 / 1 停用
    effectiveDate?: string; // 生效日期
    expiryDate?: string; // 失效日期
    remark?: string;
    itemCount?: number; // 明细行数
    createTime?: number;
    items?: Item[];
  }

  /** 价目表明细行 */
  export interface Item {
    id?: number;
    productId?: number; // 物料编号
    productCode?: string; // 物料编码
    productName?: string; // 物料名称
    unitName?: string; // 计价单位（取物料的单位）
    fromQty?: number; // 数量区间起（含）
    toQty?: number; // 数量区间止（不含）
    price?: number; // 单价（不含税，权威值）
    taxPrice?: number; // 含税单价（后端算好的展示值）
    taxPercent?: number; // 税率(%)
    remark?: string;
  }

  /** 取价结果 */
  export interface MatchResult {
    priceId?: number;
    priceCode?: string;
    priceName?: string;
    itemId?: number;
    price?: number; // 单价（不含税）
    taxPercent?: number; // 税率(%)
    source?: 'PRICE_LIST' | 'PRODUCT'; // 价目表命中 / 物料主数据兜底
  }
}

/** 查询采购价目表分页 */
export function getPurchasePricePage(params: PageParam) {
  return requestClient.get<PageResult<ErpPurchasePriceApi.Price>>(
    '/erp/purchase-price/page',
    { params },
  );
}

/** 查询采购价目表详情（含明细） */
export function getPurchasePrice(id: number) {
  return requestClient.get<ErpPurchasePriceApi.Price>(
    `/erp/purchase-price/get?id=${id}`,
  );
}

/** 新增采购价目表 */
export function createPurchasePrice(data: ErpPurchasePriceApi.Price) {
  return requestClient.post('/erp/purchase-price/create', data);
}

/** 修改采购价目表 */
export function updatePurchasePrice(data: ErpPurchasePriceApi.Price) {
  return requestClient.put('/erp/purchase-price/update', data);
}

/** 删除采购价目表 */
export function deletePurchasePrice(id: number) {
  return requestClient.delete(`/erp/purchase-price/delete?id=${id}`);
}

/** 批量删除采购价目表 */
export function deletePurchasePriceList(ids: number[]) {
  return requestClient.delete(
    `/erp/purchase-price/delete-list?ids=${ids.join(',')}`,
  );
}

/** 导出采购价目表 Excel */
export function exportPurchasePrice(params: any) {
  return requestClient.download('/erp/purchase-price/export-excel', { params });
}

/**
 * 取价：按「供应商 + 物料 + 数量 + 日期」拿适用单价与税率
 *
 * 采购订单在「选物料」时调它带出默认单价；价目表没命中时后端会兜底到物料主数据的采购价。
 */
export function matchPurchasePrice(params: {
  supplierId?: number;
  productId: number;
  quantity?: number;
  date?: string;
}) {
  return requestClient.get<ErpPurchasePriceApi.MatchResult | null>(
    '/erp/purchase-price/match',
    { params },
  );
}
