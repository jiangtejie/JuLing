import assert from 'node:assert/strict';
import { test } from 'node:test';

import {
  adaptCategory,
  adaptProductPage,
  adaptProperties,
  adaptSku,
  adaptSpu,
  adaptSpuDetail,
  buildCategoryTree,
  buildSkuName,
} from '../src/api/adapters/product.ts';
import {
  adaptOrderDetail,
  adaptOrderItem,
  adaptOrderPage,
  adaptOrderStatus,
  adaptPaymentProof,
  adaptReceiveStatus,
  orderStatusKeyToCode,
} from '../src/api/adapters/order.ts';
import { adaptLoginResult, adaptUserInfo } from '../src/api/adapters/user.ts';
import {
  adaptCartItem,
  adaptCartList,
  adaptCartListResult,
  adaptInvalidCartItem,
} from '../src/api/adapters/cart.ts';

/* ------------------------------ 商品适配 ------------------------------ */

test('adaptProperties：属性对象数组 → Record<属性名, 属性值>', () => {
  const result = adaptProperties([
    { propertyId: 1, propertyName: '颜色', valueId: 10, valueName: '红色' },
    { propertyId: 2, propertyName: '尺码', valueId: 20, valueName: 'M' },
  ]);
  assert.deepEqual(result, { 颜色: '红色', 尺码: 'M' });
});

test('adaptProperties：空/未定义 → 空对象', () => {
  assert.deepEqual(adaptProperties(undefined), {});
  assert.deepEqual(adaptProperties(null), {});
  assert.deepEqual(adaptProperties([]), {});
});

test('buildSkuName：拼接属性值，无属性时回退「规格 <id>」', () => {
  assert.equal(buildSkuName(5, { 颜色: '红色', 尺码: 'M' }), '红色 M');
  assert.equal(buildSkuName(5, {}), '规格 5');
});

test('adaptSku：properties 转 Record、补 spuId/minOrderQuantity=1、tierPrices 为空', () => {
  const sku = adaptSku(
    {
      id: 101,
      properties: [{ propertyId: 1, propertyName: '规格', valueId: 1, valueName: '标准装' }],
      price: 5980,
      marketPrice: 7475,
      vipPrice: 5800,
      picUrl: 'http://img/101.png',
      stock: 860,
      weight: 1,
      volume: 0.1,
    },
    1001,
  );
  assert.equal(sku.id, 101);
  assert.equal(sku.spuId, 1001);
  assert.equal(sku.name, '标准装');
  assert.deepEqual(sku.properties, { 规格: '标准装' });
  assert.equal(sku.price, 5980);
  assert.equal(sku.marketPrice, 7475);
  assert.equal(sku.stock, 860);
  assert.equal(sku.minOrderQuantity, 1);
  assert.equal(sku.tierPrices, undefined);
});

test('adaptSku：marketPrice 缺省时回退 price', () => {
  const sku = adaptSku(
    {
      id: 1,
      properties: [],
      price: 100,
      marketPrice: 0,
      vipPrice: 0,
      picUrl: '',
      stock: 1,
      weight: 0,
      volume: 0,
    },
    1,
  );
  assert.equal(sku.marketPrice, 100);
});

test('adaptSpu：introduction→subTitle、supportTierPrice=false、字段透传', () => {
  const product = adaptSpu({
    id: 1001,
    name: '精品五常大米 5kg',
    introduction: '当季新米 · 产地直发',
    categoryId: 1,
    picUrl: 'http://img/spu.png',
    sliderPicUrls: [],
    specType: true,
    price: 5980,
    marketPrice: 7475,
    stock: 1180,
    salesCount: 12860,
  });
  assert.equal(product.id, 1001);
  assert.equal(product.subTitle, '当季新米 · 产地直发');
  assert.equal(product.supportTierPrice, false);
  // 多规格标记要透传：分类页据此决定「+」直加还是「选规格」
  assert.equal(product.specType, true);
  assert.equal(product.price, 5980);
  assert.equal(product.salesCount, 12860);
});

