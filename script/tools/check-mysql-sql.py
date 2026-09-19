# -*- coding: utf-8 -*-
"""扫描全仓 SQL 片段里的 MySQL 专有写法(PostgreSQL 下会报错的那些)。

扫描范围：*.java(含 SQL 的行)、mapper *.xml、代码生成模板 *.vm、*.sql(排除其它方言目录)
排除：node_modules / dist / target / sql/{mysql,oracle,dm,kingbase,opengauss,highgo,sqlserver}

用法：python script/local/check_mysql_sql.py
"""
import os
import re
import subprocess

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

# PostgreSQL 不存在的 MySQL 函数(带左括号才算调用)
MYSQL_FUNCS = [
    'IFNULL', 'ISNULL', 'MONTH', 'DAYOFMONTH', 'DAYOFWEEK', 'DAYOFYEAR', 'WEEK', 'QUARTER',
    'DATE_FORMAT', 'STR_TO_DATE', 'UNIX_TIMESTAMP', 'FROM_UNIXTIME', 'CURDATE', 'CURTIME', 'SYSDATE',
    'DATEDIFF', 'TIMESTAMPDIFF', 'DATE_ADD', 'DATE_SUB', 'ADDDATE', 'SUBDATE', 'LAST_DAY',
    'TIME_TO_SEC', 'SEC_TO_TIME', 'GROUP_CONCAT', 'FIND_IN_SET', 'FIELD', 'LOCATE', 'INSTR',
    'SUBSTRING_INDEX', 'CONVERT', 'ANY_VALUE', 'JSON_EXTRACT', 'JSON_UNQUOTE', 'SOUNDEX',
    'LAST_INSERT_ID', 'YEARWEEK', 'EXTRACTVALUE', 'REGEXP_LIKE', 'SPACE', 'ELT',
]
# MySQL 专有语法
MYSQL_SYNTAX = [
    (r'\bINSERT\s+IGNORE\b', 'INSERT IGNORE'),
    (r'\bREPLACE\s+INTO\b', 'REPLACE INTO'),
    (r'\bON\s+DUPLICATE\s+KEY\b', 'ON DUPLICATE KEY'),
    (r'\bLIMIT\s+\d+\s*,\s*\d+', 'LIMIT m,n'),
    (r'\bORDER\s+BY\s+FIELD\s*\(', 'ORDER BY FIELD()'),
    (r'\bGROUP\s+BY\s+FIELD\s*\(', 'GROUP BY FIELD()'),
    (r'\bSELECT\s+.*\bIF\s*\(', 'IF() 函数'),
    (r'`[A-Za-z_][A-Za-z0-9_]*`', '反引号标识符'),
    (r'\bUNIX_TIMESTAMP\b', 'UNIX_TIMESTAMP'),
]
SQL_HINT = re.compile(r'\b(SELECT|INSERT|UPDATE|DELETE|FROM|WHERE|GROUP\s+BY|ORDER\s+BY|JOIN|setSql|apply|@Select|@Update|@Insert|@Delete|last\(|inSql)\b', re.I)

SKIP_DIRS = ('sql/mysql/', 'sql/oracle/', 'sql/dm/', 'sql/kingbase/', 'sql/opengauss/',
             'sql/highgo/', 'sql/sqlserver/', 'node_modules/', 'dist/', 'target/', '/docs/')


def tracked(*patterns):
    out = subprocess.run(['git', 'ls-files', *patterns], cwd=ROOT, capture_output=True)
    return out.stdout.decode('utf-8', 'replace').splitlines()


def scan(paths, line_filter):
    hits = []
    for rel in paths:
        if any(s in '/' + rel for s in SKIP_DIRS):
            continue
        try:
            with open(os.path.join(ROOT, rel.replace('/', os.sep)), encoding='utf-8') as f:
                lines = f.read().splitlines()
        except (OSError, UnicodeDecodeError):
            continue
        for idx, line in enumerate(lines, 1):
            if line_filter and not line_filter(line):
                continue
            for fn in MYSQL_FUNCS:
                if re.search(r'(?<![A-Za-z0-9_.])' + fn + r'\s*\(', line, re.I):
                    hits.append((rel, idx, fn + '()', line.strip()[:120]))
            for pat, label in MYSQL_SYNTAX:
                if re.search(pat, line, re.I if label not in ('IF() 函数',) else 0):
                    hits.append((rel, idx, label, line.strip()[:120]))
    return hits


result = []
result += scan(tracked('*.java'), lambda l: bool(SQL_HINT.search(l)))
result += scan(tracked('*.xml'), None)
result += scan(tracked('*.vm'), None)

print('命中 %d 处：' % len(result))
for rel, idx, kind, text in result:
    print('  [%s] %s:%d\n      %s' % (kind, rel, idx, text))
