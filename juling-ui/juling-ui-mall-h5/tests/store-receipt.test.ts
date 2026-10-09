import assert from 'node:assert/strict';
import { test } from 'node:test';

import {
  adaptFileUrls,
  adaptStoreReceiptDetail,
  adaptStoreReceiptDiffType,
  adaptStoreReceiptItem,
  adaptStoreReceiptPage,
  adaptStoreReceiptStatus,
} from '../src/api/adapters/receipt.ts';

/* ------------------------------ 门店收货适配 ------------------------------ */

test('adaptStoreReceiptStatus：未知 / 空值回落「待确认」', () => {
  assert.equal(adaptStoreReceiptStatus(undefined), 0);
  assert.equal(adaptStoreReceiptStatus(null), 0);
  assert.equal(adaptStoreReceiptStatus(99), 0);
  assert.equal(adaptStoreReceiptStatus(10), 10);
  assert.equal(adaptStoreReceiptStatus(20), 20);
});

test('adaptStoreReceiptDiffType：未知 / 空值回落「无差异」', () => {
  assert.equal(adaptStoreReceiptDiffType(undefined), 0);
  assert.equal(adaptStoreReceiptDiffType(9), 0);
  assert.equal(adaptStoreReceiptDiffType(1), 1);
  assert.equal(adaptStoreReceiptDiffType(4), 4);
});

test('adaptStoreReceiptPage：数量可能是字符串、空分页兜底', () => {
  const page = adaptStoreReceiptPage({
    list: [
      {
        id: 1,
        no: 'SH202601010001',
        orderId: 90000,
        orderNo: 'JL202601011000',
        customerName: '亚特一店',
        // 后端 numeric(24,6) 序列化后可能是字符串
        totalCount: '9.500' as unknown as number,
        totalPrice: 120000,
        receiveTime: null,
        saleOutNo: 'CK202601010001',
        status: 0,
        statusName: '待确认',
        diffType: 0,
        diffTypeName: '无差异',
      },
    ],
    total: 1,
  });
  assert.equal(page.total, 1);
  assert.equal(page.list[0]?.no, 'SH202601010001');
  assert.equal(page.list[0]?.totalCount, 9.5);
  assert.equal(page.list[0]?.totalPrice, 120000);
  assert.equal(page.list[0]?.receiveTime, undefined);
  assert.equal(page.list[0]?.status, 0);

  assert.deepEqual(adaptStoreReceiptPage({ list: [], total: 0 }), { list: [], total: 0 });
});

test('adaptStoreReceiptItem：字段改名、规格兼容属性数组、批次效期透传', () => {
  const item = adaptStoreReceiptItem({
    id: 11,
    orderItemId: 10,
    spuId: 100,
    skuId: 101,
    spuName: '雪花牛腩',
    properties: '冷冻 5kg/箱',
    picUrl: 'http://127.0.0.1:48080/admin-api/infra/file/1/a.png',
    productId: 200,
    productName: '雪花牛腩（ERP）',
    price: 15800,
    expectCount: 10,
    receiptCount: 0,
    diffCount: 0,
    diffAmount: 0,
    diffReason: null,
    batchNo: 'B20260101',
    productionDate: null,
    expiryDate: 1735689600000,
  });
  assert.equal(item.orderItemId, 10);
  assert.equal(item.name, '雪花牛腩');
  assert.equal(item.specText, '冷冻 5kg/箱');
  // 内网绝对地址归一化为同源相对路径，开发环境由 vite 代理转发
  assert.equal(item.picUrl, '/admin-api/infra/file/1/a.png');
  assert.equal(item.diffReason, undefined);
  assert.equal(item.batchNo, 'B20260101');
  assert.equal(item.expiryDate, 1735689600000);

  // 历史数据可能下发属性数组，取 valueName 拼接
  const legacy = adaptStoreReceiptItem({
    id: 12,
    orderItemId: 11,
    spuId: 100,
    skuId: 102,
    spuName: '雪花牛腩',
    properties: [
      { propertyId: 1, propertyName: '规格', valueId: 1, valueName: '冷冻' },
      { propertyId: 2, propertyName: '包装', valueId: 2, valueName: '5kg/箱' },
    ] as unknown as string,
    picUrl: '',
    productId: 200,
    productName: '',
    price: 15800,
    expectCount: '2.000' as unknown as number,
    receiptCount: 0,
    diffCount: 0,
    diffAmount: 0,
    diffReason: null,
    batchNo: null,
    productionDate: null,
    expiryDate: null,
  });
  assert.equal(legacy.specText, '冷冻 5kg/箱');
  assert.equal(legacy.expectCount, 2);
  assert.equal(legacy.picUrl, '');
});

test('adaptFileUrls：兼容 JSON 数组字符串（后端真实形态）、数组与空值', () => {
  // 后端 file_urls 是文本列，落库时 JsonUtils.toJsonString，下发的是 JSON 字符串
  assert.deepEqual(
    adaptFileUrls(
      '["http://127.0.0.1:48080/admin-api/infra/file/1/a.png","/admin-api/infra/file/1/b.png"]',
    ),
    ['/admin-api/infra/file/1/a.png', '/admin-api/infra/file/1/b.png'],
  );
  assert.deepEqual(adaptFileUrls(['/a.png', '']), ['/a.png']);
  assert.deepEqual(adaptFileUrls('/a.png,/b.png'), ['/a.png', '/b.png']);
  assert.deepEqual(adaptFileUrls('[broken json'), []);
  assert.deepEqual(adaptFileUrls(null), []);
  assert.deepEqual(adaptFileUrls(undefined), []);
  assert.deepEqual(adaptFileUrls(''), []);
});

test('adaptStoreReceiptDetail：图片归一化 + 空串剔除、空值转 undefined', () => {
  const detail = adaptStoreReceiptDetail({
    id: 1,
    no: 'SH202601010001',
    orderId: 90000,
    orderNo: 'JL202601011000',
    customerName: '亚特一店',
    saleOutNo: 'CK202601010001',
    status: 10,
    statusName: '已确认',
    diffType: 3,
    diffTypeName: '破损',
    totalCount: 10,
    receiptCount: 9.5,
    diffCount: -0.5,
    totalPrice: 158000,
    receiptPrice: 150100,
    diffAmount: -7900,
    receiverName: null,
    receiverMobile: null,
    // 真实后端下发的是 JSON 数组字符串，且可能带空串
    fileUrls:
      '["http://127.0.0.1:48080/admin-api/infra/file/1/a.png","","/admin-api/infra/file/1/b.png"]',
    remark: null,
    receiveTime: 1735689600000,
    items: [],
  });
  assert.equal(detail.status, 10);
  assert.equal(detail.diffType, 3);
  assert.equal(detail.diffTypeName, '破损');
  assert.equal(detail.diffCount, -0.5);
  assert.equal(detail.diffAmount, -7900);
  assert.equal(detail.receiverName, undefined);
  assert.equal(detail.remark, undefined);
  assert.deepEqual(detail.fileUrls, [
    '/admin-api/infra/file/1/a.png',
    '/admin-api/infra/file/1/b.png',
  ]);
  assert.equal(detail.receiveTime, 1735689600000);
  assert.deepEqual(detail.items, []);
});
