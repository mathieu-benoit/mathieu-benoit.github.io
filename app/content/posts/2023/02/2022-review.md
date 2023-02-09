---
title: 2022 in review, first year in devrel
date: 2023-02-08
tags: [gcp, kubernetes, gitops, helm, inspiration, presentations, security, service-mesh]
description: let's review my first year as devrel engineer in 2022, all about kubernetes
aliases:
    - /2022-review/
---
**For 2021** I did [this wrap up of the year on LinkedIn](https://www.linkedin.com/posts/mathieubenoitqc_googlecloud-kubernetes-canada-activity-6884693753190252544-3rau), where I shared great personal and professional achievements.

Taking the time to summarize what have been accomplished in a fiscal year is always a good exercise. We could celebrate, be grateful and adjust for the future.

## Roles I played

2022 was my first year as **DevRel Engineer**. I really enjoyed this year.

I moved from Cloud Sales to Cloud DevRel. On purpose, I chose to earn less money to have more fun and making more impact.

My title was Senior Cloud Developer Platform Engineer (DPE).

> DPEs are at the intersection of Developer Advocacy, Technical Writing, Product Management, and Engineering. - _[Source](https://medium.com/google-cloud/developer-programs-engineer-say-what-b12829729693)._

I was both an **Individual Contributor**, focused on GitOps and Security with GKE – and a **Tech Lead** in my team to connect the dots between the people, the products, the docs and the communities (internal and external) in order to enable them and improve the end users experience.

I brought my **15 years of experience** as Software Engineer and Solution Architect to broader communities. I really felt I was making impact.

I learned how to actually do **evangelism and advocacy work** as DevRel Engineer.

I directly worked with Product Managers, Software Engineers, Tech Writers, Developer Advocates, Customer Engineers, and many other stakeholders. The role I was given allowed me to be the bridge, the glue, between all of them.

I inspired and helped teammates and colleagues to accelerate their technical enablement and growth in their career.

I was focus on Kubernetes, more precisely on Google Kubernetes Engine (GKE) and Anthos.

More than ever, I continuously shared with others what I learned around **Kubernetes** and its ecosystem for the enterprise customers.

I nurtured my passion and appetite with **Security best practices with containers and Kubernetes**.

## Activities and artifacts I produced

I conducted and wrote 9 impactful [friction logs](https://developerrelations.com/developer-experience/an-introduction-to-friction-logging ), generating 200+ issues and feature requests for both products and docs.

> Including usability testing in the product development process helps establish the documentation’s usefulness and effectiveness. Most importantly, it improves user experience and increases the product’s success. - _[Source](https://medium.com/@dubemobinnaesiowu/how-to-test-technical-documentation-usability-74ad0c8d27c)._

I actively participated in 4 products/features launch. Activities I conducted were: design document reviews, UX mocks testing, internal and public preview features testing, demo samples building, docs creation or update, friction logging, blog for launch authoring, etc.
- [Harden your Kubernetes clusters and monitor workload compliance at scale with new PCI DSS policy bundle](https://cloud.google.com/blog/products/containers-kubernetes/new-pci-dss-policy-bundle/)
- [Apply policy bundles and monitor policy compliance at scale for Kubernetes clusters](https://cloud.google.com/blog/products/containers-kubernetes/apply-policy-bundles-and-monitor-policy-compliance-at-scale-for-kubernetes-clusters)
- [Manage Kubernetes configuration at scale using the new GitOps observability dashboard](https://cloud.google.com/blog/products/containers-kubernetes/manage-kubernetes-configuration-at-scale-using-the-new-gitops-observability-dashboard)
- [Deploy OCI artifacts and Helm charts the GitOps way with Config Sync ](https://cloud.google.com/blog/products/containers-kubernetes/gitops-with-oci-artifacts-and-config-sync)

I was one of the main maintainers of the very popular [**Online Boutique repository**](https://github.com/GoogleCloudPlatform/microservices-demo). I proudly added more security in there (NetworkPolicies, AuthorizationPolicies, Seccomp profile, Security Context, secure container images, etc.). I created the Online Boutique’s Helm chart. [Check these stories out](https://medium.com/p/246119e46d53)!

I created the [**Config Management and Service Mesh workshop**](https://acm-workshop.alwaysupalwayson.com/). It's a step-by-step guide to setup a secure GKE environment with services such as ASM, Cloud Armor, GKE Security Posture, Config Sync, Policy Controller, Dataplane V2, Artifact Registry, Spanner, Memorystore (Redis), etc. Everything is deployed with Config Connector and Config Sync. 3 sample apps are leveraged: Whereami, Online Boutique and Bank of Anthos. 3 personas are involved: Org Admin, Platform Admin and Apps Operator. Customers and Googlers gave me great feedback. It was my sandbox to learn and play with products and feed my friction logs.

## Blog posts I wrote

I co-wrote 2 official **Google Cloud blog posts** with [Divyansh Chaturvedi](https://www.linkedin.com/in/divyanshc/):
- [Deploy OCI artifacts and Helm charts the GitOps way with Config Sync](https://cloud.google.com/blog/products/containers-kubernetes/gitops-with-oci-artifacts-and-config-sync)
- [Manage Kubernetes configuration at scale using the new GitOps observability dashboard](https://cloud.google.com/blog/products/containers-kubernetes/manage-kubernetes-configuration-at-scale-using-the-new-gitops-observability-dashboard)

I wrote 15 posts in [**my personal blog**](https://alwaysupalwayson.com), the 3 most popular posts are:
- [Keyless GCP authentication from GitHub Actions with Workload Identity Federation](https://alwaysupalwayson.com/posts/2022/01/workload-identity-federation/)
- [Deploying Gatekeeper policies as OCI artifacts, the GitOps way](https://alwaysupalwayson.com/posts/2022/09/gatekeeper-policies-as-oci-artifacts/) 
- [Lessons learned from the Log4Shell CVEs](https://alwaysupalwayson.com/posts/2021/12/log4shell/)

I started writing [**posts on Medium**](https://medium.com/@mabenoit) in order to share more broadly my content. I wrote 8 posts there since September. The 3 most popular posts are:
- [CI/GitOps with Helm, GitHub Actions, GitHub Container Registry and Config Sync](https://medium.com/p/836913e74e79)
- [Use Helm to simplify the deployment of Online Boutique, with a Service Mesh, GitOps, and more!](https://medium.com/p/246119e46d53)
- [Seamlessly encrypt traffic from any apps in your Service Mesh to Memorystore (Redis)](https://medium.com/p/64b71969318d)

_Note: The [Sigstore’s cosign and policy-controller with GKE, Artifact Registry and KMS](https://medium.com/p/7bd5b12672ea) post just made it in the top 5 in less than 2 weeks, very popular topic! Watch out for it!_

I wrote 10 posts on [**my LinkedIn**](https://www.linkedin.com/in/mathieubenoitqc/) in order to share more broadly my content. The 3 most popular posts are:
- [2021 in review](https://www.linkedin.com/posts/mathieubenoitqc_googlecloud-kubernetes-canada-activity-6884693753190252544-3rau)
- [CI/GitOps with Helm, GitHub Actions, GitHub Container Registry and Config Sync](https://www.linkedin.com/posts/mathieubenoitqc_cigitops-with-helm-github-actions-github-activity-6977611558189154304-qP_8)
- [Use Cloud Spanner with Online Boutique](https://www.linkedin.com/posts/mathieubenoitqc_use-google-cloud-spanner-with-the-online-activity-6988665215517097984-NEQo)

_Note: Interestingly, the [Seamlessly encrypt traffic from any apps in your Mesh to Memorystore (redis)](https://www.linkedin.com/posts/mathieubenoitqc_seamlessly-encrypt-traffic-from-any-apps-activity-6975129860360826880-WFLK) post is very close to the 3rd one._

## Communities I engaged with

I presented 3 talks and 1 workshop in 2 major conferences: **IstioCon 2022** (virtual) and **GitOpsCon NA 2022** (in-person): 
- [The successful recipe to secure your fleet of clusters: GitOps + Policies + Service Mesh](https://sched.co/1AR95) - Co-built and co-presented with [Poonam Lamba](https://www.linkedin.com/in/poonamlamba/).
- [Build and deploy Cloud Native (OCI) artifacts, the GitOps way](https://sched.co/1AR9T) - Co-built with [Nan Yu](https://www.linkedin.com/in/nan-yu-57650618/).
- [Gatekeeper + Istio, FTW](https://events.istio.io/istiocon-2022/sessions/gatekeeper-istio/) - Co-built and co-delivered with [Ernest Wong](https://www.linkedin.com/in/chewong/).
- [Manage and Secure Distributed Services with Anthos Service Mesh](https://events.istio.io/istiocon-2022/sessions/workshop-anthos/) - Co-built and co-presented with [Christine Kim](https://www.linkedin.com/in/christine-soh-kim/), [Mike Coleman](https://www.linkedin.com/in/mikegcoleman/) and [Nim Jayawardena](https://www.linkedin.com/in/nimesha-nim-jayawardena-3b4a1396/).

I attended my first **KubeCon** in-person. So inspiring! Felt so re-energized when I came back from Detroit.

I co-organized with [Sébastien Thomas](https://www.linkedin.com/in/prune/) the first in-person [**K8S & CNCF meetup in Quebec City**](https://community.cncf.io/events/details/cncf-quebec-presents-meetup-de-novembre-recapitulatif-de-kubecon-na-et-lightning-talk/), post-covid.

I contributed to **5 CNCF projects: Kubernetes, Istio, ORAS, OPA Gatekeeper and Sigstore**. By delivering talks, writing blog posts, contributing to docs, filing issues, etc.

## The flights I took

I traveled internationally, again, for the first time since 2020.

I visited **5 Google offices: Montreal, Kitchener/Waterloo, NYC, Detroit and Paris**. The experience in a Google office is amazing, it’s like working from a modern art museum with free foods and the gamification of almost everything.

I took **7 weeks off in vacations** in France during Summer, to disconnect and enjoy quality time with friends and family. That was really well deserved.  

## That's a wrap!

Wow! What a year, busy, strong, but well balanced too. I really much liked it!

If our paths crossed in 2022, thank you!  Collaborating and learning from each other are what make such achievements more impactful, and meaningful. I’m very grateful for that.

Can’t wait to see what will come next in 2023 based on all of that.

Stay tuned, more to come in a next episode :)