test('adaptSpu：sliderPicUrls 多图透传，空数组归一为 undefined', () => {
  const base = {
    id: 1,
    name: 'A',
    introduction: 'a',
    categoryId: 1,
    picUrl: 'p.png',
    specType: false,
    price: 100,
    marketPrice: 120,
    stock: 1,
    salesCount: 0,
  };
  assert.deepEqual(adaptSpu({ ...base, sliderPicUrls: ['a.png', 'b.png'] }).sliderPicUrls, [
    'a.png',
    'b.png',
  ]);
  assert.equal(adaptSpu({ ...base, sliderPicUrls: [] }).sliderPicUrls, undefined);
});

test('adaptSpu / adaptSku：内网绝对地址在适配层就被归一化为相对路径', () => {
  const spu = adaptSpu({
    id: 1,
    name: 'A',
    introduction: 'a',
    categoryId: 1,
    // 后端常见形态：写死 http://127.0.0.1:48080 的绝对地址
    picUrl: 'http://127.0.0.1:48080/admin-api/infra/file/29/get/a.png',
    sliderPicUrls: ['http://127.0.0.1:48080/admin-api/infra/file/29/get/b.png'],
    specType: false,
    price: 100,
    marketPrice: 120,
    stock: 1,
    salesCount: 0,
  });
  assert.equal(spu.picUrl, '/admin-api/infra/file/29/get/a.png');
  assert.deepEqual(spu.sliderPicUrls, ['/admin-api/infra/file/29/get/b.png']);

  const sku = adaptSku(
    {
      id: 101,
      properties: [],
      price: 100,
      marketPrice: 100,
      vipPrice: 0,
      picUrl: 'http://192.168.110.62:48080/admin-api/infra/file/29/get/c.png',
      stock: 1,
      weight: 0,
      volume: 0,
    },
    1,
  );
  assert.equal(sku.picUrl, '/admin-api/infra/file/29/get/c.png');
});

test('adaptSpuDetail：description→detailHtml、skus 映射并注入 spuId', () => {
  const product = adaptSpuDetail({
    id: 1001,
    name: '大米',
    introduction: '简介',
    description: '<p>详情</p>',
    categoryId: 1,
    picUrl: '',
    sliderPicUrls: [],
    specType: true,
    price: 5980,
    marketPrice: 7475,
    stock: 100,
    skus: [
      {
        id: 101,
        properties: [{ propertyId: 1, propertyName: '规格', valueId: 1, valueName: '标准装' }],
        price: 5980,
        marketPrice: 7475,
        vipPrice: 0,
        picUrl: '',
        stock: 50,
        weight: 0,
        volume: 0,
      },
    ],
    salesCount: 1,
  });
  assert.equal(product.detailHtml, '<p>详情</p>');
  assert.equal(product.skus?.length, 1);
  assert.equal(product.skus?.[0].spuId, 1001);
  assert.equal(product.skus?.[0].name, '标准装');
});

test('adaptProductPage：分页透传并逐项适配', () => {
  const page = adaptProductPage({
    list: [
      {
        id: 1,
        name: 'A',
        introduction: 'a',
        categoryId: 1,
        picUrl: '',
        sliderPicUrls: [],
        specType: false,
        price: 100,
        marketPrice: 120,
        stock: 5,
        salesCount: 3,
      },
    ],
    total: 42,
  });
  assert.equal(page.total, 42);
  assert.equal(page.list.length, 1);
  assert.equal(page.list[0].subTitle, 'a');
});

test('adaptProductPage：空响应兜底', () => {
  const page = adaptProductPage(undefined as never);
  assert.deepEqual(page, { list: [], total: 0 });
});

test('adaptCategory：字段透传（保留 parentId）', () => {
  assert.deepEqual(adaptCategory({ id: 1, parentId: 0, name: '粮油干货', picUrl: '' }), {
    id: 1,
    name: '粮油干货',
    parentId: 0,
    picUrl: '',
  });
});

test('adaptCategory：子分类保留 parentId，内网图片地址归一化', () => {
  assert.deepEqual(
    adaptCategory({
      id: 3,
      parentId: 2,
      name: '土里埋的',
      picUrl: 'http://127.0.0.1:48080/admin-api/infra/file/29/a.png',
    }),
    { id: 3, name: '土里埋的', parentId: 2, picUrl: '/admin-api/infra/file/29/a.png' },
  );
});

