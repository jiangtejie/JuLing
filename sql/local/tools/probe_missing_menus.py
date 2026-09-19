# -*- coding: utf-8 -*-
"""侦察:mysql 脚本中 crm 缺哪些菜单、hrm/im/pms 子树规模与顶层"""
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from extract_fms_wms_menu import parse_inserts  # 复用解析器


def clean(v):
    return '' if v is None or v.upper() == 'NULL' else v


def main():
    sql_path = sys.argv[1]
    lines = Path(sql_path).read_text(encoding='utf-8', errors='replace').splitlines()
    menus = {}
    for cols, values in parse_inserts(lines, 'system_menu'):
        row = dict(zip(cols, values))
        menus[int(row['id'])] = row

    def key(row):
        return clean(row.get('component')) + '|' + clean(row.get('permission'))

    def prefix_ok(row, prefixes):
        path = clean(row.get('path')).lower()
        comp = clean(row.get('component')).lower()
        perm = clean(row.get('permission')).lower()
        for p in prefixes:
            if path == p or path.startswith(p + '/') or comp.startswith(p + '/') or perm.startswith(p + ':'):
                return True
        return False

    # 1) crm 缺失
    db_keys = {l.strip() for l in Path('db_crm_menu_keys.txt').read_text(encoding='utf-8-sig').splitlines() if l.strip()}
    crm_rows = [r for r in menus.values() if prefix_ok(r, ['crm'])]
    missing = [r for r in crm_rows if key(r) not in db_keys]
    print(f'[crm] 脚本 {len(crm_rows)} 条 / 库中键 {len(db_keys)} 个 / 缺失 {len(missing)} 条')
    for r in sorted(missing, key=lambda r: int(r['id'])):
        print(f"   - id={r['id']} type={r['type']} name={clean(r.get('name'))} path={clean(r.get('path'))} "
              f"comp={clean(r.get('component'))} perm={clean(r.get('permission'))} parent={clean(r.get('parent_id'))}")

    # 2) hrm / im / pms 子树
    for mod in ['hrm', 'im', 'pms']:
        seed = {i for i, r in menus.items() if prefix_ok(r, [mod])}
        keep = set(seed)
        changed = True
        while changed:
            changed = False
            for i in list(keep):
                pid = clean(menus[i].get('parent_id'))
                if pid and pid.isdigit() and int(pid) != 0 and int(pid) not in keep and int(pid) in menus:
                    keep.add(int(pid))
                    changed = True
        tops = [i for i in keep if clean(menus[i].get('parent_id')) in ('0', '')]
        print(f'[{mod}] 子树 {len(keep)} 条,顶层: ' +
              ', '.join(f"{menus[t].get('name')}(path={clean(menus[t].get('path'))},parent={clean(menus[t].get('parent_id'))})" for t in sorted(tops)))


if __name__ == '__main__':
    main()
