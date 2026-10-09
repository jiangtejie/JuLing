import { requestClient } from '#/api/request';

export namespace ErpProductCategoryApi {
  /** 物料分类信息 */
  export interface ProductCategory {
    id?: number; // 分类编号
    parentId?: number; // 父分类编号
    name: string; // 分类名称
    code?: string; // 分类编码
    sort?: number; // 分类排序
    status?: number; // 开启状态
    children?: ProductCategory[]; // 子分类
  }
}

/** 查询物料分类列表 */
export function getProductCategoryList(params?: any) {
  return requestClient.get<ErpProductCategoryApi.ProductCategory[]>(
    '/erp/product-category/list',
    { params },
  );
}

/** 查询物料分类精简列表 */
export function getProductCategorySimpleList() {
  return requestClient.get<ErpProductCategoryApi.ProductCategory[]>(
    '/erp/product-category/simple-list',
  );
}

/** 查询物料分类详情 */
export function getProductCategory(id: number) {
  return requestClient.get<ErpProductCategoryApi.ProductCategory>(
    `/erp/product-category/get?id=${id}`,
  );
}

/** 新增物料分类 */
export function createProductCategory(
  data: ErpProductCategoryApi.ProductCategory,
) {
  return requestClient.post('/erp/product-category/create', data);
}

/** 修改物料分类 */
export function updateProductCategory(
  data: ErpProductCategoryApi.ProductCategory,
) {
  return requestClient.put('/erp/product-category/update', data);
}

/** 删除物料分类 */
export function deleteProductCategory(id: number) {
  return requestClient.delete(`/erp/product-category/delete?id=${id}`);
}

/** 导出物料分类 Excel */
export function exportProductCategory(params: any) {
  return requestClient.download('/erp/product-category/export-excel', {
    params,
  });
}
