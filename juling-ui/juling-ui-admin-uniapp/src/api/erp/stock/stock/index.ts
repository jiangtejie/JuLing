import type { PageParam, PageResult } from '@/http/types'
import { http } from '@/http/http'

/** ERP 物料库存 */
export interface Stock {
  id?: number // 编号
  productId?: number // 物料编号
  productName?: string // 物料名称
  categoryName?: string // 物料分类名称
  unitName?: string // 物料单位名称
  warehouseId?: number // 仓库编号
  warehouseName?: string // 仓库名称
  count?: number // 库存数量
}

/** 获取物料库存分页列表 */
export function getStockPage(params: PageParam) {
  return http.get<PageResult<Stock>>('/erp/stock/page', params)
}

/** 获取物料库存详情 */
export function getStock(id: number) {
  return http.get<Stock>(`/erp/stock/get?id=${id}`)
}

/** 根据物料和仓库获取库存详情 */
export function getStockByProductAndWarehouse(productId: number, warehouseId: number) {
  return http.get<Stock>('/erp/stock/get', { productId, warehouseId })
}

/** 获取物料库存数量 */
export function getStockCount(productId: number) {
  return http.get<number>('/erp/stock/get-count', { productId })
}
