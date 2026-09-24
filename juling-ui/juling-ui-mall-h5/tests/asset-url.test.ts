import assert from 'node:assert/strict';
import { test } from 'node:test';

import { normalizeAssetUrl } from '../src/utils/asset.ts';

/**
 * 后端返回的文件地址常是写死内网 host 的绝对 URL（例如 http://127.0.0.1:48080/admin-api/...），
 * 公网访问时会让浏览器去请求访问者自己的 127.0.0.1，且在 https 页面下触发混合内容拦截。
 * 这里覆盖归一化规则。
 */

test('normalizeAssetUrl：本机 127.0.0.1 绝对地址 → 同源相对路径', () => {
  assert.equal(
    normalizeAssetUrl('http://127.0.0.1:48080/admin-api/infra/file/29/get/20260924/a.png'),
    '/admin-api/infra/file/29/get/20260924/a.png',
  );
});

test('normalizeAssetUrl：localhost / 0.0.0.0 / [::1] 同样归一化', () => {
  assert.equal(normalizeAssetUrl('http://localhost:48080/a.png'), '/a.png');
  assert.equal(normalizeAssetUrl('http://0.0.0.0:48080/a.png'), '/a.png');
  assert.equal(normalizeAssetUrl('http://[::1]:48080/a.png'), '/a.png');
});

test('normalizeAssetUrl：内网网段（192.168 / 10 / 172.16-31）归一化', () => {
  assert.equal(normalizeAssetUrl('http://192.168.110.62:48080/a.png'), '/a.png');
  assert.equal(normalizeAssetUrl('http://10.0.0.5/a.png'), '/a.png');
  assert.equal(normalizeAssetUrl('http://172.20.96.1:3001/a.png'), '/a.png');
});

test('normalizeAssetUrl：公网域名与相对路径保持原样', () => {
  assert.equal(
    normalizeAssetUrl('https://cdn.example.com/img/a.png'),
    'https://cdn.example.com/img/a.png',
  );
  assert.equal(normalizeAssetUrl('/admin-api/infra/file/1/a.png'), '/admin-api/infra/file/1/a.png');
  assert.equal(
    normalizeAssetUrl('https://ytcy.nat100.top/admin-api/a.png'),
    'https://ytcy.nat100.top/admin-api/a.png',
  );
});

test('normalizeAssetUrl：空值 / 空白 / undefined → 空串', () => {
  assert.equal(normalizeAssetUrl(undefined), '');
  assert.equal(normalizeAssetUrl(null), '');
  assert.equal(normalizeAssetUrl('   '), '');
});

test('normalizeAssetUrl：公网 IP（非私网段）不被误改写', () => {
  assert.equal(normalizeAssetUrl('http://8.8.8.8/a.png'), 'http://8.8.8.8/a.png');
  assert.equal(normalizeAssetUrl('http://11.0.0.1/a.png'), 'http://11.0.0.1/a.png');
});
