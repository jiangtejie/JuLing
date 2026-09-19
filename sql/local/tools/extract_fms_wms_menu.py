# -*- coding: utf-8 -*-
"""
从MySQL 版 juling-baseline.sql 提取 fms(财务)/ wms(仓储)模块的:
  1) system_menu 子树(含父级链)
  2) 相关 system_dict_type / system_dict_data
并转换为 PostgreSQL 可执行 INSERT。

由于两版 SQL 的菜单 id 段不同,导入前会把整棵子树重映射到新的空闲 id 段(默认 6200 起),
同步修正 parent_id 引用,避免与现有菜单冲突。

用法: python extract_fms_wms_menu.py <mysql.sql> <out.sql> [起始id]
"""
import re
import sys
from pathlib import Path

MENU_BOOL_COLS = {'always_show', 'keep_alive', 'visible'}
NEW_ID_START = 6200          # 菜单新 id 段起点(现有菜单最大 id 5985)
DICT_TYPE_ID_START = 9000    # 字典类型新 id 段起点(现有最大 2138)
DICT_DATA_ID_START = 90000   # 字典数据新 id 段起点(现有最大 3449)


def parse_inserts(lines, table):
    pat = re.compile(r"INSERT INTO\s+`" + table + r"`\s*\(([^)]*)\)\s*VALUES\s*(.*);\s*$", re.I)
    for raw in lines:
        line = raw.strip()
        if not line.upper().startswith('INSERT INTO'):
            continue
        m = pat.match(line)
        if not m:
            continue
        cols = [c.strip().strip('`') for c in m.group(1).split(',')]
        for values in split_tuples(m.group(2)):
            yield cols, values


def split_tuples(payload):
    i, n = 0, len(payload)
    while i < n:
        while i < n and payload[i] != '(':
            i += 1
        if i >= n:
            break
        i += 1
        fields, cur, in_str = [], [], False
        while i < n:
            ch = payload[i]
            if in_str:
                if ch == '\\':
                    cur.append(payload[i:i + 2])
                    i += 2
                    continue
                if ch == "'":
                    if i + 1 < n and payload[i + 1] == "'":
                        cur.append("''")
                        i += 2
                        continue
                    in_str = False
                    i += 1
                    continue
                cur.append(ch)
                i += 1
                continue
            if ch == "'":
                in_str = True
                i += 1
                continue
            if ch in 'bB' and i + 1 < n and payload[i + 1] == "'":
                # MySQL 位字面量 b'0' / b'1':跳过前缀 b,按普通字符串解析
                i += 1
                continue
            if ch == ',':
                fields.append(''.join(cur).strip())
                cur = []
                i += 1
                continue
            if ch == ')':
                fields.append(''.join(cur).strip())
                i += 1
                break
            cur.append(ch)
            i += 1
        yield fields


def sql_literal(col, v, bool_cols):
    if v.upper() == 'NULL':
        return 'NULL'
    # 兜底:MySQL 位字面量残留形式 b0 / b'0' / B'1'
    m = re.fullmatch(r"[bB]'?([01])'?", v.strip())
    if m and not re.fullmatch(r'[01]', v.strip()):
        v = m.group(1)
    if col in bool_cols:
        return 'FALSE' if v in ('0', "b'0'", 'false', 'FALSE') else 'TRUE'
    if re.fullmatch(r'-?\d+(\.\d+)?', v):
        return v
    return "'" + v.replace("\\'", "''").replace('\\"', '"') + "'"


