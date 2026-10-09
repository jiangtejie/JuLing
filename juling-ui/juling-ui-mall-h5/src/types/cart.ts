import type { Sku } from './sku';

/** 订货单 / 购物车行项 */
export interface CartItem {
  /** 行项唯一标识：spuId + skuId */
  key: string;
  /** 服务端购物车行项编号（登录态下用于 update-count / delete） */
  cartId?: number;
  spuId: number;
  skuId: number;
  name: string;
  picUrl?: string;
  /** 规格描述，如「红色 M」 */
  specText: string;
  /** 当前生效单价（单位：分），已考虑阶梯价 */
  price: number;
  /** 原价（单位：分） */
  originPrice: number;
  quantity: number;
  stock: number;
  minOrderQuantity: number;
  checked: boolean;
  /** 是否为阶梯价商品 */
  tierPrice?: boolean;
  /** SKU 快照，便于下单时复用 */
  sku?: Partial<Sku>;
}

/**
 * 失效行项：后端的 `invalidList`（下架 / 售罄 / 起订量或价格变化等不可下单的商品）。
 * 结构与有效项一致，只多一个 `invalid` 标记，便于页面用同一套卡片渲染并置灰。
 */
export interface InvalidCartItem extends CartItem {
  /** 失效标记（页面用同一套卡片渲染时可据此置灰） */
  invalid: true;
  /**
   * 失效原因，如「商品已下架」「库存不足」。
   * 后端不下发原因字段，由 adapter 按 SPU 状态 / 库存推导（口径与后端 TradeCartConvert 一致）。
   */
  invalidReason: string;
}

/**
 * 购物车列表聚合结果。
 *
 * 之前只取 `validList`，失效商品在 H5 完全不可见：用户勾了一车货，
 * 下架的那件「凭空少了一件」，既看不到也删不掉。现在两类都带出来，
 * 由页面决定失效项的展示与清理。
 */
export interface CartListResult {
  /** 可下单行项 */
  items: CartItem[];
  /** 失效行项（不可下单，需展示原因/引导删除） */
  invalidItems: InvalidCartItem[];
}
