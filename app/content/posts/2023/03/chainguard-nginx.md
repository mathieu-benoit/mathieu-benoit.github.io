---
title: chainguard nginx container image
date: 2023-03-16
tags: [containers, kubernetes, security]
description: let's see what are the advantages of using a chainguard container image, with nginx
aliases:
    - /chainguard-nginx/
---
I have been using a `nginx` container image for [my blog](https://github.com/mathieu-benoit/mathieu-benoit.github.io/blob/main/app/Dockerfile) and my [ACM workshop](https://github.com/mathieu-benoit/acm-workshop/blob/main/app/Dockerfile) for a while now.

Actually, I use a secure variation of it: [`nginxinc/nginx-unprivileged:alpine-slim`](https://github.com/nginxinc/docker-nginx-unprivileged).

I can run this container securely like this for example:
```bash
docker run -d \
    -p 8080:8080 \
    -u 1000 \
    --cap-drop=ALL \
    --read-only \
    --tmpfs /tmp \
    nginxinc/nginx-unprivileged:alpine-slim
```

Same approach on Kubernetes:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx
  labels:
    app: nginx
spec:
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      securityContext:
        fsGroup: 1000
        runAsGroup: 1000
        runAsNonRoot: true
        runAsUser: 1000
        seccompProfile:
          type: RuntimeDefault
      containers:
        - name: nginx
          securityContext:
            allowPrivilegeEscalation: false
            capabilities:
              drop:
                - ALL
            privileged: false
            readOnlyRootFilesystem: true
          image: nginxinc/nginx-unprivileged:alpine-slim
          ports:
            - containerPort: 8080
          volumeMounts:
          - mountPath: /tmp
            name: tmp
      volumes:
      - emptyDir: {}
        name: tmp
```

I thought about using `distroless` for this scenario, but it is more about _[build your own base image if you need it](https://github.com/GoogleContainerTools/distroless/issues/1219)_. And I didn't want to [go that path](https://github.com/nginxinc/docker-nginx-unprivileged/issues/49).

I found out that Chainguard has been building and maintaining a bunch of [_distroless_-like container images](https://www.chainguard.dev/chainguard-images). Sounds exciting!

> Reduce attack surface and minimize dependencies with our suite of images.

> Chainguard Images contain only what is required to build or run your application. This results in fewer CVEs over time compared to other base images and on average an 80% reduction in overall size.

Chainguard images, among many other security features provided, are backed by:
- [`wolfi`](https://www.chainguard.dev/unchained/introducing-wolfi-the-first-linux-un-distro), a Linux (un)distribution built with default security measures for the software supply chain.
- [`melange`](https://github.com/chainguard-dev/melange), a declarative pipelines tool to build apk packages.
- [`apko`](https://www.chainguard.dev/unchained/introducing-apko-bringing-distroless-nirvana-to-alpine-linux), a declarative APK-based OCI image builder.

Wow! I mean, I'm in! Let's give the [`cgr.dev/chainguard/nginx`](https://github.com/chainguard-images/images/tree/main/images/nginx) container image a try!

![Chainguard and Nginx logos](https://github.com/mathieu-benoit/my-images/raw/main/chainguard-nginx.png)

Here we are:
```bash
docker run -d \
    cgr.dev/chainguard/nginx
```

Now, I need to run it as an unprivileged container, here is how I can accomplish it:
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
    -v $PWD/nginx.conf:/etc/nginx/nginx.conf \
    -p 8080:8080 \
    -u 65532 \
    --cap-drop=ALL \
    cgr.dev/chainguard/nginx
```

Great! But now the missing piece is running it in a read-only mode:
```bash
docker run -d \
    -v $PWD/nginx.conf:/etc/nginx/nginx.conf \
    -p 8080:8080 \
    -u 65532 \
    --cap-drop=ALL \
    --read-only \
    --tmpfs /tmp \
    --tmpfs /sv \
    cgr.dev/chainguard/nginx
```
But this is not working at the time this blog post is written, [there is a known issue](https://github.com/chainguard-images/images/issues/288). Almost there, stay tuned! So for now, I will still continue using the `nginxinc/nginx-unprivileged:alpine-slim` one.

## Why using `cgr.dev/chainguard/nginx` container image?

### Smaller size!

```plaintext
REPOSITORY                    TAG           IMAGE ID       CREATED       SIZE
cgr.dev/chainguard/nginx      latest        7d2ef33a602f   6 hours ago   20.4MB
nginx                         latest        904b8cb13b93   2 weeks ago   142MB
nginx                         alpine        2bc7edbc3cf2   4 weeks ago   40.7MB
nginx                         alpine-slim   c59097225492   4 weeks ago   11.5MB
```

With the `cgr.dev/chainguard/nginx` (20.4MB) in comparison to `nginx:alpine` (40.7MB), we are saving 50.5% of space on disk!

But on the other hand, we could see that the `nginx:alpine-slim` (11.5MB) is way much smaller than the `cgr.dev/chainguard/nginx` (20.4MB).

Does it make `cgr.dev/chainguard/nginx` less secure than `nginx:alpine-slim` because the image size is bigger? The following section will tackle this question.

### Less packages and dependencies!

Actually no, it doesn't make `nginx:alpine-slim` more secure than `cgr.dev/chainguard/nginx`.

This blog post [Image sizes miss the point](https://www.chainguard.dev/unchained/image-sizes-miss-the-point) explains the why:

> To reduce debt, reduce image complexity not size.

By using a tool like [Syft](https://github.com/anchore/syft), we could see that `cgr.dev/chainguard/nginx` is less complex, with less dependencies, reducing the debt and surface of risks.

For `cgr.dev/chainguard/nginx`:
```plaintext
ca-certificates-bundle  20220614-r4  apk   
execline                2.9.2.1-r0   apk   
glibc                   2.37-r1      apk   
glibc-locale-posix      2.37-r1      apk   
libcrypto3              3.0.8-r0     apk   
libgcc                  12.2.0-r9    apk   
libssl3                 3.0.8-r0     apk   
libstdc++               12.2.0-r9    apk   
nginx                   1.23.3-r1    apk   
pcre                    8.45-r0      apk   
s6                      2.11.3.0-r0  apk   
wolfi-baselayout        20230201-r0  apk   
zlib                    1.2.13-r3    apk
```

For `nginx:alpine-slim`:
```plaintext
alpine-baselayout       3.4.0-r0     apk     
alpine-baselayout-data  3.4.0-r0     apk     
alpine-keys             2.4-r1       apk     
apk-tools               2.12.10-r1   apk     
busybox                 1.35.0       binary  
busybox                 1.35.0-r29   apk     
busybox-binsh           1.35.0-r29   apk     
ca-certificates-bundle  20220614-r4  apk     
libc-utils              0.7.2-r3     apk     
libcrypto3              3.0.8-r0     apk     
libintl                 0.21.1-r1    apk     
libssl3                 3.0.8-r0     apk     
musl                    1.2.3-r4     apk     
musl-utils              1.2.3-r4     apk     
nginx                   1.23.3-r1    apk     
pcre2                   10.42-r0     apk     
scanelf                 1.3.5-r1     apk     
ssl_client              1.35.0-r29   apk     
tzdata                  2022f-r1     apk     
zlib                    1.2.13-r0    apk
```

_Note: we could also expect that the `cgr.dev/chainguard/nginx` image will be simplified a little bit more soon [like discussed here](https://github.com/chainguard-images/images/issues/305#issuecomment-1454020044). Stay tuned!_

Another important point is the fact that `alpine` is based on `musl`, on the other hand, `cgr.dev/chainguard/nginx` is based on `glibc`. This blog post: [Why I Will Never Use Alpine Linux Ever Again](https://betterprogramming.pub/why-i-will-never-use-alpine-linux-ever-again-a324fd0cbfd6) highlights some known issues with `alpine`/`musl`.

### More secure!

Less packages and dependencies could land to a more secure container image, by using [Trivy](https://trivy.dev/) for example, we can confirm it.

For both `nginx:alpine-slim` and `cgr.dev/chainguard/nginx` we could see that we don't have any CVEs:
```plaintext
Total: 0 (UNKNOWN: 0, LOW: 0, MEDIUM: 0, HIGH: 0, CRITICAL: 0)
```

As a comparison, here below is what the scanning results will give for the two other variations.

For `nginx:alpine`:
```plaintext
Total: 6 (UNKNOWN: 0, LOW: 0, MEDIUM: 2, HIGH: 2, CRITICAL: 2)
```

For `nginx`:
```plaintext
Total: 116 (UNKNOWN: 0, LOW: 84, MEDIUM: 11, HIGH: 18, CRITICAL: 3)
```



That's a wrap! Hope you liked it!

You could find [many more Chainguard images](https://www.chainguard.dev/chainguard-images) such as Redis, Postgres, Go, Node, Python, Ruby, Rust, etc.

Happy sailing, stay safe out there!