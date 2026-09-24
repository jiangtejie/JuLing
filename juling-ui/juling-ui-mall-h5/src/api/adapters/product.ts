import type {
  AppCategoryRespVO,
  AppProductPropertyValueDetailRespVO,
  AppProductSkuDetailRespVO,
  AppProductSpuDetailRespVO,
  AppProductSpuRespVO,
  BackendPage,
  PageResult,
  Product,
  Sku,
} from '@/types';
// 注意：这里的 import 必须带 `.ts` 扩展名 —— adapter 会被 `node --test` 直接执行
// （见 tests/adapters.test.ts），那个环境按 ESM 解析、不接受省略扩展名，也不认 `@` 别名。
// 本文件其余的 `@/types` 都是纯类型导入，运行时会整体擦除，因此不受影响。
import { normalizeAssetUrl, normalizeOptionalAssetUrl } from '../../utils/asset.ts';

/**
 * 商品域 DTO → 领域模型映射。
 *
 * 后端差异（见计划「现状与契约差异」）在此收口：
 * - `introduction` → `subTitle`、`description` → `detailHtml`；
 * - SKU 无 `name`，由 `properties` 拼展示名；`properties` 由对象数组转 Record；
 * - SKU 无 `minOrderQuantity`（取 1）、无 `tierPrices`（后端无阶梯价能力，恒为空）。
 */

/** properties 对象数组 → `Record<属性名, 属性值>` */
export function adaptProperties(
  properties?: AppProductPropertyValueDetailRespVO[] | null,
): Record<string, string> {
  const result: Record<string, string> = {};
  (properties ?? []).forEach((item) => {
    if (item?.propertyName) result[item.propertyName] = item.valueName ?? '';
  });
  return result;
}

/** 由属性值拼 SKU 展示名（后端 SKU 无 name 字段） */
export function buildSkuName(skuId: number, properties: Record<string, string>): string {
  const values = Object.values(properties).filter(Boolean);
  return values.length ? values.join(' ') : `规格 ${skuId}`;
}

/** 后端 SKU 明细 → 前端 Sku */
export function adaptSku(raw: AppProductSkuDetailRespVO, spuId: number): Sku {
  const properties = adaptProperties(raw.properties);
  return {
    id: raw.id,
    spuId,
    name: buildSkuName(raw.id, properties),
    picUrl: normalizeOptionalAssetUrl(raw.picUrl),
    properties,
    price: raw.price,
    marketPrice: raw.marketPrice || raw.price,
    stock: raw.stock ?? 0,
    minOrderQuantity: 1,
    // 后端未提供阶梯价数据源 → 置空，resolvePrice 自动回退 SKU 基础价
    tierPrices: undefined,
  };
}

/** SPU 公共字段：列表 VO 与详情 VO 共有的部分 */
type SpuCommon = Pick<
  AppProductSpuRespVO,
  | 'id'
  | 'name'
  | 'picUrl'
  | 'sliderPicUrls'
  | 'introduction'
  | 'price'
  | 'marketPrice'
  | 'salesCount'
  | 'stock'
  | 'categoryId'
>;

/** 后端 SPU（列表项 / 详情公共字段）→ 前端 Product */
export function adaptSpu(raw: SpuCommon): Product {
  return {
    id: raw.id,
    name: raw.name,
    picUrl: normalizeOptionalAssetUrl(raw.picUrl),
    // 详情轮播图：后端可能返回空数组 → 归一为 undefined，由详情页回退 picUrl；
    // 多图同样做内网地址归一化（后端返回的是写死内网 host 的绝对 URL）
    sliderPicUrls: raw.sliderPicUrls?.length ? raw.sliderPicUrls.map(normalizeAssetUrl) : undefined,
    subTitle: raw.introduction,
    price: raw.price,
    marketPrice: raw.marketPrice,
    salesCount: raw.salesCount,
    stock: raw.stock,
    categoryId: raw.categoryId,
    // 后端无「阶梯价」概念，恒为 false → 列表页「阶梯价」标签不显示
    supportTierPrice: false,
  };
}

/** 后端 SPU 详情 → 前端 Product（含 SKU） */
export function adaptSpuDetail(raw: AppProductSpuDetailRespVO): Product {
  return {
    ...adaptSpu(raw),
    detailHtml: raw.description,
    skus: (raw.skus ?? []).map((sku) => adaptSku(sku, raw.id)),
  };
}

/** 后端分页 → 前端分页 */
export function adaptProductPage(page: BackendPage<AppProductSpuRespVO>): PageResult<Product> {
  return {
    list: (page?.list ?? []).map(adaptSpu),
    total: page?.total ?? 0,
  };
}

/** 后端分类 → 前端分类 */
export function adaptCategory(raw: AppCategoryRespVO): {
  id: number;
  name: string;
  picUrl?: string;
} {
  return { id: raw.id, name: raw.name, picUrl: normalizeOptionalAssetUrl(raw.picUrl) };
}
