---
title: fixme
date: 2020-08-10
tags: [fixme]
description: fixme
draft: true
aliases:
    - /app-modernization-google-next-2020/
---

TL,DR: my best sessions are (I explain more later below):
- [An App Modernization Story with Cloud Run](https://youtu.be/KY4DozBVV1Y)
- [Building Globally Scalable Services with Istio and ASM](https://youtu.be/clu7t0LVhcw)

It was my first Google conference and what a year 

Very impressed about the quality of the huge contents.

Demos: https://cloud.withgoogle.com/next/sf/demos

https://cloud.google.com/blog/topics/google-cloud-next/developer-productivity-announcements-at-next20-onair
https://gregsramblings.com/blog/google-cloud-next-onair-cheat-sheet#application-modernization-august-25
https://seroter.com/2020/08/24/im-looking-forward-these-8-sessions-at-google-cloud-next-20-onair-weeks-7/
https://cloud.google.com/blog/topics/google-cloud-next/cant-miss-application-modernization-sessions-at-next20-onair
https://cloud.google.com/blog/topics/google-cloud-next/latest-anthos-release-adds-hybrid-ai-and-other-features

https://cloud.google.com/blog/products/serverless/cant-miss-serverless-sessions-at-next20-onair

# Application Modernization

- [Hands-on Keynote: Building Trust for Speedy Innovation](https://youtu.be/7QR1z35h_yc)
    - Demo Bank on Anthos: the journey for modernization via Monitoring, Security, CI/CD, Machine learning, etc.
- [Accelerate App Development and Delivery: The Modern Way](https://youtu.be/x3G2VRDVpbY)
    - Announce of the new [Google CAMP](https://cloud.google.com/blog/products/application-development/google-camp-shows-you-how-to-operate-at-scale) program to accelerate your Cloud Application Modernization. Improvement on the integration between Cloud Code, buildpacks and Cloud Run to develop, debug and deploy your containerized apps.
- [An App Modernization Story with Cloud Run](https://youtu.be/KY4DozBVV1Y)
    - Great description of what an app modernization could look like from monolith on-prem to containerized microservices with Cloud Run to get more flexibility, security, resiliency and all of this cheaper!

# GKE and Anthos

- [Getting started with Anthos](https://youtu.be/DM8p_cnc6ZY)
    - Anthos is a managed application platform for enterprises that want faster modernization and greater consistency in a hybrid and lulti-cloud world.
- [Ship Faster, Spend Less By Going Multi-Cloud with Anthos](https://youtu.be/98QGt0zBFEg)
    - A journey to modernization with Anthos in retail explained by application decoupling, lifecycle agility,  systematic delivery, observability and security.
- [Modernizing Texas’ Best Retail Chain with Anthos](https://youtu.be/uU3ulPcjjzA)
    - FIXME
- [Build, Deploy, Modernize and Manage Apps using Anthos](https://youtu.be/N8vwVVAuG6g)
    - Anthos can managed GKE, GKE onprem, GKE on Azure, GKE on AWS, AKS or EKS clusters by providing common features such as unified authentication, Anthos Config Management (ACM), Anthos Service Mesh (ASM)
- [Optimize Cost to Performance on Google Kubernetes Engine](https://youtu.be/ry7XfEHivgE)
    - Cluster Autoscaler, Pod Horizontal Autoscaler and Pod Vertical Autoscaler with the combination of continuous monitoring to the rescue. Did you know that [`VerticalPodAutoscaler`](https://cloud.google.com/kubernetes-engine/docs/how-to/vertical-pod-autoscaling#getting_resource_recommendations) could be used to just recommend which CPU or memory requests your containers need?
- [Designing Google Kubernetes Clusters for Massive Scale and Performance](https://youtu.be/3AAgWBvM5L0)
    - Twitter shares their experiencee about their microservices at Internet scale. Note: the support of 15K nodes on GKE is coming with version 1.18.
- [Ensuring Business Continuity at Times of Uncertainty and Digital-only Business with GKE](https://youtu.be/FXuTzAy26u4)
    - Business continuity for Dexcom talking about how to support high availability while reducing risks: reggional clusters, auto-sscaling, GKE reservvation, `PodDisruptionBudget`, Pod Anti/Affinity, Probes, Continuous updates, Surge Node Upgrade, Maintenance & exclusion windows, Multiple environmens, etc.
- [Building Globally Scalable Services with Istio and ASM](https://youtu.be/clu7t0LVhcw)
    - All about multi clusters pattern and distributed services. Ameer does a really great job to explain the advantages and responsibilities to come from monolith, going to microserives, embracing service mesh to what's the value of Istio and Anthos Service Mesh. In other words, that's the presentation you need if you would like to understand what's a service mesh, and why you may need one (or not)! It's also referencing both resources [Kubernetes Engine (GKE) multi-cluster life cycle management series](http://bit.ly/gke-multicluster-lifecycle) and [ASM Workshop](http://bit.ly/asm-workshop).
- [GitOps Workflows with GitLab and Anthos for Hybrid Cloud](https://cloud.withgoogle.com/next/sf/sessions?session=APP235#application-modernization)
    - Great session about GitOps in the context of multi GKE clusters managed via Anthos Configuration Management.

App Modernization demo
https://cloud.withgoogle.com/next/sf/demos?demo=704#application-modernization

Cloud native development demo
https://cloud.withgoogle.com/next/sf/demos?demo=705#application-modernization