test('buildCategoryTree：平铺列表 → 一级分类挂在 children 上', () => {
  const tree = buildCategoryTree([
    { id: 2, parentId: 0, name: '素菜' },
    { id: 3, parentId: 2, name: '土里埋的' },
    { id: 4, parentId: 0, name: '肉禽蛋' },
  ]);
  assert.equal(tree.length, 2);
  assert.equal(tree[0].name, '素菜');
  assert.deepEqual(
    tree[0].children?.map((item) => item.name),
    ['土里埋的'],
  );
  assert.deepEqual(tree[1].children, []);
});

test('buildCategoryTree：父分类不在列表中的孤儿节点提升为一级', () => {
  const tree = buildCategoryTree([{ id: 9, parentId: 999, name: '父分类已禁用' }]);
  assert.equal(tree.length, 1);
  assert.equal(tree[0].id, 9);
  assert.deepEqual(tree[0].children, []);
});

/* ------------------------------ 购物车适配 ------------------------------ */

/** 购物车行项 VO 基线（内嵌 SKU 无 name / 起订量 / 阶梯价） */
const baseCartItemVO = {
  id: 7001,
  count: 3,
  selected: true,
  spu: {
    id: 1001,
    name: '精品五常大米 5kg',
    picUrl: 'http://127.0.0.1:48080/a.png',
    categoryId: 1,
    stock: 100,
    status: 0,
  },
  sku: {
    id: 101,
    picUrl: 'http://127.0.0.1:48080/b.png',
    price: 5980,
    stock: 50,
    properties: [{ propertyId: 1, propertyName: '规格', valueId: 1, valueName: '标准装' }],
  },
};

test('adaptCartItem：内嵌 SKU（无 name / 无阶梯价）→ 领域模型', () => {
  const item = adaptCartItem(baseCartItemVO);
  assert.equal(item.key, '1001-101');
  assert.equal(item.cartId, 7001);
  assert.equal(item.name, '精品五常大米 5kg');
  assert.equal(item.specText, '标准装');
  assert.equal(item.price, 5980);
  assert.equal(item.quantity, 3);
  assert.equal(item.stock, 50);
  // 内网绝对地址在适配层归一化
  assert.equal(item.picUrl, '/b.png');
  assert.equal(item.tierPrice, undefined);
});

test('adaptCartList：只返回有效项（保持既有签名，store 调用方不受影响）', () => {
  const items = adaptCartList({ validList: [baseCartItemVO], invalidList: [] });
  assert.equal(items.length, 1);
  assert.equal(items[0].skuId, 101);
});

test('adaptCartListResult：失效项不再被吞掉（用户才知道为什么少了一件）', () => {
  const invalid = { ...baseCartItemVO, id: 7002, selected: true };
  const result = adaptCartListResult({
    validList: [baseCartItemVO],
    invalidList: [invalid],
  });
  assert.equal(result.items.length, 1);
  assert.equal(result.invalidItems.length, 1);
  assert.equal(result.invalidItems[0].cartId, 7002);
  // 失效项带标记且强制不勾选：不能被一起提交下单
  assert.equal(result.invalidItems[0].invalid, true);
  assert.equal(result.invalidItems[0].checked, false);
  assert.equal(typeof result.invalidItems[0].invalidReason, 'string');
});

test('adaptInvalidCartItem：失效原因与后端判定口径一致（下架 / 库存不足 / 兜底）', () => {
  // 后端 TradeCartConvert：SPU 下架（status 0）
  const offShelf = adaptInvalidCartItem({
    ...baseCartItemVO,
    spu: { ...baseCartItemVO.spu, status: 0, stock: 10 },
  });
  assert.equal(offShelf.invalidReason, '商品已下架');

  // SPU 库存 <= 0
  const soldOut = adaptInvalidCartItem({
    ...baseCartItemVO,
    spu: { ...baseCartItemVO.spu, status: 1, stock: 0 },
  });
  assert.equal(soldOut.invalidReason, '库存不足');

  // SPU 已被删除（后端 spu 为 null）
  const removed = adaptInvalidCartItem({ ...baseCartItemVO, spu: null });
  assert.equal(removed.invalidReason, '商品已下架或不存在');

  // 状态缺失的旧后端：不臆断「已下架」，给中性兜底文案
  const legacy = adaptInvalidCartItem({
    ...baseCartItemVO,
    spu: { ...baseCartItemVO.spu, status: undefined as unknown as number, stock: 5 },
  });
  assert.equal(legacy.invalidReason, '商品已失效');
});

