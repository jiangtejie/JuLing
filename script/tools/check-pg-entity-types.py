# -*- coding: utf-8 -*-
"""交叉校验 PostgreSQL 列类型与 Java 实体字段类型，找出会报
"column X is of type A but expression is of type B" 的映射。

规则：
  - boolean 列  ↔  Boolean  正常；映射成 Integer/Long/String 等 → 风险
  - smallint 列 ↔  Integer/int 正常；映射成 Boolean → 风险
  - 其它类型不做判断（结构上兼容）

用法：python script/local/check_pg_type_mapping.py
"""
import os
import re
import subprocess

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

# 1) 从数据库取列类型
#    psql 命令前缀：CI 用 JULING_PSQL_CONN（连接串）或 JULING_PSQL_CMD（完整命令），本地默认走 docker
_conn = os.environ.get('JULING_PSQL_CONN')
if _conn:
    PSQL = ['psql', _conn]
elif os.environ.get('JULING_PSQL_CMD'):
    PSQL = os.environ['JULING_PSQL_CMD'].split()
else:
    PSQL = ['docker', 'exec', 'postgres', 'psql', '-U', 'root', '-d', 'juling']

sql = """
SELECT table_name || '|' || column_name || '|' || data_type
FROM information_schema.columns
WHERE table_schema = 'public' AND data_type IN ('boolean', 'smallint', 'int2', 'integer', 'bigint')
ORDER BY table_name, column_name;
"""
out = subprocess.run(PSQL + ['-tAc', sql],
                     capture_output=True, text=True, encoding='utf-8')
cols = {}
for line in (out.stdout or '').splitlines():
    line = line.strip()
    if not line or '|' not in line:
        continue
    table, column, dtype = line.split('|')
    cols.setdefault(table, {})[column] = dtype

# 2) 解析实体类
files = subprocess.run(['git', 'ls-files', '*DO.java'], cwd=ROOT, capture_output=True)
do_files = files.stdout.decode('utf-8', 'replace').splitlines()

table_re = re.compile(r'@TableName\(\s*(?:value\s*=\s*)?"([^"]+)"')
field_re = re.compile(r'@TableField\(\s*(?:value\s*=\s*)?"([^"]+)"[^)]*\)\s*(?:private|protected|public)\s+([A-Za-z0-9_<>.]+)\s+(\w+)\s*;')
plain_field_re = re.compile(r'^\s*private\s+([A-Za-z0-9_<>.]+)\s+(\w+)\s*;')

risks = []
for rel in do_files:
    path = os.path.join(ROOT, rel.replace('/', os.sep))
    try:
        with open(path, encoding='utf-8') as f:
            text = f.read()
    except (OSError, UnicodeDecodeError):
        continue
    m = table_re.search(text)
    if not m:
        continue
    table = m.group(1)
    table_cols = cols.get(table)
    if not table_cols:
        continue
    fields = {}
    # 显式 @TableField("col") 的字段
    for cm, ctype, cname in field_re.findall(text):
        fields[cname] = (cm, ctype)
    # 普通字段：列名按驼峰转下划线推断
    for ctype, cname in plain_field_re.findall(text):
        if cname in fields:
            continue
        col = re.sub(r'(?<!^)(?=[A-Z])', '_', cname).lower()
        fields[cname] = (col, ctype)

    for fname, (col, ctype) in fields.items():
        dtype = table_cols.get(col)
        if dtype is None:
            continue
        simple = ctype.split('<')[0]
        if dtype == 'boolean' and simple != 'Boolean':
            risks.append('%s : %s.%s 是 boolean，Java 字段 %s 为 %s（应为 Boolean）'
                         % (rel, table, col, fname, simple))
        elif dtype in ('smallint', 'int2') and simple == 'Boolean':
            risks.append('%s : %s.%s 是 %s，Java 字段 %s 为 Boolean（应为 Integer）'
                         % (rel, table, col, dtype, fname))

print('实体类扫描: %d 个，列类型风险: %d 处' % (len(do_files), len(risks)))
for r in risks:
    print('  ' + r)
