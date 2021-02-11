---
title: container security context on kubernetes
date: 2020-04-28
tags: [kubernetes, containers, security, dotnet]
description: let's add more security context to your containers on kubernetes
aliases:
    - /pod-security-context/
---
_2020-12 - I did my first Capture The Flag (CTF) experience illustrating those concepts explained on this article, you could find more information [here]({{< ref "/posts/2020/12/k8s-ctf.md" >}})_

While preparing my presentation with [Maxime Coquerel](https://www.linkedin.com/in/maximecoquerel) for our [16 Security Best Practices with Kubernetes on Azure (AKS)](https://youtu.be/BCDSXyrJUJQ) presentation in French, I took the opportunity to learn about the Pod Security Context in Kubernetes. Here, in this blog article, are my learnings.

First of all I went through the official Kubernetes documentation: [Configure a Security Context for a Pod or Container](https://kubernetes.io/docs/tasks/configure-pod-container/security-context/).

From there I did some research to see how I could apply this for my own projects, for example [myblog - `nginx`](https://github.com/mathieu-benoit/myblog) and [MyMonthlyBlogArticle.Bot - `dotnetcore`](https://github.com/mathieu-benoit/MyMonthlyBlogArticle.Bot).

And I found these very insightful resources:
- [Sample project for a Kubernetes friendly ASP.NET core application](https://github.com/Lybecker/k8s-friendly-aspnetcore)
- [Securing you kubernetes configuration (with Nginx). Not so simple!](https://blog.asksven.io/posts/securing-kubernetes-configuration)
    - _I agree with this statement "Not so simple!"._

So here are the results of my own implementations based on this:
- [PR to implement this with myblog](https://github.com/mathieu-benoit/myblog/pull/6)
    - `Dockerfile` to have the official base image `nginxinc/nginx-unprivileged`
    - Container's port as `8080` instead of `80`
    - `podSecurityContext` with `securityContext.capabilities.drop: all`, `runAsNonRoot: true`, `allowPrivilegeEscalation: false`, `automountServiceAccountToken: false` and `readOnlyRootFilesystem: true`
    - Mount `tmp` as `emptyDir` on Kubernetes
- [PR to implement this with MyMonthlyBlogArticle.Bot](https://github.com/mathieu-benoit/MyMonthlyBlogArticle.Bot/pull/35)
    - `Dockerfile` to have these environment variables: `ENV ASPNETCORE_URLS=http://+:5000` and `COMPlus_EnableDiagnostics=0`
    - Container's port as `5000` instead of `80`
    - `podSecurityContext` with `securityContext.capabilities.drop: all`, `runAsNonRoot: true`, `allowPrivilegeEscalation: false`, `automountServiceAccountToken: false` and `readOnlyRootFilesystem: true`

Notes: you could locally test your Docker container with:
- `docker run --read-only --cap-drop=ALL --user=1000` to anticipate few options on Kubernetes listed above
- `docker diff` on your running container to see if there is any folder it is writing in that you could mount as `emptyDir` on Kubernetes
- If you are using Istio, you will get an issue with the `istio-proxy` sidecar if you are using `automountServiceAccountToken: false`. The sidecar needs a [service account token to talk to the control plane](https://github.com/istio/istio/issues/22193)

Now on a policy or governance standpoint, how to control this across your kubernetes deployments? That's where you could [Use admission controllers to enforce policy](https://cloud.google.com/kubernetes-engine/docs/how-to/hardening-your-cluster#admission_controllers).

As an illustration, you could also read [here about the CVE-2020-14386](https://cloud.google.com/blog/products/containers-kubernetes/how-gvisor-protects-google-cloud-services-from-cve-2020-14386), uses the `CAP_NET_RAW` capability of the Linux kernel to cause memory corruption, allowing an attacker to gain root access when they should not have. And that's also a good opportunity to learn more about the investments and innovations Google is doing on an open source and security perspectives: the [`gVisor` project](https://cloud.google.com/blog/products/gcp/open-sourcing-gvisor-a-sandboxed-container-runtime) is a great example.

Hope you enjoyed and learned something with this blog article and you will be able to leverage these resources for your own context and security posture!

Cheers! ;)