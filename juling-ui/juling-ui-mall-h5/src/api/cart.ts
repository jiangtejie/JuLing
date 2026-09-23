import type { AppCartListRespVO } from '@/types';
import { http } from '@/utils/request';

/**
 * 订货单（购物车）接口。
 *
 * 注意（计划 D4）：当前订货单以前端本地 `cartStore` 为准，**未接入服务端购物车**；
 * 本模块仅按后端 `/trade/cart/*` 契约校正（字段 `count` / `id` / 参数 `ids`），
 * 供后续切换为服务端购物车时使用。
 */

/** 获取订货单（购物车）列表 */
export function getCartList(): Promise<AppCartListRespVO> {
  return http.get<AppCartListRespVO>('/trade/cart/list');
}

/** 加入订货单（后端字段为 `count`，非 `quantity`） */
export function addCart(data: { skuId: number; count: number }): Promise<number> {
  return http.post<number>('/trade/cart/add', data);
}

/** 修改数量（后端以购物车项 `id` + `count` 更新） */
export function updateCartQuantity(data: { id: number; count: number }): Promise<boolean> {
  return http.put<boolean>('/trade/cart/update-count', data);
}

/** 删除行项（后端参数名为 `ids`，逗号分隔） */
export function deleteCart(ids: number[]): Promise<boolean> {
  return http.delete<boolean>('/trade/cart/delete', { ids: ids.join(',') });
}