def main():
    src, out = sys.argv[1], sys.argv[2]
    new_start = int(sys.argv[3]) if len(sys.argv) > 3 else NEW_ID_START
    lines = Path(src).read_text(encoding='utf-8', errors='replace').splitlines()

    menus = {}
    for cols, values in parse_inserts(lines, 'system_menu'):
        row = dict(zip(cols, values))
        menus[int(row['id'])] = row

    def belongs(row):
        path = (row.get('path') or '').strip().lower()
        comp = (row.get('component') or '').strip().lower()
        perm = (row.get('permission') or '').strip().lower()
        return (path.startswith(('fms', 'wms')) or comp.startswith(('fms/', 'wms/'))
                or perm.startswith(('fms:', 'wms:')))

    keep = {i for i, r in menus.items() if belongs(r)}
    changed = True
    while changed:
        changed = False
        for i in list(keep):
            pid = (menus[i].get('parent_id') or '').strip()
            if pid and pid.upper() != 'NULL' and int(pid) != 0 and int(pid) not in keep and int(pid) in menus:
                keep.add(int(pid))
                changed = True

    # id 重映射(按原 id 升序分配新 id)
    ids = sorted(keep)
    id_map = {old: new_start + idx * 10 for idx, old in enumerate(ids)}
    print(f'menus parsed      : {len(menus)}')
    print(f'fms/wms subtree   : {len(ids)}  (old id {ids[0]} ~ {ids[-1]})')
    print(f'id remap          : {ids[0]} -> {id_map[ids[0]]} ... {ids[-1]} -> {id_map[ids[-1]]}')
    tops = [i for i in ids if int((menus[i].get('parent_id') or '0')) in (0,) or int(menus[i].get('parent_id') or '0') not in menus]
    for t in tops:
        print(f"  top: {menus[t].get('name')} path={menus[t].get('path')} old_parent={menus[t].get('parent_id')}")

    menu_cols = ['id', 'name', 'permission', 'type', 'sort', 'parent_id', 'path', 'icon',
                 'component', 'component_name', 'status', 'visible', 'keep_alive',
                 'always_show', 'creator', 'create_time', 'updater', 'update_time', 'deleted']
    out_lines = [
        '-- 由MySQL 版 juling-baseline.sql 提取并转换为 PostgreSQL',
        '-- 内容:fms(财务)/ wms(仓储)模块菜单(含父级链,id 已重映射)+ 相关字典',
        '-- 幂等:重复执行不会造成冲突',
        '',
    ]
    for i in ids:
        row = dict(menus[i])
        row['id'] = str(id_map[i])
        pid = (row.get('parent_id') or '0').strip()
        if pid.upper() == 'NULL' or int(pid) == 0:
            row['parent_id'] = '0'
        elif int(pid) in id_map:
            row['parent_id'] = str(id_map[int(pid)])
        vals = ', '.join(sql_literal(c, row.get(c, 'NULL'), MENU_BOOL_COLS) for c in menu_cols)
        out_lines.append(f'INSERT INTO system_menu ({", ".join(menu_cols)}) VALUES ({vals}) ON CONFLICT (id) DO NOTHING;')
    out_lines.append('')

    # 字典:type + data(id 同样重映射,避开现有数据)
    dict_types = []
    for cols2, values2 in parse_inserts(lines, 'system_dict_type'):
        row = dict(zip(cols2, values2))
        t = (row.get('type') or '').strip()
        if t.startswith(('fms', 'wms')):
            dict_types.append(row)

    has_fms = any((r.get('type') or '').startswith('fms') for r in dict_types)
    has_wms = any((r.get('type') or '').startswith('wms') for r in dict_types)
    prefix_ok = lambda t: (t.startswith('fms') and has_fms) or (t.startswith('wms') and has_wms)

    dict_types.sort(key=lambda r: int(r['id']))
    type_id_map = {int(r['id']): DICT_TYPE_ID_START + idx * 10 for idx, r in enumerate(dict_types)}
    for row in dict_types:
        row = dict(row)
        row['id'] = str(type_id_map[int(row['id'])])
        cols3 = list(row.keys())
        vals = ', '.join(sql_literal(c, row[c], set()) for c in cols3)
        out_lines.append(f'INSERT INTO system_dict_type ({", ".join(cols3)}) VALUES ({vals}) ON CONFLICT (id) DO NOTHING;')
    out_lines.append('')

    dict_rows = []
    for cols4, values4 in parse_inserts(lines, 'system_dict_data'):
        row = dict(zip(cols4, values4))
        if prefix_ok((row.get('dict_type') or '').strip()):
            dict_rows.append(row)
    dict_rows.sort(key=lambda r: int(r['id']))
    for idx, row in enumerate(dict_rows):
        row = dict(row)
        row['id'] = str(DICT_DATA_ID_START + idx)
        cols5 = list(row.keys())
        vals = ', '.join(sql_literal(c, row[c], set()) for c in cols5)
        out_lines.append(f'INSERT INTO system_dict_data ({", ".join(cols5)}) VALUES ({vals}) ON CONFLICT (id) DO NOTHING;')
    out_lines.append('')

    Path(out).write_text('\n'.join(out_lines), encoding='utf-8')
    print(f'dict types         : {len(dict_types)} (id remap {DICT_TYPE_ID_START}...)')
    print(f'dict data rows     : {len(dict_rows)} (id remap {DICT_DATA_ID_START}...)')
    print(f'written            : {out}')


if __name__ == '__main__':
    main()