test('adaptCartListResult：后端不返回 invalidList（旧版本）时不报错', () => {
  const result = adaptCartListResult({ validList: [baseCartItemVO] } as never);
  assert.equal(result.items.length, 1);
  assert.deepEqual(result.invalidItems, []);
});

test('adaptInvalidCartItem：有效项与失效项结构一致，只有 invalid 标记不同', () => {
  const valid = adaptCartItem(baseCartItemVO);
  const invalid = adaptInvalidCartItem(baseCartItemVO);
  assert.equal(invalid.key, valid.key);
  assert.equal(invalid.price, valid.price);
  assert.equal(invalid.specText, valid.specText);
  assert.equal(invalid.invalid, true);
});

/* ------------------------------ 订单适配 ------------------------------ */

test('adaptOrderStatus：后端码 → 前端 key', () => {
  assert.equal(adaptOrderStatus(0), 'UNPAID');
  assert.equal(adaptOrderStatus(10), 'PAID');
  assert.equal(adaptOrderStatus(20), 'SHIPPED');
  assert.equal(adaptOrderStatus(30), 'COMPLETED');
  assert.equal(adaptOrderStatus(40), 'CANCELED');
});

test('adaptOrderStatus：后端新增状态码不再冒充「已取消」，兜底为显式 UNKNOWN', () => {
  // 关键回归：曾经兜底成 CANCELED，后端一加状态门店就看到「已取消」
  assert.equal(adaptOrderStatus(999), 'UNKNOWN');
  assert.equal(adaptOrderStatus(-1), 'UNKNOWN');
  assert.equal(adaptOrderStatus(50), 'UNKNOWN');
  assert.notEqual(adaptOrderStatus(50), 'CANCELED');
});

test('adaptOrderStatus：UNKNOWN 不参与列表筛选（不能拼出非法状态码）', () => {
  assert.equal(orderStatusKeyToCode('UNKNOWN'), undefined);
});

test('orderStatusKeyToCode：key → 后端码；all/未知/AFTER_SALE → undefined', () => {
  assert.equal(orderStatusKeyToCode('UNPAID'), 0);
  assert.equal(orderStatusKeyToCode('SHIPPED'), 20);
  assert.equal(orderStatusKeyToCode('all'), undefined);
  assert.equal(orderStatusKeyToCode(undefined), undefined);
  assert.equal(orderStatusKeyToCode('AFTER_SALE'), undefined);
  assert.equal(orderStatusKeyToCode('NOT_EXIST'), undefined);
});

/** 订单行项最小字段集：只覆盖价格相关用例关心的字段 */
const baseOrderItem = {
  id: 1,
  orderId: 9,
  spuId: 1001,
  spuName: '大米',
  skuId: 101,
  properties: [{ propertyId: 1, propertyName: '规格', valueId: 1, valueName: '标准装' }],
  picUrl: 'http://img.png',
  count: 20,
  commentStatus: false,
  price: 5980,
  payPrice: 5980,
  afterSaleId: null,
  afterSaleStatus: null,
};

test('adaptOrderItem：spuName→name、count→quantity、properties→specText', () => {
  const item = adaptOrderItem(baseOrderItem);
  assert.equal(item.name, '大米');
  assert.equal(item.quantity, 20);
  assert.equal(item.specText, '标准装');
  assert.equal(item.price, 5980);
});

test('adaptOrderItem：行小计优先用后端 payPrice（后台改价 / 优惠后与 price×count 不同）', () => {
  // 实付 100000 ≠ 5980 × 20：以实付为准，否则「商品金额」与「实付」对不上
  const item = adaptOrderItem({ ...baseOrderItem, payPrice: 100000 });
  assert.equal(item.totalPrice, 100000);
  assert.notEqual(item.totalPrice, baseOrderItem.price * baseOrderItem.count);
});

test('adaptOrderItem：后端未下发 payPrice 时回退 price×count', () => {
  const item = adaptOrderItem({ ...baseOrderItem, payPrice: undefined as unknown as number });
  assert.equal(item.totalPrice, 5980 * 20);
});

