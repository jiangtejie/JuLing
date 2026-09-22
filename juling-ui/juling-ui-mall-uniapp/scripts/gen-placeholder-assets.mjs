/**
 * 生成商城前端缺失的占位图资源
 * ------------------------------------------------------------------
 * 背景：本项目沿用了上游 shopro 的代码，但仓库里 `static/img/shop/**` 整棵目录缺失，
 * 代码中有约 25 处引用它（订单状态、支付渠道、分享、钱包、工具菜单、默认头像、海报底图等），
 * 运行时会显示成裂图。本脚本用自绘的简单几何图形一次性补出全部占位资源。
 *
 * 这些是**占位素材**，不是品牌素材：
 *   - 支付/登录渠道图标（微信、支付宝、Apple Pay）用中性色块 + 单字/符号表示，
 *     未使用任何厂商商标，正式上线前请替换为官方素材；
 *   - 轮播图、海报底图为纯装饰渐变，请替换为真实运营素材；
 *   - 其余为通用功能图标（房子/购物车/人像/票据…），可长期使用或按品牌风格替换。
 *
 * 依赖与运行（resvg 仅用于生成图片，未加入 package.json，避免污染前端依赖）：
 *   npm i -D @resvg/resvg-js
 *   node scripts/gen-placeholder-assets.mjs
 * 若脚本不在项目内运行，用 JULING_ROOT 指定项目根目录：
 *   JULING_ROOT=D:\\path\\juling-ui-mall-uniapp node gen-placeholder-assets.mjs
 */

import fs from 'node:fs';
import path from 'node:path';

let Resvg;
try {
  ({ Resvg } = await import('@resvg/resvg-js'));
} catch {
  console.error('缺少依赖，请先执行： npm i -D @resvg/resvg-js');
  process.exit(1);
}

const ROOT = process.env.JULING_ROOT || path.resolve(process.cwd());
const FONT_FILES = ['C:/Windows/Fonts/msyh.ttc', 'C:/Windows/Fonts/msyhbd.ttc'];
const FONT_FAMILY = 'Microsoft YaHei';

// ============ 通用小工具 ============
const svg24 = (inner, w, h) =>
  '<svg xmlns="http://www.w3.org/2000/svg" width="' + w + '" height="' + h + '" viewBox="0 0 24 24">' + inner + '</svg>';

const icon = (name, color, size) => svg24(ICONS[name](color), size, size);

const rect = (x, y, w, h, r, fill) =>
  '<rect x="' + x + '" y="' + y + '" width="' + w + '" height="' + h + '" rx="' + r + '" fill="' + fill + '"/>';

const circle = (cx, cy, r, fill) =>
  '<circle cx="' + cx + '" cy="' + cy + '" r="' + r + '" fill="' + fill + '"/>';

const text = (x, y, size, fill, content, weight) =>
  '<text x="' + x + '" y="' + y + '" font-size="' + size + '" font-weight="' + (weight || 'bold') +
  '" font-family="' + FONT_FAMILY + '" fill="' + fill + '" text-anchor="middle">' + content + '</text>';

const linear = (id, from, to, x2, y2) =>
  '<linearGradient id="' + id + '" x1="0" y1="0" x2="' + (x2 || 1) + '" y2="' + (y2 || 1) + '">' +
  '<stop offset="0" stop-color="' + from + '"/><stop offset="1" stop-color="' + to + '"/></linearGradient>';

