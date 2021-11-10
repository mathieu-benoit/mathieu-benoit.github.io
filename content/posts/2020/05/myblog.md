---
title: hello, cloud native hugo blog!
date: 2020-05-15
tags: [containers, gcp, kubernetes, security]
description: let's discuss why my new blog is a containerized hugo website hosted on kubernetes
aliases:
    - /myblog/
---
_Update on 2020-08-07 where I transitioned from Azure to GCP for both build and host my blog._

My new blog is [here](https://alwaysupalwayson.com)! The old one was [there on Blogger](https://alwaysupalwayson.blogspot.com).

I just migrated my old articles to this new one by doing a "purge", meaning by removing some articles and just keeping the most important ones with the more value for the readers according to my focus: Open Source, Containers, DevOps, Cloud, Security and Kubernetes.

Blogger was fine for me, great helper to write, publish and host my blog articles. But I decided to move to a new self-hosted way as an opportunity for me to learn more:
- [Hugo website](https://gohugo.io) - I love the light and geeky way of writting Markdown files, Everything-as-Code!
- Container - I leverage the agile way to containerize my Hugo website to deploy it anywhere; from my local environment for dev/test to Kubernetes for my Production environment.
- Kubernetes - yet another app I want to deploy in my Kubernetes cluster to get more experiences with this.

For sure I lost on-purpose few features like comments and analytics/statistics on my blog articles... but to be honest I was not using them that much. So I made a choice here to not have yet equivalent to those features but that something I could implement in the future.

So yes, I just wanted to make it Cloud Native by leveraging different concepts you could look at, directly in its public GitHub repository: [https://github.com/mathieu-benoit/myblog](https://github.com/mathieu-benoit/myblog):
- Docker - see [`Dockerfile`](https://github.com/mathieu-benoit/myblog/blob/main/Dockerfile): multi-stages to build the container and generate an unprivileged container 
- Cloud Build - see [`cloudbuild.yaml`](https://github.com/mathieu-benoit/myblog/blob/main/cloudbuild.yaml): build the container, run security scan on it before pushing it in artifact registry
- GitHub Dependabot - see [`dependabot.yml`](https://github.com/mathieu-benoit/myblog/blob/main/.github/dependabot.yml): keep up-to-date the hugo theme git submodule and the docker base images

That is for the Continuous Integration (CI) part, for the Continuous Deployment (CD) part I opted in for a GitOps approach, here is where you could find all the Kubernetes manifests needed to deploy this app. Couple of features are leveraged here too:
- mTLS STRICT - see [`peerauthentication.yaml`](https://github.com/mathieu-benoit/my-kubernetes-deployments/blob/main/namespaces/myblog/myblog/peerauthentication.yaml)
- `NetworkPolicies` - see [`networkpolicies.yaml`](https://github.com/mathieu-benoit/my-kubernetes-deployments/blob/main/namespaces/myblog/myblog/networkpolicies.yaml)
- [`Pod Security Context`]({{< ref "/posts/2020/04/pod-security-context.md" >}})
- `AuthorizationPolicies` - see [`authorizationpolicies.yaml`](https://github.com/mathieu-benoit/my-kubernetes-deployments/blob/main/namespaces/myblog/myblog/authorizationpolicies.yaml)

In front of this, an ASM/Istio's `IngressGateway` is in place, it has [its own Kubernetes manifests in its own namespace](https://github.com/mathieu-benoit/my-kubernetes-deployments/tree/main/namespaces/asm-ingress). Couple of features are leveraged here too:
- mTLS STRICT
- HTTPS with `ManagedCertificate`
- [Cloud Armor for DDOS and WAF protections]({{< ref "/posts/2021/04/cloud-armor.md" >}})


I have been learning a lot with this, and still am, that's a continuous learning journey for sure, and that's the goal!

Hope you like this story and hope you will love this new UI and UX with my new blog! If you have any feedback, comment or issue about this blog, feel free to directly file a new issue {{< html >}}<a href="https://github.com/mathieu-benoit/myblog/issues/new/choose" target="_blank">there</a>{{< /html >}}.

Cheers!