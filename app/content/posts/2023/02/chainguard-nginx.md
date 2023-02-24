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

https://www.chainguard.dev/chainguard-images

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

## Why using `cgr.dev/chainguard/nginx` container image?

### Smaller size!

Let s talk about the size of the container image:
```plaintext
REPOSITORY                    TAG       IMAGE ID       CREATED       SIZE
cgr.dev/chainguard/nginx      latest    347a73fb3cdb   3 hours ago   20.4MB
nginxinc/nginx-unprivileged   alpine    157abf7c6312   11 days ago   40.7MB
nginxinc/nginx-unprivileged   latest    32817c140766   11 days ago   142MB
nginx                         alpine    2bc7edbc3cf2   13 days ago   40.7MB
nginx                         latest    3f8a00f137a0   2 weeks ago   142MB
```

With the `cgr.dev/chainguard/nginx` (20.4MB) in comparison to `nginxinc/nginx-unprivileged:alpine` (40.7MB), we are saving 50.5% of space on the disk!

### More secure!

```plaintext
cgr.dev/chainguard/nginx (wolfi 20230201)
=========================================
Total: 0 (UNKNOWN: 0, LOW: 0, MEDIUM: 0, HIGH: 0, CRITICAL: 0)
```

```plaintext
nginx:alpine (alpine 3.17.2)
============================
Total: 6 (UNKNOWN: 0, LOW: 4, MEDIUM: 2, HIGH: 0, CRITICAL: 0)

┌─────────┬────────────────┬──────────┬───────────────────┬───────────────┬─────────────────────────────────────────────────────────┐
│ Library │ Vulnerability  │ Severity │ Installed Version │ Fixed Version │                          Title                          │
├─────────┼────────────────┼──────────┼───────────────────┼───────────────┼─────────────────────────────────────────────────────────┤
│ curl    │ CVE-2023-23916 │ MEDIUM   │ 7.87.0-r1         │ 7.87.0-r2     │ [curl: HTTP multi-header compression denial of service] │
│         │                │          │                   │               │ https://avd.aquasec.com/nvd/cve-2023-23916              │
│         ├────────────────┼──────────┤                   │               ├─────────────────────────────────────────────────────────┤
│         │ CVE-2023-23914 │ LOW      │                   │               │ [curl: HSTS ignored on multiple requests]               │
│         │                │          │                   │               │ https://avd.aquasec.com/nvd/cve-2023-23914              │
│         ├────────────────┤          │                   │               ├─────────────────────────────────────────────────────────┤
│         │ CVE-2023-23915 │          │                   │               │ [curl: HSTS amnesia with --parallel]                    │
│         │                │          │                   │               │ https://avd.aquasec.com/nvd/cve-2023-23915              │
├─────────┼────────────────┼──────────┤                   │               ├─────────────────────────────────────────────────────────┤
│ libcurl │ CVE-2023-23916 │ MEDIUM   │                   │               │ [curl: HTTP multi-header compression denial of service] │
│         │                │          │                   │               │ https://avd.aquasec.com/nvd/cve-2023-23916              │
│         ├────────────────┼──────────┤                   │               ├─────────────────────────────────────────────────────────┤
│         │ CVE-2023-23914 │ LOW      │                   │               │ [curl: HSTS ignored on multiple requests]               │
│         │                │          │                   │               │ https://avd.aquasec.com/nvd/cve-2023-23914              │
│         ├────────────────┤          │                   │               ├─────────────────────────────────────────────────────────┤
│         │ CVE-2023-23915 │          │                   │               │ [curl: HSTS amnesia with --parallel]                    │
│         │                │          │                   │               │ https://avd.aquasec.com/nvd/cve-2023-23915              │
└─────────┴────────────────┴──────────┴───────────────────┴───────────────┴─────────────────────────────────────────────────────────┘
```

That s a wrap!

You could find many other Chainguard images such as FIXME
https://www.chainguard.dev/chainguard-images