// ============ 自绘图标库（24 x 24 视野）============
const ICONS = {
  home: (c) => '<path fill-rule="evenodd" fill="' + c + '" d="M12 2.3 1.6 10.9h2.9v10.4h14.9V10.9h2.9zM14 19.4h-4v-5.3h4z"/>',
  grid: (c) =>
    rect(2.4, 2.4, 8.2, 8.2, 2, c) + rect(13.4, 2.4, 8.2, 8.2, 2, c) +
    rect(2.4, 13.4, 8.2, 8.2, 2, c) + rect(13.4, 13.4, 8.2, 8.2, 2, c),
  cart: (c) =>
    '<path fill="' + c + '" d="M1.9 3h2.4c.5 0 1 .4 1.1.9l.5 2H21c.8 0 1.3.7 1.1 1.4l-1.9 6.8c-.1.5-.6.9-1.1.9H7.4c-.5 0-1-.4-1.1-.9L4.1 5.2H1.9z"/>' +
    circle(8.4, 19.6, 2, c) + circle(17.6, 19.6, 2, c),
  user: (c) => circle(12, 8, 4.3, c) + '<path fill="' + c + '" d="M3.8 20.8c0-4 3.7-6.6 8.2-6.6s8.2 2.6 8.2 6.6z"/>',
  search: (c) =>
    '<circle cx="10.5" cy="10.5" r="6.6" fill="none" stroke="' + c + '" stroke-width="2.3"/>' +
    '<path d="M15.4 15.4 21 21" stroke="' + c + '" stroke-width="2.3" stroke-linecap="round"/>',
  eye: (c) =>
    '<path d="M12 5.2C6.6 5.2 2.5 9.5 1.3 12c1.2 2.5 5.3 6.8 10.7 6.8S21.5 14.5 22.7 12C21.5 9.5 17.4 5.2 12 5.2z" fill="none" stroke="' + c + '" stroke-width="2"/>' +
    circle(12, 12, 3.2, c),
  star: (c) => '<path fill="' + c + '" d="M12 2.4l3 6 6.6.9-4.8 4.6 1.2 6.6L12 17.4l-5.9 3.1 1.2-6.6L2.5 9.3 9.1 8.4z"/>',
  service: (c) =>
    '<path d="M4.6 13.4v-1.6a7.4 7.4 0 0 1 14.8 0v1.6" fill="none" stroke="' + c + '" stroke-width="2.2" stroke-linecap="round"/>' +
    rect(2.2, 12.2, 4.4, 6.6, 2.2, c) + rect(17.4, 12.2, 4.4, 6.6, 2.2, c) +
    '<path d="M19.6 18.8c0 1.7-1.8 2.8-3.8 2.8" fill="none" stroke="' + c + '" stroke-width="2.2" stroke-linecap="round"/>',
  wallet: (c) =>
    rect(2.4, 5, 19.2, 14.2, 2.8, c) + circle(17, 12.1, 2, '#ffffff'),
  box: (c) =>
    '<path d="M12 2.4 21.2 7v10.2L12 21.6 2.8 17.2V7z" fill="none" stroke="' + c + '" stroke-width="2"/>' +
    '<path d="M2.9 7.1 12 11.5l9.1-4.4M12 11.5v9.7" fill="none" stroke="' + c + '" stroke-width="2"/>',
  pen: (c) =>
    '<path fill="' + c + '" d="M3.6 17.6 15.1 6.1l3 3L6.6 20.6H3.6z"/>' +
    '<path fill="' + c + '" d="M16.5 4.7 18 3.2a1.6 1.6 0 0 1 2.3 0l1.5 1.5a1.6 1.6 0 0 1 0 2.3l-1.5 1.5z"/>',
  refresh: (c) =>
    '<path d="M20.2 12.2a8.2 8.2 0 1 1-2.7-6.1" fill="none" stroke="' + c + '" stroke-width="2.2" stroke-linecap="round"/>' +
    '<path fill="' + c + '" d="M20.6 2.6v5.7h-5.7z"/>',
  list: (c) => rect(2.8, 4.2, 18.4, 2.7, 1.35, c) + rect(2.8, 10.7, 18.4, 2.7, 1.35, c) + rect(2.8, 17.1, 18.4, 2.7, 1.35, c),
  ticket: (c) =>
    '<path fill-rule="evenodd" fill="' + c + '" d="M2.9 5.2h18.2a1.1 1.1 0 0 1 1.1 1.1v3.3a2.4 2.4 0 0 0 0 4.8v3.3a1.1 1.1 0 0 1-1.1 1.1H2.9a1.1 1.1 0 0 1-1.1-1.1v-3.3a2.4 2.4 0 0 0 0-4.8V6.3A1.1 1.1 0 0 1 2.9 5.2z"/>',
  coin: (c) =>
    '<circle cx="12" cy="12" r="9" fill="none" stroke="' + c + '" stroke-width="2"/>' +
    '<path fill="' + c + '" d="M12 6.4l1.9 3.7 3.7.6-2.7 2.6.7 3.7-3.6-1.9-3.6 1.9.7-3.7-2.7-2.6 3.7-.6z"/>',
  camera: (c) =>
    rect(2.4, 6.4, 19.2, 13, 3, c) + '<path fill="' + c + '" d="M8.5 6.4 9.9 4h4.2l1.4 2.4z"/>' +
    circle(12, 12.9, 3.6, '#ffffff'),
  wifioff: (c) =>
    '<path d="M2.4 8.6a14.4 14.4 0 0 1 8.3-3.3M15.1 5.8a14.4 14.4 0 0 1 6.5 2.8" fill="none" stroke="' + c + '" stroke-width="2.3" stroke-linecap="round"/>' +
    '<path d="M6.2 12.6a9.4 9.4 0 0 1 4.3-1.6M14.6 11.3a9.4 9.4 0 0 1 3.2 1.3" fill="none" stroke="' + c + '" stroke-width="2.3" stroke-linecap="round"/>' +
    '<path d="M9.7 16.4a4.6 4.6 0 0 1 4.6.1" fill="none" stroke="' + c + '" stroke-width="2.3" stroke-linecap="round"/>' +
    circle(12, 20, 1.6, c) +
    '<path d="M3.4 3.4 20.6 20.6" stroke="' + c + '" stroke-width="2.3" stroke-linecap="round"/>',
  play: (c) =>
    '<circle cx="12" cy="12" r="9.2" fill="none" stroke="' + c + '" stroke-width="2"/>' +
    '<path fill="' + c + '" d="M10 8.1 16.5 12 10 15.9z"/>',
  live: (c) =>
    '<circle cx="12" cy="12" r="9.2" fill="none" stroke="' + c + '" stroke-width="2"/>' +
    circle(12, 12, 3.4, c) +
    '<path d="M6.6 6.6a7.6 7.6 0 0 0 0 10.8M17.4 6.6a7.6 7.6 0 0 1 0 10.8" fill="none" stroke="' + c + '" stroke-width="1.8" stroke-linecap="round"/>',
  stop: (c) =>
    '<circle cx="12" cy="12" r="9.2" fill="none" stroke="' + c + '" stroke-width="2"/>' +
    rect(9, 9, 6, 6, 1.4, c),
  chat: (c) =>
    '<path fill="' + c + '" d="M12 3.2C6.9 3.2 2.8 6.5 2.8 10.6c0 2.4 1.4 4.5 3.6 5.9l-.9 3.6 3.9-2c.8.2 1.7.3 2.6.3 5.1 0 9.2-3.3 9.2-7.8S17.1 3.2 12 3.2z"/>' +
    circle(8.4, 10.6, 1.15, '#ffffff') + circle(12, 10.6, 1.15, '#ffffff') + circle(15.6, 10.6, 1.15, '#ffffff'),
  link: (c) =>
    '<path d="M9.5 14.5a4.7 4.7 0 0 0 6.6 0l2.9-2.9a4.7 4.7 0 0 0-6.6-6.6L11.2 6.2" fill="none" stroke="' + c + '" stroke-width="2.2" stroke-linecap="round"/>' +
    '<path d="M14.5 9.5a4.7 4.7 0 0 0-6.6 0l-2.9 2.9a4.7 4.7 0 0 0 6.6 6.6l1.2-1.2" fill="none" stroke="' + c + '" stroke-width="2.2" stroke-linecap="round"/>',
  image: (c) =>
    rect(2.6, 4.6, 18.8, 14.8, 2.6, c) +
    circle(8.3, 9.8, 1.9, '#ffffff') +
    '<path fill="#ffffff" d="M5 17.4 10 12.4l2.9 2.8 2.7-2.4 3.4 4.6z"/>',
  card: (c) => rect(2.2, 5, 19.6, 14, 2.8, c) + rect(2.2, 8.4, 19.6, 2.6, 0, '#ffffff'),
};

