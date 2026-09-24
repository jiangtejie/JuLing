/**
 * 生成 PWA / favicon 图标（零依赖，纯 Node 实现 PNG 编码）。
 * 图标元素：圆角方形底色（品牌蓝渐变）+ 白色购物袋。
 * 重新生成：pnpm gen:icons
 */
import { deflateSync } from 'node:zlib';
import { mkdirSync, writeFileSync } from 'node:fs';
import path from 'node:path';
import process from 'node:process';

const BRAND_TOP = [0, 129, 255]; // #0081ff
const BRAND_BOTTOM = [58, 160, 255];

const CRC_TABLE = (() => {
  const table = new Int32Array(256);
  for (let n = 0; n < 256; n++) {
    let c = n;
    for (let k = 0; k < 8; k++) c = c & 1 ? 0xedb88320 ^ (c >>> 1) : c >>> 1;
    table[n] = c;
  }
  return table;
})();

function crc32(buf) {
  let c = 0xffffffff;
  for (let i = 0; i < buf.length; i++) c = CRC_TABLE[(c ^ buf[i]) & 0xff] ^ (c >>> 8);
  return (c ^ 0xffffffff) >>> 0;
}

function chunk(type, data) {
  const len = Buffer.alloc(4);
  len.writeUInt32BE(data.length, 0);
  const body = Buffer.concat([Buffer.from(type, 'ascii'), data]);
  const crc = Buffer.alloc(4);
  crc.writeUInt32BE(crc32(body), 0);
  return Buffer.concat([len, body, crc]);
}

function encodePng(width, height, rgba) {
  const stride = width * 4;
  const raw = Buffer.alloc((stride + 1) * height);
  for (let y = 0; y < height; y++) {
    raw[y * (stride + 1)] = 0; // filter: None
    rgba.copy(raw, y * (stride + 1) + 1, y * stride, (y + 1) * stride);
  }
  const ihdr = Buffer.alloc(13);
  ihdr.writeUInt32BE(width, 0);
  ihdr.writeUInt32BE(height, 4);
  ihdr[8] = 8; // bit depth
  ihdr[9] = 6; // RGBA
  return Buffer.concat([
    Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]),
    chunk('IHDR', ihdr),
    chunk('IDAT', deflateSync(raw, { level: 9 })),
    chunk('IEND', Buffer.alloc(0)),
  ]);
}

/** 圆角矩形内部判定（u/v 为 0..1 归一化坐标） */
function inRoundedRect(u, v, x0, y0, x1, y1, r) {
  if (u < x0 || u > x1 || v < y0 || v > y1) return false;
  const cx = Math.min(Math.max(u, x0 + r), x1 - r);
  const cy = Math.min(Math.max(v, y0 + r), y1 - r);
  return (u - cx) ** 2 + (v - cy) ** 2 <= r * r;
}

/** 购物袋形状判定 */
function inBag(u, v) {
  // 袋身
  if (inRoundedRect(u, v, 0.275, 0.4, 0.725, 0.8, 0.07)) return true;
  // 提手（上半圆环）
  const dx = u - 0.5;
  const dy = v - 0.43;
  if (dy <= 0) {
    const d = Math.hypot(dx, dy);
    if (d >= 0.085 && d <= 0.135) return true;
  }
  return false;
}

function render(size, { maskable = false, radiusRatio = 0.22 } = {}) {
  const ss = 3; // 3x 超采样抗锯齿
  const out = Buffer.alloc(size * size * 4);
  const scale = maskable ? 0.62 : 1;

  for (let y = 0; y < size; y++) {
    for (let x = 0; x < size; x++) {
      let bgHits = 0;
      let bagHits = 0;
      for (let sy = 0; sy < ss; sy++) {
        for (let sx = 0; sx < ss; sx++) {
          const u = (x + (sx + 0.5) / ss) / size;
          const v = (y + (sy + 0.5) / ss) / size;
          // 背景
          const bgOk = maskable ? true : inRoundedRect(u, v, 0, 0, 1, 1, radiusRatio);
          if (bgOk) bgHits++;
          // 前景（购物袋，按 maskable 缩放）
          const bu = (u - 0.5) / scale + 0.5;
          const bv = (v - 0.5) / scale + 0.5;
          if (inBag(bu, bv)) bagHits++;
        }
      }

      const total = ss * ss;
      const bgA = bgHits / total;
      const bagA = bagHits / total;
      const t = y / size;
      const bg = [
        Math.round(BRAND_TOP[0] + (BRAND_BOTTOM[0] - BRAND_TOP[0]) * t),
        Math.round(BRAND_TOP[1] + (BRAND_BOTTOM[1] - BRAND_TOP[1]) * t),
        Math.round(BRAND_TOP[2] + (BRAND_BOTTOM[2] - BRAND_TOP[2]) * t),
      ];
      const color = [
        Math.round(bg[0] + (255 - bg[0]) * bagA),
        Math.round(bg[1] + (255 - bg[1]) * bagA),
        Math.round(bg[2] + (255 - bg[2]) * bagA),
      ];
      const i = (y * size + x) * 4;
      out[i] = color[0];
      out[i + 1] = color[1];
      out[i + 2] = color[2];
      out[i + 3] = Math.round(Math.max(bgA, bagA) * 255);
    }
  }
  return encodePng(size, size, out);
}

const publicDir = path.resolve(process.cwd(), 'public');
mkdirSync(publicDir, { recursive: true });

const targets = [
  ['pwa-192x192.png', 192, {}],
  ['pwa-512x512.png', 512, {}],
  ['pwa-maskable-512x512.png', 512, { maskable: true }],
  ['apple-touch-icon.png', 180, { radiusRatio: 1 }],
];

for (const [name, size, opts] of targets) {
  const file = path.join(publicDir, name);
  writeFileSync(file, render(size, opts));
  console.log('generated', path.relative(process.cwd(), file));
}
