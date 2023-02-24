---
title: fixme
date: 2020-08-10
tags: [fixme]
description: fixme
draft: true
aliases:
    - /fixme/
---

cgr.dev/chainguard/nginx

https://github.com/chainguard-images/images/tree/main/images/nginx

```bash
mkdir site-content
cat <<EOF > site-content/index.html
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <title>Nginx</title>
</head>
<body>
  <h2>Hello World from Nginx!</h2>
</body>
</html>
EOF
docker run -d \
    -v $PWD/site-content:/var/lib/nginx/html \
    cgr.dev/chainguard/nginx
```

```bash
cat <<EOF > nginx.conf
events {}
http {
    server {
        listen                  8080;
    }
}
EOF
docker run -d \
    -v $PWD/site-content:/var/lib/nginx/html \
    -v $PWD/nginx.conf:/etc/nginx/nginx.conf \
    -p 8080:8080 \
    -u 65532 \
    cgr.dev/chainguard/nginx
```

```bash
docker run -d \
    -v $PWD/site-content:/var/lib/nginx/html \
    -v $PWD/nginx.conf:/etc/nginx/nginx.conf \
    -p 8080:8080 \
    -u 65532 \
    --cap-drop=ALL \
    cgr.dev/chainguard/nginx
```

```bash
docker run -d \
    -v $PWD/site-content:/var/lib/nginx/html \
    -v $PWD/nginx.conf:/etc/nginx/nginx.conf \
    -p 8080:8080 \
    -u 65532 \
    --cap-drop=ALL \
    --read-only \
    --tmpfs /tmp \
    --tmpfs /sv \
    cgr.dev/chainguard/nginx
```