// ============ 资源清单 ============
const ASSETS = [];

const IMG = 'static/img/shop/';

// —— 默认头像 / 网络异常 / 上传相机 ——
ASSETS.push([IMG + 'default_avatar.png', svg24(
  '<rect width="24" height="24" fill="#f2f3f5"/>' + circle(12, 9.4, 4, '#c9ced6') +
  '<path fill="#c9ced6" d="M4.6 24c0-4.1 3.3-6.6 7.4-6.6s7.4 2.5 7.4 6.6z"/>', 240, 240)]);

ASSETS.push([IMG + 'empty_network.png', svg24(
  circle(12, 12, 11.4, '#f2f3f5') + ICONS.wifioff('#b6bcc6'), 360, 360)]);

ASSETS.push([IMG + 'upload-camera.png', svg24(ICONS.camera('#8b93a1'), 120, 120)]);

// —— 商品相关 ——
ASSETS.push([IMG + 'goods/score1.svg', svg24(ICONS.coin('#ff6000'), 48, 48)]);

ASSETS.push([IMG + 'goods/groupon-tag-white.png',
  '<svg xmlns="http://www.w3.org/2000/svg" width="132" height="44" viewBox="0 0 132 44">' +
  rect(0, 0, 132, 44, 22, '#ffffff') + text(66, 30, 22, '#ff3000', '拼团') + '</svg>']);

