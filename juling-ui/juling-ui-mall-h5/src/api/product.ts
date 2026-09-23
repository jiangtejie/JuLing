import type {
  AppCategoryRespVO,
  AppProductSpuDetailRespVO,
  AppProductSpuRespVO,
  BackendPage,
  PageParam,
  PageResult,
  Product,
} from '@/types';
import { adaptCategory, adaptProductPage, adaptSpuDetail } from '@/api/adapters';
import { http } from '@/utils/request';

export interface ProductQuery extends Partial<PageParam> {
  /** 关键词 */
  keyword?: string;
  categoryId?: number;
  /** 仅看有货 */
  onlyStock?: boolean;
}

/** 商品分页 */
export async function getProductPage(params: ProductQuery): Promise<PageResult<Product>> {
  const page = await http.get<BackendPage<AppProductSpuRespVO>>('/product/spu/page', {
    ...params,
  });
  return adaptProductPage(page);
}

/** 商品详情（含 SKU；后端无独立 SKU 列表接口，SKU 随详情一起返回） */
export async function getProductDetail(id: number): Promise<Product> {
  const detail = await http.get<AppProductSpuDetailRespVO>('/product/spu/get-detail', { id });
  return adaptSpuDetail(detail);
}

/** 分类列表 */
export async function getCategoryList(): Promise<
  Array<{ id: number; name: string; picUrl?: string }>
> {
  const list = await http.get<AppCategoryRespVO[]>('/product/category/list');
  return (list ?? []).map(adaptCategory);
}
