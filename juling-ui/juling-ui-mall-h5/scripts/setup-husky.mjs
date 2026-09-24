/**
 * Husky 安装守卫脚本。
 *
 * 背景：本工程位于 JuLing 单体仓库（D:/A_ERP/java17/JuLing）之内，
 * 而该仓库根目录已经通过 core.hooksPath 指向 script/git-hooks，
 * 直接执行 husky 会覆盖整个仓库的钩子配置，影响其它子工程。
 *
 * 因此：
 *  - 若本目录就是 Git 仓库根（独立仓库 / git init 之后）=> 正常安装 husky 钩子；
 *  - 若处于上层仓库的子目录中       => 只给出提示，不做任何破坏性改动，pnpm install 也不会失败。
 */
import { execFileSync } from 'node:child_process';
import path from 'node:path';
import process from 'node:process';

const cwd = process.cwd();
const rel = (p) => path.resolve(p).replace(/\\/g, '/').toLowerCase();

function git(args) {
  return execFileSync('git', args, {
    cwd,
    encoding: 'utf8',
    stdio: ['ignore', 'pipe', 'ignore'],
  }).trim();
}

function log(msg) {
  console.log(`\u001B[36m[husky]\u001B[0m ${msg}`);
}

try {
  const toplevel = git(['rev-parse', '--show-toplevel']);

  if (rel(toplevel) === rel(cwd)) {
    // 本工程即 Git 根目录，交给 husky 正常安装
    execFileSync('npx', ['--no-install', 'husky'], { cwd, stdio: 'inherit' });
    log('Git 钩子已安装到 .husky/_');
  } else {
    log('检测到本工程位于上层 Git 仓库的子目录中，已跳过 husky 自动安装。');
    log(`  Git 根目录：${toplevel}`);
    log(
      '  当前仓库的 core.hooksPath 为：' +
        (git(['config', '--get', 'core.hooksPath']) || '(未设置)'),
    );
    log('');
    log('  如需在本工程启用提交前校验，二选一：');
    log('    A. 把本工程作为独立仓库：git init && pnpm prepare');
    log('    B. 让本仓库统一使用本工程的钩子（会影响整个仓库，请与团队确认）：');
    log('       git config core.hooksPath juling-ui/juling-ui-mall-h5/.husky/_');
    log('');
    log('  未启用也不影响安装与构建，lint-staged / commitlint 仍可手动执行：');
    log('    pnpm exec lint-staged');
    log('    pnpm exec commitlint --from HEAD~1 --to HEAD');
  }
} catch (error) {
  log('跳过 husky 安装（' + (error?.message ?? error) + '）');
}