ASSETS.push([IMG + 'goods/groupon-btn-long.png',
  '<svg xmlns="http://www.w3.org/2000/svg" width="690" height="96" viewBox="0 0 690 96">' +
  '<defs>' + linear('g', '#ff6000', '#fe832a') + '</defs>' +
  rect(0, 0, 690, 96, 48, 'url(#g)') + '</svg>']);

// —— 订单状态 ——
const orderIcon = (name, color) => [IMG + 'order/' + name + '.png', svg24(ICONS[ORDER_GLYPH[name]](color), 108, 108)];
const ORDER_GLYPH = {
  no_pay: 'wallet', no_take: 'box', no_comment: 'pen', change_order: 'refresh', all_order: 'list',
  nouse_coupon: 'ticket', useend_coupon: 'ticket', out_coupon: 'ticket', all_coupon: 'ticket',
};
ASSETS.push(orderIcon('no_pay', '#ff6000'));
ASSETS.push(orderIcon('no_take', '#3b82f6'));
ASSETS.push(orderIcon('no_comment', '#22c55e'));
ASSETS.push(orderIcon('change_order', '#8b5cf6'));
ASSETS.push(orderIcon('all_order', '#64748b'));
ASSETS.push(orderIcon('nouse_coupon', '#ff6000'));
ASSETS.push(orderIcon('useend_coupon', '#cbd5e1'));
ASSETS.push(orderIcon('out_coupon', '#cbd5e1'));
ASSETS.push(orderIcon('all_coupon', '#fc4141'));

// —— 支付渠道（占位：中性色块 + 单字/符号，未使用厂商商标）——
const tile = (size, bg, inner) =>
  '<svg xmlns="http://www.w3.org/2000/svg" width="' + size + '" height="' + size + '" viewBox="0 0 ' + size + ' ' + size + '">' +
  rect(0, 0, size, size, size * 0.24, bg) + inner + '</svg>';

