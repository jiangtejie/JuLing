# -*- coding: utf-8 -*-
"""校验已跟踪 markdown 中引用的"仓库内路径"是否真实存在。

用法：python script/tools/check-doc-links.py
输出：`文件 -> 缺失引用`，无输出即全部有效。

检查两类引用：
  1. markdown 链接目标   [文字](路径)
  2. 反引号里的文件路径  `path/to/file.ext`

跳过：http(s)/mailto/锚点/绝对路径/通配符；只在扩展名白名单内检查反引号内容，
避免把 `uni.request`、版本号这类代码片段误判为路径。
"""
import os
import re
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SKIP_PREFIX = ('http://', 'https://', 'mailto:', '#', 'data:', '/', 'D:', 'C:', '~')
EXTS = ('.md', '.sql', '.ps1', '.sh', '.py', '.yaml', '.yml', '.xml', '.json',
        '.ts', '.vue', '.js', '.txt', '.java', '.properties', '.conf', '.html')
# 第三方 vendored 目录：其文档里的相对链接不属于本仓库，跳过
SKIP_MD_PARTS = ('/uni_modules/', '/sheep/', '/node_modules/', '/dist/')

MD_LINK = re.compile(r'\]\(([^)\s]+)\)')
CODE_PATH = re.compile(r'`([A-Za-z0-9_\-./]+\.[A-Za-z0-9]{1,8})`')


def git(*args):
    out = subprocess.run(['git'] + list(args), cwd=ROOT, capture_output=True)
    return out.stdout.decode('utf-8', 'replace').splitlines()


def main():
    tracked = set(git('ls-files'))
    basenames = set(os.path.basename(t) for t in tracked)
    mds = [p for p in tracked if p.endswith('.md')
           and not any(part in '/' + p for part in SKIP_MD_PARTS)]
    missing = []
    for rel in mds:
        try:
            with open(os.path.join(ROOT, rel), encoding='utf-8') as f:
                text = f.read()
        except (OSError, UnicodeDecodeError):
            continue
        refs = set(m.group(1).split('#')[0] for m in MD_LINK.finditer(text))
        for m in CODE_PATH.finditer(text):
            ref = m.group(1)
            if ref.endswith(EXTS) and '/' in ref:
                refs.add(ref)
        for ref in refs:
            ref = ref.strip()
            if not ref or ref.startswith(SKIP_PREFIX) or '*' in ref:
                continue
            if ref.startswith('./'):
                ref = ref[2:]
            candidates = [os.path.normpath(os.path.join(os.path.dirname(rel), ref)).replace('\\', '/'), ref]
            # 也允许按 basename 命中（文档常只写文件名）
            if not any(c in tracked or os.path.exists(os.path.join(ROOT, c)) for c in candidates) \
                    and os.path.basename(ref) not in basenames:
                missing.append((rel, ref))

    print('检查 markdown 文件: %d 个' % len(mds))
    if not missing:
        print('OK：未发现指向不存在文件的引用')
        return 0
    print('发现 %d 处可疑引用：' % len(missing))
    for rel, ref in missing:
        print('  %s  ->  %s' % (rel, ref))
    return 1


if __name__ == '__main__':
    sys.exit(main())
