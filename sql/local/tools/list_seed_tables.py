# -*- coding: utf-8 -*-
"""列出官方 mysql 脚本中带种子数据的业务表(排除菜单/字典/账号/工作流引擎表),并生成库侧计数 SQL"""
import re
import sys
from pathlib import Path

SKIP_PREFIX = ('act_', 'flw_', 'qrtz_')
SKIP_TABLES = {
    'system_menu', 'system_dict_data', 'system_dict_type', 'system_role_menu', 'system_user_role',
    'system_role', 'system_users', 'system_dept', 'system_post', 'system_tenant', 'system_tenant_package',
    'system_user_post', 'system_user_third_party',
}


def main():
    src, db_tables_file, out_prefix = sys.argv[1:4]
    lines = Path(src).read_text(encoding='utf-8', errors='replace').splitlines()
    pat = re.compile(r"INSERT INTO\s+`([^`]+)`", re.I)
    counts = {}
    for line in lines:
        m = pat.match(line.strip())
        if not m:
            continue
        t = m.group(1)
        if t in SKIP_TABLES or t.startswith(SKIP_PREFIX):
            continue
        counts[t] = counts.get(t, 0) + line.count('),(') + 1

    db_tables = {l.strip() for l in Path(db_tables_file).read_text(encoding='utf-8-sig').splitlines() if l.strip()}
    both = sorted(t for t in counts if t in db_tables)
    only_sql = sorted(t for t in counts if t not in db_tables)

    Path(f'{out_prefix}_seed_tables.txt').write_text(
        '\n'.join(f'{t}\t{counts[t]}' for t in sorted(counts)), encoding='utf-8')

    parts = [f"SELECT '{t}' AS tbl, COUNT(*) AS cnt FROM {t}" for t in both]
    Path(f'{out_prefix}_seed_count.sql').write_text(' UNION ALL '.join(parts) + ' ORDER BY 2 DESC;', encoding='utf-8')

    print(f'seed tables in script : {len(counts)}  (库中存在 {len(both)} 个,脚本独有 {len(only_sql)} 个)')
    for t in sorted(counts, key=lambda x: -counts[x])[:30]:
        flag = '' if t in db_tables else '  <-- 库中无此表'
        print(f'  {t:<44} ~{counts[t]} 行{flag}')
    if only_sql:
        print('脚本独有(库中无表): ' + ', '.join(only_sql[:20]))


if __name__ == '__main__':
    main()