const tileChar = (size, bg, ch) => tile(size, bg, text(size / 2, size * 0.69, size * 0.54, '#ffffff', ch));
const tileGlyph = (size, bg, glyph, color) =>
  tile(size, bg, '<g transform="translate(' + size * 0.2 + ',' + size * 0.2 + ') scale(' + (size * 0.6) / 24 + ')">' +
    ICONS[glyph](color) + '</g>');

ASSETS.push([IMG + 'pay/wechat.png', tileGlyph(96, '#07c160', 'chat', '#ffffff')]);
ASSETS.push([IMG + 'pay/alipay.png', tileChar(96, '#1677ff', '支')]);
ASSETS.push([IMG + 'pay/wallet.png', svg24(ICONS.wallet('#ff6000'), 96, 96)]);
ASSETS.push([IMG + 'pay/apple.png', tileGlyph(96, '#1f2937', 'card', '#ffffff')]);
ASSETS.push([IMG + 'platform/wechat.png', tileGlyph(96, '#07c160', 'chat', '#ffffff')]);
ASSETS.push([IMG + 'platform/apple.png', tileGlyph(96, '#1f2937', 'card', '#ffffff')]);

// —— 分享 ——
ASSETS.push([IMG + 'share/share_wx.png', tileGlyph(120, '#07c160', 'chat', '#ffffff')]);
ASSETS.push([IMG + 'share/share_poster.png', svg24(ICONS.image('#ff6000'), 120, 120)]);
ASSETS.push([IMG + 'share/share_link.png', svg24(ICONS.link('#3b82f6'), 120, 120)]);
ASSETS.push([IMG + 'share/share_guide.png',
  '<svg xmlns="http://www.w3.org/2000/svg" width="750" height="750" viewBox="0 0 750 750">' +
  '<path d="M690 120c-120 0-210 20-300 90-70 55-120 130-150 220" fill="none" stroke="#ffffff" stroke-width="14" stroke-linecap="round" stroke-dasharray="26 20"/>' +
  '<path fill="#ffffff" d="M690 78l58 44-70 18z"/>' +
  text(375, 500, 40, '#ffffff', '点击右上角 · 分享给朋友') +
  text(375, 566, 30, '#ffffff', '或保存图片后转发') + '</svg>']);

// —— 快捷菜单工具 ——
const TOOLS = [['home', '#ff6000'], ['search', '#3b82f6'], ['user', '#22c55e'], ['cart', '#fc4141'],
  ['browse', '#8b5cf6'], ['collect', '#f59e0b'], ['service', '#06b6d4']];
for (const t of TOOLS) {
  const glyph = t[0] === 'browse' ? 'eye' : t[0] === 'collect' ? 'star' : t[0];
  ASSETS.push([IMG + 'tools/' + t[0] + '.png', svg24(ICONS[glyph](t[1]), 108, 108)]);
}

// —— 钱包 / 地址 / 直播 / 旧购物车图标 ——
ASSETS.push([IMG + 'user/wallet_icon.png', svg24(ICONS.wallet('#ff6000'), 96, 96)]);
ASSETS.push([IMG + 'user/address/edit.png', svg24(ICONS.pen('#8b93a1'), 72, 72)]);
ASSETS.push([IMG + 'app/mplive/living.png', svg24(ICONS.live('#fc4141'), 108, 108)]);
ASSETS.push([IMG + 'app/mplive/start.png', svg24(ICONS.play('#22c55e'), 108, 108)]);
ASSETS.push([IMG + 'app/mplive/ended.png', svg24(ICONS.stop('#9aa3af'), 108, 108)]);
ASSETS.push([IMG + 'tabbar/category2.png', svg24(ICONS.cart('#ffffff'), 96, 96)]);

// —— 海报底图（画布约 337 x 600，故取 9:16）——
const posterBg = (id, from, to, accent) =>
  '<svg xmlns="http://www.w3.org/2000/svg" width="750" height="1334" viewBox="0 0 750 1334">' +
  '<defs>' + linear(id, from, to, 0.4, 1) + '</defs>' +
  '<rect width="750" height="1334" fill="url(#' + id + ')"/>' +
  circle(640, 120, 190, accent) + circle(90, 470, 130, accent) +
  rect(0, 1000, 750, 334, 0, 'rgba(255,255,255,0.92)') + '</svg>';