test('adaptOrderPage：no→orderNo、status 转换、createTime 保留时间戳', () => {
  const page = adaptOrderPage({
    list: [
      {
        id: 90000,
        no: 'JL202601011000',
        type: 0,
        status: 10,
        productCount: 1,
        commentStatus: false,
        createTime: 1735689600000,
        payOrderId: 1,
        payPrice: 119600,
        deliveryType: 1,
        items: [],
        combinationRecordId: null,
      },
    ],
    total: 1,
  });
  assert.equal(page.total, 1);
  assert.equal(page.list[0].orderNo, 'JL202601011000');
  assert.equal(page.list[0].status, 'PAID');
  assert.equal(page.list[0].createTime, 1735689600000);
});

/** 订单详情 VO 基线：只覆盖本组用例关心的字段，其余按后端必填给中性值 */
const baseOrderDetailVO = {
  id: 90000,
  no: 'JL202601011000',
  type: 0,
  createTime: 1735689600000,
  userRemark: '工作日送达',
  status: 20,
  productCount: 1,
  finishTime: null,
  cancelTime: null,
  commentStatus: false,
  payStatus: true,
  payOrderId: 1,
  payTime: 1735689700000,
  payExpireTime: null,
  payChannelCode: '',
  payChannelName: '',
  totalPrice: 119600,
  discountPrice: 0,
  deliveryPrice: 800,
  adjustPrice: 0,
  payPrice: 120400,
  deliveryType: 1,
  logisticsId: null,
  logisticsName: '',
  logisticsNo: '',
  deliveryTime: null,
  receiveTime: null,
  receiverName: '张经理',
  receiverMobile: '13800138000',
  receiverAreaId: null,
  receiverAreaName: '浙江省杭州市',
  receiverDetailAddress: '文一西路 969 号',
  refundStatus: null,
  refundPrice: null,
  couponId: null,
  couponPrice: 0,
  pointPrice: 0,
  vipPrice: 0,
  combinationRecordId: null,
  items: [],
};

test('adaptOrderDetail：字段改名 + 地址拼接', () => {
  const order = adaptOrderDetail(baseOrderDetailVO);
  assert.equal(order.orderNo, 'JL202601011000');
  assert.equal(order.status, 'SHIPPED');
  assert.equal(order.freightPrice, 800);
  assert.equal(order.remark, '工作日送达');
  assert.equal(order.receiverAddress, '浙江省杭州市 文一西路 969 号');
  assert.equal(order.payTime, 1735689700000);
  assert.equal(order.deliveryTime, undefined);
});

test('adaptOrderDetail：finishTime 适配（订单「已完成」节点的时间）', () => {
  const done = adaptOrderDetail({
    ...baseOrderDetailVO,
    status: 30,
    finishTime: 1735699900000,
  });
  assert.equal(done.finishTime, 1735699900000);

  // 未完成的订单：finishTime 为 null → undefined（详情页不显示该节点时间）
  const unfinished = adaptOrderDetail({ ...baseOrderDetailVO, status: 0, finishTime: null });
  assert.equal(unfinished.finishTime, undefined);
});

test('adaptOrderPage：门店归属与审核状态透传（代理人账号要能看出是哪家店的单）', () => {
  const page = adaptOrderPage({
    total: 1,
    list: [
      {
        id: 62,
        no: 'JL202601011001',
        type: 0,
        status: 10,
        productCount: 1,
        commentStatus: false,
        createTime: 1735689600000,
        payOrderId: null,
        payPrice: 129000,
        paidAmount: 129000,
        paymentProofStatus: 4,
        deliveryType: 1,
        items: [],
        combinationRecordId: null,
        customerId: 14,
        customerName: '萍姐成都（门店）',
        storeType: 'DIRECT',
        auditStatus: 20,
      },
    ],
  });
  assert.equal(page.list[0]!.customerId, 14);
  assert.equal(page.list[0]!.customerName, '萍姐成都（门店）');
  assert.equal(page.list[0]!.storeType, 'DIRECT');
  assert.equal(page.list[0]!.auditStatus, 20);
});

