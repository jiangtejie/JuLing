# -*- coding: utf-8 -*-
"""检查代码里引用的字典类型是否都在数据库中存在（缺失会导致下拉为空、导入模板异常等）。

做法：
  1. 从各模块的 *DictTypeConstants.java 收集 常量名 -> 字典类型值
  2. 扫描 ```@DictFormat(X)``` / ```@ExcelColumnSelect(dictType = X)``` 引用（含带类名前缀的写法）
  3. 与数据库 system_dict_type 比对，并统计每个字典的数据行数（0 行同样有问题）

用法：python script/tools/check-dict-coverage.py
"""
import os
import re
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))


def git(*args):
    out = subprocess.run(['git', *args], cwd=ROOT, capture_output=True)
    return out.stdout.decode('utf-8', 'replace').splitlines()


def db_dicts():
    sql = ("SELECT t.type || '|' || count(d.id) FROM system_dict_type t "
           "LEFT JOIN system_dict_data d ON d.dict_type = t.type AND d.deleted = 0 "
           "WHERE t.deleted = 0 GROUP BY t.type")
    # 本地默认走 docker 里的 postgres；CI 用 JULING_PSQL_CONN（连接串）或 JULING_PSQL_CMD（完整命令）
    conn = os.environ.get('JULING_PSQL_CONN')
    if conn:
        cmd = ['psql', conn]
    elif os.environ.get('JULING_PSQL_CMD'):
        cmd = os.environ['JULING_PSQL_CMD'].split()
    else:
        cmd = ['docker', 'exec', 'postgres', 'psql', '-U', 'root', '-d', 'juling']
    out = subprocess.run(cmd + ['-tAc', sql], capture_output=True, text=True, encoding='utf-8')
    result = {}
    for line in (out.stdout or '').splitlines():
        line = line.strip()
        if '|' in line:
            k, v = line.split('|')
            result[k] = int(v)
    return result


def main():
    # 1. 常量表
    const_re = re.compile(r'String\s+(\w+)\s*=\s*"([^"]+)"')
    consts = {}
    for rel in git('ls-files', '*DictTypeConstants.java'):
        try:
            with open(os.path.join(ROOT, rel.replace('/', os.sep)), encoding='utf-8') as f:
                for name, value in const_re.findall(f.read()):
                    consts[name] = value
        except (OSError, UnicodeDecodeError):
            continue

    # 2. 注解引用
    use_re = re.compile(r'@(?:DictFormat|ExcelColumnSelect)\s*\(\s*(?:dictType\s*=\s*)?"?([\w.]+)"?')
    used = {}
    for rel in git('ls-files', '*.java'):
        if '/test/' in rel:
            continue
        try:
            with open(os.path.join(ROOT, rel.replace('/', os.sep)), encoding='utf-8') as f:
                text = f.read()
        except (OSError, UnicodeDecodeError):
            continue
        for ref in use_re.findall(text):
            key = ref.split('.')[-1]
            value = consts.get(key) or (ref if '_' in ref and not ref.isupper() else None)
            if value:
                used.setdefault(value, set()).add(rel)

    db = db_dicts()
    missing = sorted(k for k in used if k not in db)
    empty = sorted(k for k in used if db.get(k) == 0)

    print('代码引用字典 %d 个；数据库字典 %d 个' % (len(used), len(db)))
    print('缺失(库中无此字典类型)：%d 个' % len(missing))
    for k in missing:
        print('  %s   ← %s' % (k, ', '.join(sorted(used[k]))[:110]))
    print('存在但无数据行：%d 个' % len(empty))
    for k in empty:
        print('  %s   ← %s' % (k, ', '.join(sorted(used[k]))[:110]))
    return 1 if (missing or empty) else 0


if __name__ == '__main__':
    sys.exit(main())
