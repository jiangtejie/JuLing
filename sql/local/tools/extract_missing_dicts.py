# -*- coding: utf-8 -*-
"""
补齐缺失字典(以MySQL 全量脚本为参照):
  1) 库中完全没有的 dict_type 及其全部 dict_data
  2) 已存在但条目少于脚本的 dict_type,按 value 补差异条目
  cms_ / oa_ 前缀跳过(后端无对应模块、前端无页面)

用法: python extract_missing_dicts.py <mysql.sql> <db_dict_types.txt> output.sql [type_id_start] [data_id_start]
"""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from extract_fms_wms_menu import parse_inserts, sql_literal

SKIP_PREFIXES = ('cms_', 'oa_')
TYPE_ID_START = 9500
DATA_ID_START = 95000

DICT_TYPE_COLS_HINT = ['id', 'name', 'type', 'status', 'remark', 'creator', 'create_time', 'updater', 'update_time', 'deleted']


def clean(v):
    return '' if v is None or v.upper() == 'NULL' else v


def main():
    src, db_types_file, out = sys.argv[1], sys.argv[2], sys.argv[3]
    type_start = int(sys.argv[4]) if len(sys.argv) > 4 else TYPE_ID_START
    data_start = int(sys.argv[5]) if len(sys.argv) > 5 else DATA_ID_START

    lines = Path(src).read_text(encoding='utf-8', errors='replace').splitlines()

    sql_types = {}
    for cols, values in parse_inserts(lines, 'system_dict_type'):
        row = dict(zip(cols, values))
        sql_types[clean(row.get('type'))] = row

    sql_data = {}
    for cols, values in parse_inserts(lines, 'system_dict_data'):
        row = dict(zip(cols, values))
        sql_data.setdefault(clean(row.get('dict_type')), []).append(row)

    db_types = {}
    for line in Path(db_types_file).read_text(encoding='utf-8-sig').splitlines():
        if '|' in line:
            k, v = line.split('|', 1)
            db_types[k.strip()] = int(v.strip())

    # 缺失集合:以 type 表 + data 表中的类型并集为准(脚本中存在"只有数据、没有类型行"的字典)
    all_sql_types = set(sql_types) | set(sql_data)
    missing_types = [t for t in sorted(all_sql_types)
                     if t not in db_types and t and not t.startswith(SKIP_PREFIXES)]
    skipped = [t for t in sorted(all_sql_types)
               if t not in db_types and t and t.startswith(SKIP_PREFIXES)]

    out_lines = [
        '-- 补齐缺失字典(由MySQL 版转换;cms_/oa_ 已跳过)',
        '-- 幂等:重复执行不会造成冲突',
        '',
    ]

    # 1) 缺失的 dict_type + 其数据
    t_id = type_start
    d_id = data_start
    type_cnt = data_cnt = 0
    for t in missing_types:
        if t in sql_types:
            row = dict(sql_types[t])
            row['id'] = str(t_id)
            t_id += 10
            cols = list(row.keys())
            vals = ', '.join(sql_literal(c, row[c], set()) for c in cols)
            out_lines.append(f'INSERT INTO system_dict_type ({", ".join(cols)}) VALUES ({vals}) ON CONFLICT (id) DO NOTHING;')
            type_cnt += 1
        else:
            print(f'  ! {t}: 脚本无 dict_type 行,仅补数据')
        for d in sorted(sql_data.get(t, []), key=lambda r: int(r['id'])):
            d = dict(d)
            d['id'] = str(d_id)
            d_id += 1
            cols_d = list(d.keys())
            vals_d = ', '.join(sql_literal(c, d[c], set()) for c in cols_d)
            out_lines.append(f'INSERT INTO system_dict_data ({", ".join(cols_d)}) VALUES ({vals_d}) ON CONFLICT (id) DO NOTHING;')
            data_cnt += 1
    out_lines.append('')

    # 2) 已有类型补差:按 (dict_type, value) 比对
    extra_rows = []
    for t, rows in sql_data.items():
        if t in missing_types or t.startswith(SKIP_PREFIXES) or t not in db_types:
            continue
        try:
            existing = {l.split('|', 1)[1].strip() for l in Path('db_dict_values.txt').read_text(encoding='utf-8-sig').splitlines()
                        if l.startswith(t + '|')}
        except FileNotFoundError:
            existing = set()
        for r in rows:
            v = clean(r.get('value'))
            if v and v not in existing:
                extra_rows.append((t, r, v))
    for t, r, v in extra_rows:
        r = dict(r)
        r['id'] = str(d_id)
        d_id += 1
        cols = list(r.keys())
        vals = ', '.join(sql_literal(c, r[c], set()) for c in cols)
        out_lines.append(f'INSERT INTO system_dict_data ({", ".join(cols)}) VALUES ({vals}) ON CONFLICT (id) DO NOTHING;')
        data_cnt += 1
        print(f'  + 补差: {t} -> {v}')

    Path(out).write_text('\n'.join(out_lines), encoding='utf-8')
    print(f'missing dict types : {type_cnt}  (跳过 cms_/oa_: {len(skipped)})')
    print(f'dict data rows     : {data_cnt}')
    print(f'written            : {out}')


if __name__ == '__main__':
    main()