ASSETS.push([IMG + 'config/user-poster-bg.png', posterBg('up', '#ffe6e0', '#ffd0c4', 'rgba(255,255,255,0.34)')]);
ASSETS.push([IMG + 'config/goods-poster-bg.png', posterBg('gp', '#fff3e0', '#ffe0b8', 'rgba(255,255,255,0.36)')]);
ASSETS.push([IMG + 'config/groupon-poster-bg.png', posterBg('cb', '#ffe8ea', '#ffced4', 'rgba(255,255,255,0.34)')]);

// —— 装修模板：底部导航（常态 #282828 / 选中 #fc4141）——
const TABBAR = [['home', 'home'], ['category', 'grid'], ['cart', 'cart'], ['user', 'user']];
for (const t of TABBAR) {
  ASSETS.push(['static/img/tabbar/' + t[0] + '.png', svg24(ICONS[t[1]]('#282828'), 96, 96)]);
  ASSETS.push(['static/img/tabbar/' + t[0] + '-active.png', svg24(ICONS[t[1]]('#fc4141'), 96, 96)]);
}

// —— 装修模板：宫格导航 ——
ASSETS.push(['static/img/menu/goods.png', svg24(ICONS.cart('#ff6000'), 120, 120)]);
ASSETS.push(['static/img/menu/coupon.png', svg24(ICONS.ticket('#fc4141'), 120, 120)]);
ASSETS.push(['static/img/menu/sign.png', svg24(ICONS.coin('#f59e0b'), 120, 120)]);
ASSETS.push(['static/img/menu/order.png', svg24(ICONS.list('#3b82f6'), 120, 120)]);

// —— 装修模板：轮播图（750 x 348，即 2 倍于 375 x 174）——
const banner = (id, from, to, title, sub) =>
  '<svg xmlns="http://www.w3.org/2000/svg" width="750" height="348" viewBox="0 0 750 348">' +
  '<defs>' + linear(id, from, to) + '</defs>' +
  '<rect width="750" height="348" fill="url(#' + id + ')"/>' +
  circle(660, 60, 150, 'rgba(255,255,255,0.16)') + circle(80, 320, 110, 'rgba(255,255,255,0.14)') +
  text(376, 172, 62, '#ffffff', title) + text(376, 236, 28, 'rgba(255,255,255,0.88)', sub, 'normal') + '</svg>';

ASSETS.push(['static/img/banner/banner-1.png',
  banner('b1', '#ff5a3c', '#ff9b56', '矩灵商城', '占位图 · 请在管理后台替换为运营素材')]);
ASSETS.push(['static/img/banner/banner-2.png',
  banner('b2', '#3b82f6', '#22d3ee', '精选好物', '占位图 · 请在管理后台替换为运营素材')]);

// ============ 渲染并写盘 ============
let ok = 0;
const failed = [];
for (const [rel, svg] of ASSETS) {
  const out = path.join(ROOT, rel);
  try {
    fs.mkdirSync(path.dirname(out), { recursive: true });
    if (rel.endsWith('.svg')) {
      fs.writeFileSync(out, svg, 'utf-8');
    } else {
      const resvg = new Resvg(svg, {
        font: { loadSystemFonts: true, fontFiles: FONT_FILES, defaultFontFamily: FONT_FAMILY },
        background: 'rgba(0,0,0,0)',
      });
      fs.writeFileSync(out, resvg.render().asPng());
    }
    ok++;
  } catch (e) {
    failed.push(rel + ' -> ' + e.message);
  }
}
console.log('生成完成：' + ok + ' / ' + ASSETS.length + ' 个文件，输出根目录 ' + ROOT);
if (failed.length) console.log('失败：\n' + failed.join('\n'));
