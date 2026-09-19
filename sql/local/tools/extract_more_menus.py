# -*- coding: utf-8 -*-
"""
补齐缺失菜单:
  1) hrm / im / pms 整棵子树(含父级链)→ 重映射到新 id 段(8300 起,步长 10)
  2) crm 缺失的 7 条(产品统计/业绩统计/业绩目标配置+4 按钮)
     —— 两版 SQL 的 crm 菜单 id 段不同,按 path 匹配库中实际父节点:
        mysql parent 594(数据统计) -> 库 2560
        mysql parent 564(系统设置) -> 库 2524
        1451 自身在本批插入,保留原 id(库中空闲)

用法: python extract_more_menus.py <mysql.sql> <out.sql> [menu_id_start]
"""
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from extract_fms_wms_menu import MENU_BOOL_COLS, parse_inserts, sql_literal

MODULE_PREFIXES = ['hrm', 'im', 'pms']
ID_START = 8300
CRM_EXTRA_IDS = ['1449', '1450', '1451', '1452', '1453', '1454', '1455']
CRM_PARENT_MAP = {'594': '2560', '564': '2524', '1451': '1451'}

MENU_COLS = ['id', 'name', 'permission', 'type', 'sort', 'parent_id', 'path', 'icon',
             'component', 'component_name', 'status', 'visible', 'keep_alive',
             'always_show', 'creator', 'create_time', 'updater', 'update_time', 'deleted']


def clean(v):
    return '' if v is None or v.upper() == 'NULL' else v


def prefix_ok(row, prefixes):
    path = clean(row.get('path')).lower()
    comp = clean(row.get('component')).lower()
    perm = clean(row.get('permission')).lower()
    for p in prefixes:
        if path == p or path.startswith(p + '/') or comp.startswith(p + '/') or perm.startswith(p + ':'):
            return True
    return False


def main():
    src, out = sys.argv[1], sys.argv[2]
    start = int(sys.argv[3]) if len(sys.argv) > 3 else ID_START
    lines = Path(src).read_text(encoding='utf-8', errors='replace').splitlines()
    menus = {}
    for cols, values in parse_inserts(lines, 'system_menu'):
        row = dict(zip(cols, values))
        menus[int(row['id'])] = row

    out_lines = [
        '-- 补齐缺失菜单:hrm / im / pms 子树 + crm 缺失项(由MySQL 版转换)',
        '-- 幂等:重复执行不会造成冲突',
        '',
    ]

    # ---------- 1) hrm / im / pms ----------
    keep = {i for i, r in menus.items() if prefix_ok(r, MODULE_PREFIXES)}
    changed = True
    while changed:
        changed = False
        for i in list(keep):
            pid = clean(menus[i].get('parent_id'))
            if pid.isdigit() and int(pid) != 0 and int(pid) not in keep and int(pid) in menus:
                keep.add(int(pid))
                changed = True
    ids = sorted(keep)
    id_map = {old: start + idx * 10 for idx, old in enumerate(ids)}
    for i in ids:
        row = dict(menus[i])
        row['id'] = str(id_map[i])
        pid = clean(row.get('parent_id'))
        row['parent_id'] = '0' if (not pid or int(pid) == 0) else str(id_map[int(pid)])
        vals = ', '.join(sql_literal(c, row.get(c, 'NULL'), MENU_BOOL_COLS) for c in MENU_COLS)
        out_lines.append(f'INSERT INTO system_menu ({", ".join(MENU_COLS)}) VALUES ({vals}) ON CONFLICT (id) DO NOTHING;')
    print(f'hrm/im/pms subtree : {len(ids)}  (id {id_map[ids[0]]} ~ {id_map[ids[-1]]})')
    out_lines.append('')

    # ---------- 2) crm 缺失项 ----------
    crm_cnt = 0
    for mid in CRM_EXTRA_IDS:
        row = menus.get(int(mid))
        if not row:
            print(f'  ! mysql 中未找到菜单 id={mid}')
            continue
        row = dict(row)
        old_parent = clean(row.get('parent_id'))
        row['parent_id'] = CRM_PARENT_MAP.get(old_parent, old_parent)
        vals = ', '.join(sql_literal(c, row.get(c, 'NULL'), MENU_BOOL_COLS) for c in MENU_COLS)
        out_lines.append(f'INSERT INTO system_menu ({", ".join(MENU_COLS)}) VALUES ({vals}) ON CONFLICT (id) DO NOTHING;')
        crm_cnt += 1
    print(f'crm extra menus    : {crm_cnt}')
    out_lines.append('')

    Path(out).write_text('\n'.join(out_lines), encoding='utf-8')
    print(f'written            : {out}')


if __name__ == '__main__':
    main()
