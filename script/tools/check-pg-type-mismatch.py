# -*- coding: utf-8 -*-
"""检查 PostgreSQL 类型与 SQL 字面量不匹配的写法（会报 operator does not exist / 类型错误）。

检查两类：
  1) boolean 列 与 0/1 比较        → PostgreSQL 报 operator does not exist: boolean = integer
  2) smallint 列 与 TRUE/FALSE 比较 → PostgreSQL 报 operator does not exist: smallint = boolean

数据来源：数据库 information_schema（boolean / smallint 列名），扫描 *.java(含 SQL 的行)、*.xml、*.vm。

用法：python script/tools/check-pg-type-mismatch.py
"""
import os
import re
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))


def psql_cmd():
    """psql 命令前缀：CI 用 JULING_PSQL_CONN（连接串）或 JULING_PSQL_CMD（完整命令），本地默认走 docker。"""
    conn = os.environ.get('JULING_PSQL_CONN')
    if conn:
        return ['psql', conn]
    cmd = os.environ.get('JULING_PSQL_CMD')
    if cmd:
        return cmd.split()
    return ['docker', 'exec', 'postgres', 'psql', '-U', 'root', '-d', 'juling']


def db_columns(dtype):
    sql = ("SELECT DISTINCT column_name FROM information_schema.columns "
           "WHERE table_schema='public' AND data_type='%s'" % dtype)
    out = subprocess.run(psql_cmd() + ['-tAc', sql],
                         capture_output=True, text=True, encoding='utf-8')
    return [l.strip() for l in (out.stdout or '').splitlines() if l.strip()]


def tracked(*patterns):
    out = subprocess.run(['git', 'ls-files', *patterns], cwd=ROOT, capture_output=True)
    return out.stdout.decode('utf-8', 'replace').splitlines()


SQL_HINT = re.compile(r'\b(SELECT|INSERT|UPDATE|DELETE|FROM|WHERE|GROUP\s+BY|ORDER\s+BY|JOIN|setSql|apply|@Select|@Update)\b', re.I)
SKIP = ('node_modules/', 'dist/', 'target/', '/docs/', 'sql/mysql/', 'sql/oracle/', 'sql/dm/',
        'sql/kingbase/', 'sql/opengauss/', 'sql/highgo/', 'sql/sqlserver/')


def scan(cols, pattern_tpl, label):
    hits = []
    files = tracked('*.java') + tracked('*.xml') + tracked('*.vm')
    for rel in files:
        if any(s in '/' + rel for s in SKIP):
            continue
        try:
            with open(os.path.join(ROOT, rel.replace('/', os.sep)), encoding='utf-8') as f:
                lines = f.read().splitlines()
        except (OSError, UnicodeDecodeError):
            continue
        is_java = rel.endswith('.java')
        for idx, line in enumerate(lines, 1):
            if is_java and not SQL_HINT.search(line):
                continue
            stripped = line.strip()
            if stripped.startswith(('//', '*', '<!--', '#')):   # 注释行跳过
                continue
            for col in cols:
                if re.search(pattern_tpl.format(col=re.escape(col)), line, re.I):
                    hits.append((label, rel, idx, col, stripped[:130]))
    return hits


def main():
    bool_cols = db_columns('boolean')
    small_cols = db_columns('smallint')
    hits = []
    # boolean 列 = 0 / 1 （排除 true/false 写法）
    hits += scan(bool_cols, r'(?<![A-Za-z0-9_]){col}\s*(=|<>|!=)\s*[01](?![0-9])', 'boolean列与0/1比较')
    # smallint 列 = TRUE / FALSE
    hits += scan(small_cols, r'(?<![A-Za-z0-9_]){col}\s*(=|<>|!=)\s*(TRUE|FALSE)\b', 'smallint列与TRUE比较')

    print('boolean 列 %d 个、smallint 列 %d 个；可疑写法 %d 处' % (len(bool_cols), len(small_cols), len(hits)))
    for label, rel, idx, col, text in hits:
        print('  [%s] %s:%d (%s)\n      %s' % (label, rel, idx, col, text))
    return 1 if hits else 0


if __name__ == '__main__':
    sys.exit(main())
