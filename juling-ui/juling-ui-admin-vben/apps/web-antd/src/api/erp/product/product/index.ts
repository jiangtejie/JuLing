import type { PageParam, PageResult } from '@vben/request';

import { requestClient } from '#/api/request';

export namespace ErpProductApi {
  /** 物料信息 */
  export interface Product {
    id?: number; // 物料编号
    name: string; // 物料名称
    barCode: string; // 物料条码
    categoryId: number; // 物料类型编号
    unitId: number; // 单位编号
    unitName?: string; // 单位名字
    status: number; // 物料状态
    standard: string; // 物料规格
    remark: string; // 物料备注
    expiryDay: number; // 保质期天数
    weight: number; // 重量（kg）
    purchasePrice: number; // 采购价格，单位：元
    salePrice: number; // 销售价格，单位：元
    minPrice: number; // 最低价格，单位：元
    allowCentral?: boolean; // 是否允许统配（中心库配送出库）
    allowDirect?: boolean; // 是否允许直拨（下采购订单、供应商直送门店）
  }
}

/** 查询物料分页 */
export function getProductPage(params: PageParam) {
  return requestClient.get<PageResult<ErpProductApi.Product>>(
    '/erp/product/page',
    { params },
  );
}

/** 查询物料精简列表 */
export function getProductSimpleList() {
  return requestClient.get<ErpProductApi.Product[]>('/erp/product/simple-list');
}

/** 查询物料详情 */
export function getProduct(id: number) {
  return requestClient.get<ErpProductApi.Product>(`/erp/product/get?id=${id}`);
}

/** 新增物料 */
export function createProduct(data: ErpProductApi.Product) {
  return requestClient.post('/erp/product/create', data);
}

/** 修改物料 */
export function updateProduct(data: ErpProductApi.Product) {
  return requestClient.put('/erp/product/update', data);
}

/** 删除物料 */
export function deleteProduct(id: number) {
  return requestClient.delete(`/erp/product/delete?id=${id}`);
}

/** 导出物料 Excel */
export function exportProduct(params: any) {
  return requestClient.download('/erp/product/export-excel', { params });
}
