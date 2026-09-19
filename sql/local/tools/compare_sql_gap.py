# -*- coding: utf-8 -*-
"""
对比MySQL 全量脚本 与 当前 PostgreSQL 库,找出缺失内容:
  1) 缺表
  2) 各模块菜单数量差异(component 首段口径)
  3) 缺失字典类型 / 字典数据数量差异
  4) 需要初始化数据的表(脚本里有 INSERT,而库里可能是空表)

用法: python compare_sql_gap.py <mysql.sql> <db_tables.txt> <db_menu_segments.txt> <db_dict_types.txt>
"""
import re
import sys
from pathlib import Path


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
                    cur.append(payload[i:i + 2]); i += 2; continue
                if ch == "'":
                    if i + 1 < n and payload[i + 1] == "'":
                        cur.append("''"); i += 2; continue
                    in_str = False; i += 1; continue
                cur.append(ch); i += 1; continue
            if ch == "'":
                in_str = True; i += 1; continue
            if ch in 'bB' and i + 1 < n and payload[i + 1] == "'":
                i += 1; continue
            if ch == ',':
                fields.append(''.join(cur).strip()); cur = []; i += 1; continue
            if ch == ')':
                fields.append(''.join(cur).strip()); i += 1; break
            cur.append(ch); i += 1
        yield fields


def clean(v):
    return '' if v is None or v.upper() == 'NULL' else v


def main():
    sql_path, db_tables, db_menu_seg, db_dict = sys.argv[1:5]
    lines = Path(sql_path).read_text(encoding='utf-8', errors='replace').splitlines()

    # ---------- 1) 表 ----------
    sql_tables = set()
    for raw in lines:
        m = re.match(r"CREATE TABLE\s+(?:IF NOT EXISTS\s+)?`([^`]+)`", raw.strip(), re.I)
        if m:
            sql_tables.add(m.group(1))
    db_tables_set = {l.strip() for l in Path(db_tables).read_text(encoding='utf-8-sig').splitlines() if l.strip()}
    missing_tables = sorted(sql_tables - db_tables_set)
    extra_tables = sorted(db_tables_set - sql_tables)

    # ---------- 2) 菜单 ----------
    def seg(comp):
        comp = clean(comp)
        return comp.split('/')[0] if comp else '(none)'
    sql_menu = {}
    for cols, values in parse_inserts(lines, 'system_menu'):
        row = dict(zip(cols, values))
        s = seg(row.get('component'))
        sql_menu[s] = sql_menu.get(s, 0) + 1
    db_menu = {}
    for line in Path(db_menu_seg).read_text(encoding='utf-8-sig').splitlines():
        if '|' in line:
            k, v = line.split('|', 1)
            db_menu[k.strip()] = int(v.strip())

    # ---------- 3) 字典 ----------
    sql_dict_data = {}
    for cols, values in parse_inserts(lines, 'system_dict_data'):
        row = dict(zip(cols, values))
        t = clean(row.get('dict_type'))
        sql_dict_data[t] = sql_dict_data.get(t, 0) + 1
    db_dict_map = {}
    for line in Path(db_dict).read_text(encoding='utf-8-sig').splitlines():
        if '|' in line:
            k, v = line.split('|', 1)
            db_dict_map[k.strip()] = int(v.strip())

    print('=' * 78)
    print(f'[1] 表:脚本 {len(sql_tables)} 张 / 库中 {len(db_tables_set)} 张')
    print(f'    缺失(脚本有、库无): {len(missing_tables)} 张')
    for t in missing_tables[:40]:
        print('      - ' + t)
    if len(missing_tables) > 40:
        print(f'      ... 其余 {len(missing_tables) - 40} 张见文件')
    Path('gap_missing_tables.txt').write_text('\n'.join(missing_tables), encoding='utf-8')
    print(f'    仅库中有(脚本无): {len(extra_tables)} 张')

    print('=' * 78)
    print('[2] 菜单按模块(component 首段):')
    print(f'    {"模块":<16}{"脚本":>8}{"库中":>8}{"差值":>8}')
    keys = sorted(set(sql_menu) | set(db_menu), key=lambda k: -(sql_menu.get(k, 0) - db_menu.get(k, 0)))
    for k in keys:
        a, b = sql_menu.get(k, 0), db_menu.get(k, 0)
        if a != b:
            print(f'    {k:<16}{a:>8}{b:>8}{a - b:>8}')

    print('=' * 78)
    print(f'[3] 字典:脚本 {len(sql_dict_data)} 类 / 库中 {len(db_dict_map)} 类')
    missing_types = sorted(set(sql_dict_data) - set(db_dict_map))
    print(f'    缺失字典类型: {len(missing_types)} 类')
    for t in missing_types[:40]:
        print(f'      - {t} ({sql_dict_data[t]} 条)')
    if len(missing_types) > 40:
        print(f'      ... 其余 {len(missing_types) - 40} 类见文件')
    Path('gap_missing_dict_types.txt').write_text(
        '\n'.join(f'{t}\t{sql_dict_data[t]}' for t in missing_types), encoding='utf-8')
    diff_data = [(t, sql_dict_data[t], db_dict_map.get(t, 0)) for t in sorted(set(sql_dict_data) & set(db_dict_map))
                 if sql_dict_data[t] != db_dict_map.get(t, 0)]
    print(f'    数量不一致的字典类型: {len(diff_data)} 类')
    for t, a, b in diff_data[:20]:
        print(f'      - {t}: 脚本 {a} / 库中 {b}')


if __name__ == '__main__':
    main()
