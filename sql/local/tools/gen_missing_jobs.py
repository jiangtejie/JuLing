# -*- coding: utf-8 -*-
"""补齐缺失的定时任务(infra_job):hrm 3 个 + pms 1 个;cms 模块任务跳过"""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from extract_fms_wms_menu import parse_inserts, sql_literal

WANT = {'12903', '7112', '7111', '12906'}


def main():
    src = sys.argv[1]
    out_file = sys.argv[2]
    lines = Path(src).read_text(encoding='utf-8', errors='replace').splitlines()
    rows = [dict(zip(c, v)) for c, v in parse_inserts(lines, 'infra_job')]
    sel = [r for r in rows if r.get('id') in WANT]

    out = ['-- 补齐缺失定时任务(由MySQL 版转换;cms 模块任务已跳过)', '-- 幂等', '']
    for r in sel:
        cols = list(r.keys())
        vals = ', '.join(sql_literal(c, r[c], set()) for c in cols)
        out.append('INSERT INTO infra_job (' + ', '.join(cols) + ') VALUES (' + vals + ') ON CONFLICT (id) DO NOTHING;')
        print(f"  + id={r.get('id')} {r.get('handler_name')} status={r.get('status')}")
    Path(out_file).write_text('\n'.join(out), encoding='utf-8')
    print(f'written {out_file}, rows = {len(sel)}')


if __name__ == '__main__':
    main()
