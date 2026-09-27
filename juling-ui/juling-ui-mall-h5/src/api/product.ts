import type {
  AppCategoryRespVO,
  AppProductSpuDetailRespVO,
  AppProductSpuRespVO,
  BackendPage,
  Category,
  PageParam,
  PageResult,
  Product,
} from '@/types';
import { adaptCategory, adaptProductPage, adaptSpuDetail, buildCategoryTree } from '@/api/adapters';
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

/** 分类列表（后端返回平铺列表，含 parentId；层级由视图层用 buildCategoryTree 组装） */
export async function getCategoryList(): Promise<Category[]> {
  const list = await http.get<AppCategoryRespVO[]>('/product/category/list');
  return (list ?? []).map(adaptCategory);
}

/** 分类树：一级分类带 children，供分类页直接消费 */
export async function getCategoryTree(): Promise<Category[]> {
  return buildCategoryTree(await getCategoryList());
}
