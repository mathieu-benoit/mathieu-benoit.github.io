---
title: container security context on kubernetes
date: 2020-04-28
tags: [kubernetes, containers, security]
description: let's add more security context to your containers on kubernetes
aliases:
    - /pod-security-context/
---
While preparing my presentation with [Maxime Coquerel](https://www.linkedin.com/in/maximecoquerel) for our [16 Security Best Practices with Kubernetes on Azure (AKS)](https://www.youtube.com/watch?v=BCDSXyrJUJQ) presentation in French, I took the opportunity to learn about the Pod Security Context in Kubernetes. Here, in this blog article, are my learnings.

First of all I went through the official Kubernetes documentation: [Configure a Security Context for a Pod or Container](https://kubernetes.io/docs/tasks/configure-pod-container/security-context/).

From there I did some research to see how I could apply this for my own projects, for example [myblog](https://github.com/mathieu-benoit/myblog) and [MyMonthlyBlogArticle.Bot](https://github.com/mathieu-benoit/MyMonthlyBlogArticle.Bot).

And I found those very insightful resources:
- [Sample project for a Kubernetes friendly ASP.NET core application](https://github.com/Lybecker/k8s-friendly-aspnetcore)
- [Securing you kubernetes configuration (with Nginx). Not so simple!](https://blog.asksven.io/posts/securing-kubernetes-configuration)
    - _I agree with this statement "Not so simple!"._

So here are the results of my own implementations based on this:
- [PR to implement this with myblog](https://github.com/mathieu-benoit/myblog/pull/6)
    - `Dockerfile` to have the official base image `nginxinc/nginx-unprivileged`
    - Container's port as `8080` instead of `80`
    - `podSecurityContext` with `securityContext.capabilities.drop: all`, `runAsNonRoot: true`, `allowPrivilegeEscalation: false` and `readOnlyRootFilesystem: true`
    - Mount `tmp` as `emptyDir` on Kubernetes
- [PR to implement this with MyMonthlyBlogArticle.Bot](https://github.com/mathieu-benoit/MyMonthlyBlogArticle.Bot/pull/35)
    - `Dockerfile` to have these environment variables: `ENV ASPNETCORE_URLS=http://+:5000` and `COMPlus_EnableDiagnostics=0`
    - Container's port as `5000` instead of `80`
    - `podSecurityContext` with `securityContext.capabilities.drop: all`, `runAsNonRoot: true`, `allowPrivilegeEscalation: false` and `readOnlyRootFilesystem: true`

Note: you could locally test your Docker container with:
- `docker run --rm --read-only` to anticipate `readOnlyRootFilesystem: true` on Kubernetes
- `docker diff` on your running container to see if there is any folder it is writing in and you could mount as `emptyDir` on Kubernetes

Now on a policy or governance standpoint, how to control this across your kubernetes deployments? Officially, there is the notion of [Pod Security Policy](https://kubernetes.io/docs/concepts/policy/pod-security-policy), you could [give it a try to this PSP concept in Preview with AKS](https://docs.microsoft.com/azure/aks/use-pod-security-policies). But it seems that this concept won't graduate anymore in Kubernetes and will let more room for the new concept of [Gatekeeper](https://github.com/open-policy-agent/gatekeeper) and [Open Policy Agent](https://www.openpolicyagent.org). In AKS you could [give it a try to this new way by leveraging Azure Policy](https://docs.microsoft.com/azure/governance/policy/concepts/rego-for-aks). Stay tuned for sure on this!

Hope you enjoyed and learned something with this blog article and you will be able to leverage those resources for your own context and security posture!

Cheers! ;)