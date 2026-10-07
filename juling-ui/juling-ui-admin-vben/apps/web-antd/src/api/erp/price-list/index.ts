import type { PageParam, PageResult } from '@vben/request';

import { requestClient } from '#/api/request';

export namespace ErpPurchasePriceApi {
  /** 采购价目表（头） */
  export interface Price {
    id?: number;
    priceType?: 'DELIVERY' | 'PURCHASE'; // 价目表类型
    code?: string; // 业务编码（编码规则发号）
    name?: string; // 价目表名称
    scopes?: Scope[]; // 适用范围（采购=供应商 / 配送=门店）；为空或 partnerId 为空表示通用范围
    scopeSummary?: string; // 适用范围摘要（列表展示用）
    scopePartnerIds?: number[]; // 仅前端表单用：适用范围选中的对象编号
    scopeIsDefault?: boolean; // 仅前端表单用：整张表的「默认价目表」
    isDefault?: boolean; // 是否默认价目表
    priceIncludesTax?: boolean; // 报价口径：true 表示供应商报的是含税价
    pricerUserId?: number; // 定价员编号
    pricerUserName?: string; // 定价员名称
    status?: number; // 状态：0 启用 / 1 停用
    effectiveDate?: string; // 生效日期
    expiryDate?: string; // 失效日期
    remark?: string;
    itemCount?: number; // 明细行数
    createTime?: number;
    items?: Item[];
  }

  /** 适用范围行 */
  export interface Scope {
    id?: number;
    partnerId?: number; // 适用对象编号；为空表示通用范围
    partnerName?: string;
    isDefault?: boolean; // 该对象下的默认价目表
    remark?: string;
  }

  /** 价目表明细行 */
  export interface Item {
    id?: number;
    /** 行序号：仅前端使用，vxe 表格的 rowConfig.keyField 需要每行唯一（新增行还没有 id） */
    seq?: number;
    productId?: number; // 物料编号
    productCode?: string; // 物料编码
    productName?: string; // 物料名称
    spec?: string; // 规格型号（取物料的规格，仅展示）
    unitName?: string; // 计价单位（取物料的单位）
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

/** 价格变更留痕（供核算追溯） */
export interface PriceItemLog {
  changeType?: 'CREATE' | 'DELETE' | 'UPDATE';
  productId?: number;
  productCode?: string;
  productName?: string;
  beforePrice?: number;
  afterPrice?: number;
  beforeTaxPercent?: number;
  afterTaxPercent?: number;
  priceCode?: string;
  priceName?: string;
  createTime?: string;
  creator?: string;
}

/**
 * 查询价格变更历史
 *
 * 传 priceId 看某张价目表的历次改价；传 productId 看**某物料的历次改价**（核算主要用后者）。
 */
export function getPriceItemLog(params: { priceId?: number; productId?: number }) {
  return requestClient.get<PriceItemLog[]>('/erp/price-list/item-log', { params });
}

/** 查询采购价目表分页 */
export function getPurchasePricePage(params: PageParam) {
  return requestClient.get<PageResult<ErpPurchasePriceApi.Price>>(
    '/erp/price-list/page',
    { params },
  );
}

/** 查询采购价目表详情（含明细） */
export function getPurchasePrice(id: number) {
  return requestClient.get<ErpPurchasePriceApi.Price>(
    `/erp/price-list/get?id=${id}`,
  );
}

/** 新增采购价目表 */
export function createPurchasePrice(data: ErpPurchasePriceApi.Price) {
  return requestClient.post('/erp/price-list/create', data);
}

/** 修改采购价目表 */
export function updatePurchasePrice(data: ErpPurchasePriceApi.Price) {
  return requestClient.put('/erp/price-list/update', data);
}

/** 删除采购价目表 */
export function deletePurchasePrice(id: number) {
  return requestClient.delete(`/erp/price-list/delete?id=${id}`);
}

/** 批量删除采购价目表 */
export function deletePurchasePriceList(ids: number[]) {
  return requestClient.delete(
    `/erp/price-list/delete-list?ids=${ids.join(',')}`,
  );
}

/** 导出采购价目表 Excel */
export function exportPurchasePrice(params: any) {
  return requestClient.download('/erp/price-list/export-excel', { params });
}

/**
 * 取价：按「供应商 + 物料 + 数量 + 日期」拿适用单价与税率
 *
 * 采购订单在「选物料」时调它带出默认单价；价目表没命中时后端会兜底到物料主数据的采购价。
 */
export function matchPrice(params: {
  priceType: 'DELIVERY' | 'PURCHASE';
  partnerId?: number;
  productId: number;
  date?: string;
}) {
  return requestClient.get<ErpPurchasePriceApi.MatchResult | null>(
    '/erp/price-list/match',
    { params },
  );
}
