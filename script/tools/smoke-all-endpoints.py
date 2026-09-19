# -*- coding: utf-8 -*-
"""全接口动态冒烟：遍历所有无路径参数的 GET 接口，找出运行期报错(尤其 PG 兼容问题)。

用法：python script/local/smoke_all_endpoints.py [baseUrl]
"""
import json
import os
import re
import subprocess
import sys
import urllib.error
import urllib.request

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
BASE = sys.argv[1] if len(sys.argv) > 1 else 'http://127.0.0.1:48080'
PASSWORD_FILE = os.path.join(ROOT, 'script', 'local', 'admin-password.txt')


def git(*args):
    out = subprocess.run(['git', *args], cwd=ROOT, capture_output=True)
    return out.stdout.decode('utf-8', 'replace').splitlines()


def request(method, url, token=None, body=None):
    data = json.dumps(body).encode() if body is not None else None
    req = urllib.request.Request(url, data=data, method=method)
    req.add_header('Content-Type', 'application/json')
    req.add_header('tenant-id', '1')
    if token:
        req.add_header('Authorization', 'Bearer ' + token)
    try:
        with urllib.request.urlopen(req, timeout=30) as r:
            return r.status, r.read().decode('utf-8', 'replace')
    except urllib.error.HTTPError as e:
        return e.code, e.read().decode('utf-8', 'replace')
    except Exception as e:  # 连接层错误
        return 0, str(e)


def login():
    with open(PASSWORD_FILE, encoding='utf-8-sig') as f:
        pw = f.read().strip()
    status, text = request('POST', BASE + '/admin-api/system/auth/login',
                           body={'username': 'admin', 'password': pw})
    try:
        return json.loads(text)['data']['accessToken']
    except Exception:
        print('登录失败: %s %s' % (status, text[:200]))
        sys.exit(1)


CLASS_MAPPING = re.compile(r'@RequestMapping\(\s*(?:value\s*=\s*)?"([^"]*)"')
METHOD_MAPPING = re.compile(r'@(Get|Post|Put|Delete)Mapping\(\s*(?:value\s*=\s*)?"([^"]*)"')


def collect_endpoints():
    endpoints = []
    for rel in git('ls-files', '*Controller.java'):
        if '/test/' in rel:
            continue
        try:
            with open(os.path.join(ROOT, rel.replace('/', os.sep)), encoding='utf-8') as f:
                text = f.read()
        except (OSError, UnicodeDecodeError):
            continue
        m = CLASS_MAPPING.search(text)
        if not m:
            continue
        prefix = m.group(1)
        for verb, path in METHOD_MAPPING.findall(text):
            if verb != 'Get' or '{' in path:
                continue
            full = '/admin-api' + prefix + path
            if 'page' in path.lower() or 'list' in path.lower():
                full += ('&' if '?' in full else '?') + 'pageNo=1&pageSize=5'
            endpoints.append((rel, full))
    return endpoints


def main():
    token = login()
    endpoints = collect_endpoints()
    print('登录成功，收集到 GET 接口 %d 个，开始冒烟……' % len(endpoints))
    bad = []
    for rel, url in endpoints:
        status, text = request('GET', BASE + url, token=token)
        code, msg = None, ''
        try:
            obj = json.loads(text)
            code, msg = obj.get('code'), obj.get('msg') or ''
        except Exception:
            pass
        if code is None:
            if status != 200:
                bad.append((rel, url, 'HTTP=%s' % status, text[:120]))
            continue
        # 0 成功；400 参数问题；401/403 权限；404 不存在；501 模块禁用 —— 都不算缺陷
        if code not in (0, 400, 401, 403, 404, 405, 501):
            bad.append((rel, url, 'code=%s' % code, msg[:200]))
    print('\n异常接口 %d / %d：' % (len(bad), len(endpoints)))
    for rel, url, code, msg in bad:
        print('  %-58s %-14s %s' % (url.split('?')[0], code, msg.replace('\n', ' ')[:150]))


if __name__ == '__main__':
    main()
