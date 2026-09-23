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
