#!/usr/bin/env node
/**
 * uni-app CLI 启动包装（CommonJS，可直接 node 执行）
 *
 * 背景：本项目沿用 HBuilderX 的**扁平目录结构**（manifest.json、pages.json 都在项目根目录），
 * 而 uni CLI 在没有 UNI_INPUT_DIR 时默认把源码目录当成 <项目根>/src：
 *   @dcloudio/vite-plugin-uni/dist/cli/utils.js
 *   process.env.UNI_INPUT_DIR = process.env.UNI_INPUT_DIR || path.resolve(process.cwd(), 'src')
 * 于是会报 ENOENT: .../src/manifest.json。
 *
 * 这里显式把源码根目录指向项目根，同时保持 pnpm dev:h5 这类命令的用法不变。
 * 采用同进程 require（而非 spawn 子进程），避免中断时留下占用端口的孤儿进程。
 */
const path = require('path');

const projectRoot = path.resolve(__dirname, '..');

// 显式指定源码目录与 Vite 根目录（允许外部覆盖）
process.env.UNI_INPUT_DIR = process.env.UNI_INPUT_DIR || projectRoot;
process.env.VITE_ROOT_DIR = process.env.VITE_ROOT_DIR || projectRoot;

require(path.join(projectRoot, 'node_modules', '@dcloudio', 'vite-plugin-uni', 'bin', 'uni.js'));
