import type { PageParam, PageResult } from '@vben/request';

import { requestClient } from '#/api/request';

export namespace ErpProductUnitApi {
  /** 物料单位信息 */
  export interface ProductUnit {
    id?: number; // 单位编号
    name: string; // 单位名字
    status: number; // 单位状态
  }
}

/** 查询物料单位分页 */
export function getProductUnitPage(params: PageParam) {
  return requestClient.get<PageResult<ErpProductUnitApi.ProductUnit>>(
    '/erp/product-unit/page',
    { params },
  );
}

/** 查询物料单位精简列表 */
export function getProductUnitSimpleList() {
  return requestClient.get<ErpProductUnitApi.ProductUnit[]>(
    '/erp/product-unit/simple-list',
  );
}

/** 查询物料单位详情 */
export function getProductUnit(id: number) {
  return requestClient.get<ErpProductUnitApi.ProductUnit>(
    `/erp/product-unit/get?id=${id}`,
  );
}

/** 新增物料单位 */
export function createProductUnit(data: ErpProductUnitApi.ProductUnit) {
  return requestClient.post('/erp/product-unit/create', data);
}

/** 修改物料单位 */
export function updateProductUnit(data: ErpProductUnitApi.ProductUnit) {
  return requestClient.put('/erp/product-unit/update', data);
}

/** 删除物料单位 */
export function deleteProductUnit(id: number) {
  return requestClient.delete(`/erp/product-unit/delete?id=${id}`);
}

/** 导出物料单位 Excel */
export function exportProductUnit(params: any) {
  return requestClient.download('/erp/product-unit/export-excel', { params });
}