test('adaptOrderDetail：门店 / 审核 / 收货状态透传，缺字段归 null 而不是 undefined', () => {
  const order = adaptOrderDetail({
    ...baseOrderDetailVO,
    customerId: 6,
    customerName: '耙二哥双碑店（门店）',
    storeType: 'DIRECT',
    auditStatus: 30,
    auditRemark: '数量与配送价不符，请修改后重新提交',
    receiptStatus: 20,
  });
  assert.equal(order.customerId, 6);
  assert.equal(order.customerName, '耙二哥双碑店（门店）');
  assert.equal(order.storeType, 'DIRECT');
  assert.equal(order.auditStatus, 30);
  assert.equal(order.auditRemark, '数量与配送价不符，请修改后重新提交');
  assert.equal(order.receiptStatus, 20);

  // 旧后端不下发这些字段：必须是 null（视图按「待提交 / 不显示」兜底），不能是 undefined 造成取不到配置
  const legacy = adaptOrderDetail(baseOrderDetailVO);
  assert.equal(legacy.customerName, null);
  assert.equal(legacy.auditStatus, null);
  assert.equal(legacy.receiptStatus, null);
});

test('adaptOrderItem：数量进度透传（下单 → 已发 → 已收）', () => {
  const item = adaptOrderItem({
    id: 1,
    orderId: 62,
    spuId: 17,
    spuName: '午餐肉',
    skuId: 17,
    properties: [],
    picUrl: '',
    count: 4,
    commentStatus: false,
    price: 11000,
    payPrice: 44000,
    afterSaleId: null,
    afterSaleStatus: 0,
    deliveredCount: '4.000000',
    receiptCount: 3,
  });
  // 后端 decimal 可能是字符串，适配层原样透传，消费方 Number(x) || 0
  assert.equal(item.deliveredCount, '4.000000');
  assert.equal(item.receiptCount, 3);

  // 未发货 / 未收货：字段缺省时归 null（视图按 0 处理，不显示）
  const pending = adaptOrderItem(baseOrderItem);
  assert.equal(pending.deliveredCount, null);
  assert.equal(pending.receiptCount, null);
});

test('adaptReceiveStatus：未返回收款状态时回落「未上传凭证」', () => {
  assert.equal(adaptReceiveStatus(undefined), 0);
  assert.equal(adaptReceiveStatus(null), 0);
  assert.equal(adaptReceiveStatus(3), 3);
});

test('adaptOrderPage：收款状态与已收金额透传（旧后端缺字段时不报错）', () => {
  const base = {
    id: 90001,
    no: 'JL202601011001',
    type: 0,
    status: 0,
    productCount: 1,
    commentStatus: false,
    createTime: 1735689600000,
    payOrderId: null,
    payPrice: 100000,
    deliveryType: 1,
    items: [],
    combinationRecordId: null,
  };
  const page = adaptOrderPage({
    list: [
      { ...base, paidAmount: 40000, paymentProofStatus: 3 },
      { ...base, id: 90002 },
    ],
    total: 2,
  });
  assert.equal(page.list[0].paidAmount, 40000);
  assert.equal(page.list[0].paymentProofStatus, 3);
  // 老后端不返回这两个字段：金额按 0、状态按「未上传凭证」，避免视图层拿到 undefined
  assert.equal(page.list[1].paidAmount, 0);
  assert.equal(page.list[1].paymentProofStatus, 0);
});

test('adaptOrderDetail：收款状态与已收金额透传', () => {
  const order = adaptOrderDetail({
    id: 90000,
    no: 'JL202601011000',
    type: 0,
    createTime: 1735689600000,
    userRemark: '',
    status: 0,
    productCount: 1,
    finishTime: null,
    cancelTime: null,
    commentStatus: false,
    payStatus: false,
    payOrderId: null,
    payTime: null,
    payExpireTime: null,
    payChannelCode: '',
    payChannelName: '',
    totalPrice: 100000,
    discountPrice: 0,
    deliveryPrice: 0,
    adjustPrice: 0,
    payPrice: 100000,
    paidAmount: 60000,
    paymentProofStatus: 1,
    deliveryType: 1,
    logisticsId: null,
    logisticsName: '',
    logisticsNo: '',
    deliveryTime: null,
    receiveTime: null,
    receiverName: '张经理',
    receiverMobile: '13800138000',
    receiverAreaId: null,
    receiverAreaName: '',
    receiverDetailAddress: '文一西路 969 号',
    refundStatus: null,
    refundPrice: null,
    couponId: null,
    couponPrice: 0,
    pointPrice: 0,
    vipPrice: 0,
    combinationRecordId: null,
    items: [],
  });
  assert.equal(order.paidAmount, 60000);
  assert.equal(order.paymentProofStatus, 1);
});

