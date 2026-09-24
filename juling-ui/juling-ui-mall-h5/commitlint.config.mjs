/** 提交信息规范：Conventional Commits */
export default {
  extends: ['@commitlint/config-conventional'],
  rules: {
    // type 枚举：feat 新功能 / fix 缺陷 / docs 文档 / style 格式 / refactor 重构
    // perf 性能 / test 测试 / build 构建 / ci 流水线 / chore 杂项 / revert 回滚
    'type-enum': [
      2,
      'always',
      [
        'feat',
        'fix',
        'docs',
        'style',
        'refactor',
        'perf',
        'test',
        'build',
        'ci',
        'chore',
        'revert',
      ],
    ],
    'subject-empty': [2, 'never'],
    'subject-full-stop': [0, 'never'],
    // 中文提交信息不强制小写
    'subject-case': [0],
    'header-max-length': [2, 'always', 100],
  },
};
