# script/nginx —— 生产部署片段(参考)

线上 nginx 配置文件位于仓库外：`D:\software\a_installer\nginx-1.31.2\conf\nginx.conf`
（同目录有 `nginx.conf.bak-<时间戳>` 备份）。本文件是 **/jl 部署相关片段**的归档，便于换机重建。

## 片段

```nginx
# 入口 index.html 不缓存：保证部署后立刻拿到新的资源指纹
location = /jl/index.html {
    alias <项目根目录>/juling-ui/juling-ui-admin-vben/apps/web-antd/dist/index.html;
    add_header Cache-Control "no-cache";
}

# 品牌 logo 短缓存（非哈希文件名，避免长期缓存导致换标不生效）
location = /jl/logo.svg {
    alias <项目根目录>/juling-ui/juling-ui-admin-vben/apps/web-antd/dist/logo.svg;
    expires 1h;
}

# 前端静态资源：构建产物带内容哈希，可长缓存
location /jl/ {
    alias <项目根目录>/juling-ui/juling-ui-admin-vben/apps/web-antd/dist/;
    index index.html;
    try_files $uri $uri/ /jl/index.html;
    expires 30d;
    add_header Cache-Control "public, immutable";
}

# 后端 API(48080，后端只监听 127.0.0.1)
location /admin-api/ {
    proxy_pass http://127.0.0.1:48080;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection $connection_upgrade;
}

# IM 实时通道(WebSocket，后端 context-path 为 /，端点是 /infra/ws)
location /infra/ws {
    proxy_pass http://127.0.0.1:48080/infra/ws;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection $connection_upgrade;
    proxy_set_header Host $host;
    proxy_read_timeout 3600s;
}
```

## 注意

- `map $http_upgrade $connection_upgrade { default upgrade; '' close; }` 需在 `http` 块中定义（线上已有）。
- gzip 已在 `http` 块开启，`gzip_types` 为多行指令，已包含 `application/json`、`application/javascript`；
  修改它时注意别只改首行，否则会产生 `duplicate MIME type` 警告。
- `/druid/*` 与 `/doc.html` **刻意不做反向代理**：后端 48080 已限制为仅监听 `127.0.0.1`，
  这两个运维入口只在本机可访问，Druid 控制台另有账号口令
  （**本机文件** `script/local/druid-console.txt`，不在仓库内）。
- 改完配置先验证再生效：`nginx.exe -p <安装目录>\ -c conf/nginx.conf -t` 然后 `-s reload`。
