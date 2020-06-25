---
title: hello, cloud native hugo blog!
date: 2020-05-15
tags: [containers, azure, azure devops, kubernetes, helm, security]
description: let's discuss why my new blog is a containerized hugo website hosted on kubernetes
aliases:
    - /myblog/
---
My new blog is [here](http://alwaysupalwayson.com)! The old one was [there on Blogger](https://alwaysupalwayson.blogspot.com).

I just migrated my old articles to this new one by doing a "purge", meaning by removing some articles and just keeping the more important ones with the more value for others according to my focus: Open Source, Containers, DevOps, Cloud, Security and Kubernetes.

Blogger was fine for me, great helper to write, publish and host my blog articles. But I decided to move to a new self-hosted way as an opportunity for me to learn more:
- [Hugo website](https://gohugo.io) - I love the light and geeky way of writting Markdown files, Everything-as-Code!
- Container - I leverage the agile way to containerize my Hugo website to deploy it anywhere; from my local environment for dev/test to Kubernetes for my Production environment.
- Kubernetes - yet another app I want to deploy in my Kubernetes cluster to get more experiences with this.

As a note, I lost on-purpose few features like Comments and Analytics/Statistics on my blog articles... but to be honest I was not using them that much. So I made a choice here to not have yet equivalent to these features but that something I could implement too (in the future).

So yes, I just wanted to make it Cloud Native by leveraging different concepts you could look at, directly in its public GitHub repository: [https://github.com/mathieu-benoit/myblog](https://github.com/mathieu-benoit/myblog):
- Docker - see [`Dockerfile` file](https://github.com/mathieu-benoit/myblog/blob/master/Dockerfile)
- Helm chart - see [`chart` folder](https://github.com/mathieu-benoit/myblog/tree/master/chart)
- Azure Pipelines - see [`azure-pipeline.yml` file](https://github.com/mathieu-benoit/myblog/blob/master/azure-pipeline.yml)
- And few more concepts and technologies such as: [`NetworkPolicies`]({{< ref "/posts/2019/09/calico.md" >}}), [`Pod Security Context`]({{< ref "/posts/2020/04/pod-security-context.md" >}}), `Nginx Ingress Controller`, `Cert-Manager`, etc.

I have been learning a lot (yes, that's a continuous journey)!

Hope you like this story and hope you will love this new UI and UX with my new blog! If you have any feedback, comment or issue about this blog, feel free to directly file a new issue {{< html >}}<a href="https://github.com/mathieu-benoit/myblog/issues/new/choose" target="_blank">there</a>{{< /html >}}.

Cheers!