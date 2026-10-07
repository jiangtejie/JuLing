#!/usr/bin/env node
/**
 * 校验 sql/local 下的脚本能否被 DbTool 正确切分。
 *
 * 【为什么需要它】DbTool 按正则 ";\s*\r?\n" 切分语句，于是有两条隐含约定：
 *   1. 多行 `DO $$ ... $$;` 块会被切碎（块内部的 ";" 后面跟了换行）
 *      → 必须写成**一行**（54 号脚本正是如此，所以它一直能跑）
 *   2. 语句结尾的 ";" 后面**必须跟换行**
 * 这两条在真实开发里被反复踩（同一个脚本里踩过两次、另一个脚本又各踩一次），
 * 靠"记住"是没用的 —— 所以把它变成可执行的检查。
 *
 * 另外也检查 JS 侧改 SQL 时的经典坑：`String.replace` 的替换文本里 `$$` 是转义序列，
 * 会被吃成 `$`（表现为脚本里出现 `DO $ ... $`）。
 *
 * 用法：node script/tools/check-sql-scripts.mjs [目录，默认 sql/local]
 * 退出码：0 通过 / 1 有问题
 */
import { readdirSync, readFileSync, statSync } from 'node:fs';
import { join } from 'node:path';

const dir = process.argv[2] ?? 'sql/local';
const files = readdirSync(dir).filter((f) => f.endsWith('.sql')).sort();
const problems = [];

for (const f of files) {
  const path = join(dir, f);
  if (!statSync(path).isFile()) continue;
  const text = readFileSync(path, 'utf8');
  const lines = text.split(/\r?\n/);

  // 检查 1：`$$` 是否成对（出现 `DO $ ` 说明被 replace 吃过）
  const dollars = (text.match(/\$\$/g) ?? []).length;
  if (dollars % 2 !== 0) problems.push(`${f}: \`$$\` 出现 ${dollars} 次（不是偶数），可能是被 String.replace 吃掉了`);
  lines.forEach((l, i) => {
    if (/DO\s+\$\s+/.test(l) || /END\s+\$;/.test(l)) problems.push(`${f}:${i + 1}: 检测到 DO 单美元符（应为两个），可能是被 String.replace 吃掉了`);
  });

  // 检查 2：DO $$ 块必须在一行内闭合
  let inBlock = false;
  let blockStart = 0;
  lines.forEach((l, i) => {
    const opens = (l.match(/DO\s+\$\$/g) ?? []).length;
    const closes = (l.match(/END\s+\$\$/g) ?? []).length;
    if (opens > closes && !inBlock) { inBlock = true; blockStart = i + 1; }
    else if (closes > 0 && inBlock) { problems.push(`${f}:${blockStart}: DO $$ 块跨了 ${i + 1 - blockStart + 1} 行，必须写成一行（否则会被 DbTool 按 ";" 切碎）`); inBlock = false; }
  });
  if (inBlock) problems.push(`${f}:${blockStart}: DO $$ 块没有闭合`);

  // 检查 3：模拟 DbTool 的切分，报告切出来但不像完整语句的片段
  text.split(/;\s*\r?\n/).forEach((raw, i) => {
    const s = raw.replace(/^\s*--.*$/gm, '').trim();
    if (!s) return;
    if (s.startsWith('END $$') || s.startsWith('END IF') || s === '$$') {
      problems.push(`${f}: 切分后第 ${i + 1} 段是残片「${s.slice(0, 40)}」—— 说明有语句被切碎`);
    }
  });
}

if (problems.length === 0) {
  console.log(`✓ ${files.length} 个脚本全部通过（DO 块单行、$$ 成对、可按 ";" + 换行 正确切分）`);
  process.exit(0);
}
console.log(`✗ 发现 ${problems.length} 处问题：`);
for (const p of problems) console.log('  ' + p);
process.exit(1);
