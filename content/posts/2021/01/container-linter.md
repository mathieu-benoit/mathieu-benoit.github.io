---
title: container linter for compliances and security
date: 2021-01-06
tags: [containers, security]
description: let's see how to use open policy agent or dockle to check your containers on a security and compliances perspectives.
aliases:
    - /container-linter/
---
Let's see how we could easily leverage 2 tools/linters to add more security and complicances tests and checks for our containers.

# OPA

![Logo of Open Policy Agent.](https://github.com/open-policy-agent/opa/raw/main/logo/logo-144x144.png)

[Open Policy Agent (OPA)](https://www.openpolicyagent.org/) is a unified toolset and framework for policy across the cloud native stack. You can use OPA to enforce policies in microservices, Kubernetes, CI/CD pipelines, API gateways, and more.
> Whether for one service or for all your services, use OPA to decouple policy from the service's code so you can release, analyze, and review policies (which security and compliance teams love) without sacrificing availability or performance.

OPA is a CNCF project and is getting a great momentum especially with [OPA Gatekeeper for Kubernetes](https://www.openpolicyagent.org/docs/latest/kubernetes-introduction/). I won't cover this part today, but that's something I'm keeping for another blog article in the future. Since [PSP](https://kubernetes.io/docs/concepts/policy/pod-security-policy/) is not leaving the `beta` status since a while, OPA Gatekeeper is definitely something to look at and invest time on.

Today, what I would like to illustrate is checking that my containers are secured and compliant. For this I will use [`conftest`](https://www.conftest.dev/) to check my `Dockerfile`. Here below is an illustration of how to run `conftest` (as a container in my case, but you have [different options to install it](https://www.conftest.dev/install/)) by checking my OPA policies I defined in this file [`container-policies.rego`](https://gist.github.com/mathieu-benoit/6ee17cfa0172f75c1ee117667d82cc9a#file-container-policies-rego):

```
# Get the container-policies.rego file locally
mkdir policy
curl https://gist.githubusercontent.com/mathieu-benoit/6ee17cfa0172f75c1ee117667d82cc9a/raw/937f7664a9e73285917f2b6047db51314d39fe79/container-policies.rego -o ./policy/container-policies.rego
# Run conftest
docker run --rm -v $(pwd):/project openpolicyagent/conftest test Dockerfile
```

# Dockle

![Logo of Dockle.](https://github.com/goodwithtech/dockle/raw/master/imgs/logo.png)

> [`Dockle`](https://github.com/goodwithtech/dockle) - Container Image Linter for Security, Helping build the Best-Practice Docker Image, Easy to start. `Dockle` helps you to build best practice and secure container images (checkpoints include CIS Benchmarks).

```
docker run -v /var/run/docker.sock:/var/run/docker.sock --rm goodwithtech/dockle:latest \
    --exit-code 1 \
    --exit-level fatal \
    myblog
```

That's a wrap! We saw two approaches to add more checks and tests on a security and a compliance perspectives. On one hand OPA: extensible, broad use cases and for containers we saw it in actions to analyse your `Dockerfile` with your own custom policies. On the other hand `Dockle`, we saw how easy it is to use it with complex and out of the box policies to analyse a container image.

Further and complementary resources:
- [Open Policy Agent Intro - Patrick East, Styra & Max Smythe, Google](https://youtu.be/-_1wvU0v9UI?list=PLj6h78yzYM2Pn8RxfLh2qrXBDftr6Qjut)
- [PodSecurityContext]({{< ref "/posts/2020/04/pod-security-context.md" >}})
- [My Capture The Flag (CTF) and KubeCon NA 2020 experiences]({{< ref "/posts/2020/12/k8s-ctf.md" >}})
- [Advanced Continuous Integration pipeline for containers]({{< ref "/posts/2020/12/ci-for-k8s.md" >}})

Hope you enjoyed that one and that you will be able to shifting left more security and compliance checks in your deployment pipelines with your applications.

Cheers, stay safe out there! ;)