test('adaptPaymentProof：多图归一化、空串剔除、驳回原因透传', () => {
  const proof = adaptPaymentProof({
    id: 1,
    orderId: 90000,
    urls: [
      'http://127.0.0.1:48080/admin-api/infra/file/1/a.png',
      '',
      'https://cdn.example.com/b.png',
    ],
    amount: 60000,
    confirmedAmount: null,
    payerName: null,
    payChannelCode: 'offline_transfer',
    transferTime: null,
    remark: null,
    status: 2,
    auditTime: 1735689800000,
    auditRemark: '金额不符，请重传',
    createTime: 1735689700000,
  });
  assert.deepEqual(proof.urls, ['/admin-api/infra/file/1/a.png', 'https://cdn.example.com/b.png']);
  assert.equal(proof.amount, 60000);
  assert.equal(proof.confirmedAmount, undefined);
  assert.equal(proof.status, 2);
  assert.equal(proof.auditRemark, '金额不符，请重传');
  assert.equal(proof.payChannelCode, 'offline_transfer');
});

/* ------------------------------ 会员适配 ------------------------------ */

test('adaptLoginResult：expiresTime 归一为 number', () => {
  const result = adaptLoginResult({
    userId: 1,
    accessToken: 'tk',
    refreshToken: 'rt',
    expiresTime: '1735689600000',
    openid: null,
  });
  assert.equal(result.userId, 1);
  assert.equal(result.accessToken, 'tk');
  assert.equal(result.expiresTime, 1735689600000);
});

test('adaptUserInfo：level 拍平为 levelName，未提供字段留空', () => {
  const user = adaptUserInfo({
    id: 1,
    nickname: '张经理',
    avatar: 'http://a.png',
    mobile: '13800138000',
    email: '',
    sex: 1,
    point: 0,
    experience: 0,
    level: { id: 1, name: '金牌经销商', level: 3, icon: '' },
  });
  assert.equal(user.nickname, '张经理');
  assert.equal(user.levelName, '金牌经销商');
  assert.equal(user.customerName, undefined);
  assert.equal(user.verified, undefined);
});

test('adaptUserInfo：level 为 null 时不报错', () => {
  const user = adaptUserInfo({
    id: 1,
    nickname: 'n',
    avatar: '',
    mobile: '',
    email: '',
    sex: 0,
    point: 0,
    experience: 0,
    level: null,
  });
  assert.equal(user.levelName, undefined);
});

/** 会员信息最小字段集：只覆盖本组用例关心的可空字段 */
const baseMemberVO = {
  id: 1,
  nickname: '亚特总店',
  avatar: '',
  email: '',
  sex: 0,
  point: 0,
  experience: 0,
  level: null,
};

test('adaptUserInfo：username（订货账号）透传，空串 / 缺失归一为 undefined', () => {
  assert.equal(
    adaptUserInfo({ ...baseMemberVO, username: '亚特总店', mobile: '13800138000' }).username,
    '亚特总店',
  );
  assert.equal(adaptUserInfo({ ...baseMemberVO, username: '  ' }).username, undefined);
  assert.equal(adaptUserInfo({ ...baseMemberVO }).username, undefined);
});

test('adaptUserInfo：mobile 可空（会员手机号已非必填）', () => {
  assert.equal(adaptUserInfo({ ...baseMemberVO, mobile: '13800138000' }).mobile, '13800138000');
  assert.equal(adaptUserInfo({ ...baseMemberVO, mobile: '' }).mobile, undefined);
  assert.equal(adaptUserInfo({ ...baseMemberVO, mobile: null }).mobile, undefined);
  assert.equal(adaptUserInfo({ ...baseMemberVO }).mobile, undefined);
});
