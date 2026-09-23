/** 订单状态 */
export type OrderStatus = 'UNPAID' | 'PAID' | 'SHIPPED' | 'COMPLETED' | 'CANCELED' | 'AFTER_SALE';

/** 订单行项 */
export interface OrderItem {
  id: number;
  spuId: number;
  skuId: number;
  name: string;
  picUrl?: string;
  specText: string;
  price: number;
  quantity: number;
  /** 小计（单位：分） */
  totalPrice: number;
}

/** 订单 */
export interface Order {
  id: number;
  orderNo: string;
  status: OrderStatus;
  /** 订单总额（单位：分） */
  totalPrice: number;
  /** 优惠金额（单位：分） */
  discountPrice?: number;
  /** 实付金额（单位：分） */
  payPrice: number;
  /** 运费（单位：分） */
  freightPrice?: number;
  receiverName?: string;
  receiverMobile?: string;
  receiverAddress?: string;
  remark?: string;
  createTime: string | number;
  payTime?: string | number;
  deliveryTime?: string | number;
  items: OrderItem[];
}

/** 创建订单参数 */
export interface OrderCreateParam {
  items: Array<{ skuId: number; quantity: number }>;
  receiverName: string;
  receiverMobile: string;
  receiverAddress: string;
  remark?: string;
}
