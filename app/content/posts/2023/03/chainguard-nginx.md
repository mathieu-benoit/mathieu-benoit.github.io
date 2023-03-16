---
title: Chainguard nginx container image
date: 2023-03-15
tags: [fixme]
description: let s see what are the advantages of using a chainguard container image, in our case for the nginx one
draft: true
aliases:
    - /chainguard-nginx/
---
I have been using a `nginx` container image for [my blog](https://github.com/mathieu-benoit/mathieu-benoit.github.io/blob/main/app/Dockerfile) and my [ACM workshop](https://github.com/mathieu-benoit/acm-workshop/blob/main/app/Dockerfile) for a while now.

Actually, I use a secure variation of it: [`nginxinc/nginx-unprivileged:alpine-slim`](https://github.com/nginxinc/docker-nginx-unprivileged).

I can run this container securely like this for example:
```bash
docker run -d \
    -v $PWD/site-content:/var/lib/nginx/html \
    -p 8080:8080 \
    -u 1000 \
    --cap-drop=ALL \
    --read-only \
    --tmpfs /tmp \
    nginxinc/nginx-unprivileged:alpine-slim
```
_Note: same approach on Kubernetes._

Assuming that my awesome static website is:
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
  <h2>Hello World, with Nginx!</h2>
</body>
</html>
EOF
```

I thought about using `distroless` for this scenario, but it is more about _[build your own base image if you need it](https://github.com/GoogleContainerTools/distroless/issues/1219)_. But I didn't want to [go that path](https://github.com/nginxinc/docker-nginx-unprivileged/issues/49).

I found out that Chainguard has been building and maintaining a bunch of [_distroless_-like container images](https://www.chainguard.dev/chainguard-images). Sounds exciting!

> Reduce attack surface and minimize dependencies with our suite of images.

> Chainguard Images contain only what is required to build or run your application. This results in fewer CVEs over time compared to other base images and on average an 80% reduction in overall size.

Chainguard images, among many other security features provided, are baked by:
- [Wolfi](https://www.chainguard.dev/unchained/introducing-wolfi-the-first-linux-un-distro), a Linux (un)distribution built with default security measures for the software supply chain.
- [apko](https://www.chainguard.dev/unchained/introducing-apko-bringing-distroless-nirvana-to-alpine-linux), a declarative APK-based OCI image builder.
- glibc

Wow! I mean, I'm in! Let's give the [`cgr.dev/chainguard/nginx`](https://github.com/chainguard-images/images/tree/main/images/nginx) container image a try!

![Chainguard and Nginx logos](https://github.com/mathieu-benoit/my-images/raw/main/chainguard-nginx.png)

Here we are:
```bash
docker run -d \
    -v $PWD/site-content:/var/lib/nginx/html \
    cgr.dev/chainguard/nginx
```

Now, I need to run it as unprivileged container, here is how you can accomplish it:
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
    --cap-drop=ALL \
    cgr.dev/chainguard/nginx
```

The missing piece is running it in read-only mode:
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

With the `cgr.dev/chainguard/nginx` (20.4MB) in comparison to `nginx:alpine-slim` (40.7MB), we are saving 50.5% of space on the disk!

But on the other hand, we could see that the `nginx:alpine-slim` (11.5MB) is way much smaller than the `cgr.dev/chainguard/nginx` (20.4MB).

Does it make it less secure because the surface of attack is supposingly bigger? The following section will tackle this question.

### Less packages!

Actually no, it doesn't make `nginx:alpine-slim` more secure than `cgr.dev/chainguard/nginx`.

This blog post [Image sizes miss the point](https://www.chainguard.dev/unchained/image-sizes-miss-the-point) explains the why:

> To reduce debt, reduce image complexity not size.



_Note: we could also anticipate that the `cgr.dev/chainguard/nginx` image will be simplified soon [like discussed here](https://github.com/chainguard-images/images/issues/305#issuecomment-1454020044)._

Another important point is the fact that alpine is based on `musl`, in the other hand, `cgr.dev/chainguard/nginx` is based on `glibc`. This blog post [Why I Will Never Use Alpine Linux Ever Again](https://betterprogramming.pub/why-i-will-never-use-alpine-linux-ever-again-a324fd0cbfd6) highlight some known issues with `alpine`/`musl`.

### More secure!

Less packages and dependencies could land to a more secure container image, by using [Trivy](https://trivy.dev/) for example, we can confirm it.

For both `nginx:alpine-slim` and `cgr.dev/chainguard/nginx` we could see that we don t have any CVEs:
```plaintext
Total: 0 (UNKNOWN: 0, LOW: 0, MEDIUM: 0, HIGH: 0, CRITICAL: 0)
```

As a comparison, here is what the scanning results will give for the two other variations:
- `nginx:alpine`: `Total: 6 (UNKNOWN: 0, LOW: 0, MEDIUM: 2, HIGH: 2, CRITICAL: 2)`
- `nginx`: `Total: 116 (UNKNOWN: 0, LOW: 84, MEDIUM: 11, HIGH: 18, CRITICAL: 3)`



That's a wrap! Hope you liked it!

You could find [many more Chainguard images](https://www.chainguard.dev/chainguard-images) such as Redis, Postgres, Go, Node, Python, Ruby, Rust, etc.

Happy sailing, stay safe out there!