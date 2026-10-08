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
  const result = adaptProductPage(page);
  await applyStorePrice(result.list);
  return result;
}

/** 商品详情（含 SKU；后端无独立 SKU 列表接口，SKU 随详情一起返回） */
export async function getProductDetail(id: number): Promise<Product> {
  const detail = await http.get<AppProductSpuDetailRespVO>('/product/spu/get-detail', { id });
  const result = adaptSpuDetail(detail);
  await applyStorePrice([result]);
  return result;
}

/**
 * 用**门店价**覆盖商城价
 *
 * 为什么放在数据入口而不是视图层：下单价是门店维度、按 SKU 算的（/trade/order/store-price），
 * 而列表展示的是 SPU 价、详情展示的是 SKU 价 —— 只改其中一个就会「列表一个价、详情另一个价」。
 * 在唯一的数据入口统一覆盖，两个页面自动一致，**视图层零改动**。
 *
 * 拿不到就**保持商城价**：浏览不该因为取价失败而打不开（下单时后端还会按同一套规则兜底）。
 */
async function applyStorePrice(items: Product[]): Promise<void> {
  const skuIds = items.flatMap((item) => item.skuIds ?? []);
  if (skuIds.length === 0) return;
  try {
    const priceMap = await http.get<Record<string, number>>('/trade/order/store-price', {
      skuIds: skuIds.join(','),
    });
    for (const item of items) {
      // 详情：逐 SKU 覆盖
      for (const sku of item.skus ?? []) {
        const storePrice = priceMap?.[String(sku.id)];
        if (typeof storePrice === 'number') sku.price = storePrice;
      }
      // 列表：SPU 展示价取名下 SKU 的最低价（与商城「起」价口径一致）
      const prices = (item.skuIds ?? [])
        .map((id: number) => priceMap?.[String(id)])
        .filter((v): v is number => typeof v === 'number');
      if (prices.length > 0) item.price = Math.min(...prices);
    }
  } catch {
    // 忽略：保持商城价
  }
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
