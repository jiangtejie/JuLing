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
    deliveryTypes: [1],
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
    deliveryTypes: [1],
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
    deliveryTypes: [1],
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
        deliveryTypes: [1],
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

/* ------------------------------ 订单适配 ------------------------------ */

test('adaptOrderStatus：后端码 → 前端 key', () => {
  assert.equal(adaptOrderStatus(0), 'UNPAID');
  assert.equal(adaptOrderStatus(10), 'PAID');
  assert.equal(adaptOrderStatus(20), 'SHIPPED');
  assert.equal(adaptOrderStatus(30), 'COMPLETED');
  assert.equal(adaptOrderStatus(40), 'CANCELED');
  assert.equal(adaptOrderStatus(999), 'CANCELED');
});

test('orderStatusKeyToCode：key → 后端码；all/未知/AFTER_SALE → undefined', () => {
  assert.equal(orderStatusKeyToCode('UNPAID'), 0);
  assert.equal(orderStatusKeyToCode('SHIPPED'), 20);
  assert.equal(orderStatusKeyToCode('all'), undefined);
  assert.equal(orderStatusKeyToCode(undefined), undefined);
  assert.equal(orderStatusKeyToCode('AFTER_SALE'), undefined);
  assert.equal(orderStatusKeyToCode('NOT_EXIST'), undefined);
});

test('adaptOrderItem：spuName→name、count→quantity、properties→specText', () => {
  const item = adaptOrderItem({
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
  });
  assert.equal(item.name, '大米');
  assert.equal(item.quantity, 20);
  assert.equal(item.specText, '标准装');
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

test('adaptOrderDetail：字段改名 + 地址拼接', () => {
  const order = adaptOrderDetail({
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
    pickUpStoreId: null,
    pickUpVerifyCode: null,
    refundStatus: null,
    refundPrice: null,
    couponId: null,
    couponPrice: 0,
    pointPrice: 0,
    vipPrice: 0,
    combinationRecordId: null,
    items: [],
  });
  assert.equal(order.orderNo, 'JL202601011000');
  assert.equal(order.status, 'SHIPPED');
  assert.equal(order.freightPrice, 800);
  assert.equal(order.remark, '工作日送达');
  assert.equal(order.receiverAddress, '浙江省杭州市 文一西路 969 号');
  assert.equal(order.payTime, 1735689700000);
  assert.equal(order.deliveryTime, undefined);
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
    pickUpStoreId: null,
    pickUpVerifyCode: null,
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
