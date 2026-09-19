# Git 钩子

## pre-commit:拦截大文件

仓库历史上曾因误提交 78MB 的安装包(`Mockitt-win32-x64-zh-1.1.7.exe`)导致历史体积膨胀,
已通过重写历史清理。为防再次发生,本目录提供按**文件体积**拦截的 pre-commit 钩子
(`.gitignore` 只能按名称/扩展名拦截,无法按大小拦截)。

### 启用(每个克隆者执行一次)

```bash
git config core.hooksPath script/git-hooks
```

### 默认阈值与调整

默认单文件上限 **5MB**,可用环境变量覆盖:

```bash
LARGE_FILE_LIMIT_MB=10 git commit -m "xxx"
```

### 确需提交大文件时

```bash
git commit --no-verify -m "xxx"      # 跳过本次检查
```

> 建议把大文件(安装包、演示视频、数据集、设计稿)放到对象存储或附件服务器,
> 代码中仅保存引用地址;确需纳入版本管理时使用 Git LFS。

### 已知的历史遗留大文件

钩子只拦截**新提交**。移动端模板自带的 3 个演示素材(`unocss.gif` 9.75MB、`10-ios.mp4` 5.57MB、
`auto-page.gif` 5.46MB)已随第三方文档目录从工作区移除;它们仍存在于**历史提交**中,
要让仓库彻底瘦身需要重写历史(参见本目录开头提到的清理方式)。
