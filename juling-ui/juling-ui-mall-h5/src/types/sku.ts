/** 规格项，如「颜色」-> ['红','蓝'] */
export interface SkuSpec {
  id: number;
  name: string;
  values: string[];
}

/** 阶梯价：订货业务核心，按数量区间定价 */
export interface SkuTierPrice {
  /** 区间起始数量（含） */
  minQuantity: number;
  /** 区间结束数量（含），为空表示上不封顶 */
  maxQuantity?: number;
  /** 单价（单位：分） */
  price: number;
}

/** 最小库存单元 */
export interface Sku {
  id: number;
  spuId: number;
  /** SKU 名称 / 规格描述，如「红色 M」 */
  name: string;
  picUrl?: string;
  /** 规格组合，如 { 颜色: '红', 尺码: 'M' } */
  properties: Record<string, string>;
  /** 零售价（单位：分） */
  price: number;
  /** 划线价 / 市场价（单位：分） */
  marketPrice?: number;
  /** 可用库存 */
  stock: number;
  /** 起订量 */
  minOrderQuantity?: number;
  /** 阶梯价列表（按 minQuantity 升序） */
  tierPrices?: SkuTierPrice[];
}

/** 商品（SPU） */
export interface Product {
  id: number;
  name: string;
  picUrl?: string;
  /** 详情轮播图（后端 sliderPicUrls）；为空时详情页回退 picUrl */
  sliderPicUrls?: string[];
  /** 商品副标题 / 卖点 */
  subTitle?: string;
  /** 展示价（单位：分），多规格时取最低价 */
  price: number;
  marketPrice?: number;
  salesCount?: number;
  stock?: number;
  unit?: string;
  categoryId?: number;
  /** 是否支持阶梯价 */
  supportTierPrice?: boolean;
  skus?: Sku[];
  specList?: SkuSpec[];
  detailHtml?: string;
}
