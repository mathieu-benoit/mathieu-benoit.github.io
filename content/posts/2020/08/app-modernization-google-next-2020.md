---
title: application modernization at google next onair 2020
date: 2020-08-31
tags: [gcp, containers, kubernetes]
description: let's see in details what is google next onair 2020 and more specifically what you should watch on an application modernization standpoint
aliases:
    - /app-modernization-google-next-2020/
---
[![](https://storage.googleapis.com/gweb-cloudblog-publish/images/DevOps_BlogHeader_D_Rnd3.max-2200x2200.jpg)](https://storage.googleapis.com/gweb-cloudblog-publish/images/DevOps_BlogHeader_D_Rnd3.max-2200x2200.jpg)

tl;dr: There is a lot of content and sessions discussed in this blog article, in case you would like to know what are the top 5 sessions I found very insightful on an App Modernization standpoint, here you are:
- [An App Modernization Story with Cloud Run](https://cloud.withgoogle.com/next/sf/sessions?session=APP236#application-modernization) [[Youtube](https://youtu.be/KY4DozBVV1Y)], great journey from monolith (Windows VM) to microservices (serverless Linux Container).
- [Building Globally Scalable Services with Istio and ASM](https://cloud.withgoogle.com/next/sf/sessions?session=APP210#application-modernization) [[Youtube](https://youtu.be/clu7t0LVhcw)], great definition of what's a service mesh.
- [GitOps Workflows with GitLab and Anthos for Hybrid Cloud](https://cloud.withgoogle.com/next/sf/sessions?session=APP235#application-modernization) [[Youtube](https://youtu.be/npc08ggdTOw)], great session about GitOps in the context of multi GKE clusters managed via Anthos Configuration Management.
- [Anthos Deep Dive: Part One](https://cloud.withgoogle.com/next/sf/sessions?session=APP316#application-modernization) [[Youtube](https://youtu.be/be_bXETvbuE)], great walkthrough of ACM, Anthos GKE (on GCP, on-premise on AWS) and Cloud Monitoring and Logging.
- [Anthos Deep Dive: Part Two](https://cloud.withgoogle.com/next/sf/sessions?session=APP317#application-modernization) [[Youtube](https://youtu.be/jIkymJYsCR4)], great walkthrough of ASM and Cloud Run for Anthos.

What a perfect timing! While I'm doing my onboarding as [a Noogler](https://www.linkedin.com/posts/mathieubenoitqc_cloud-innovation-continuouslearning-activity-6685996290330947584-bKkB), I have the opportunity to (e-)attend my first Google conference. Yes for sure, like everyone I won't be able to travel to San Francisco or somewhere else to attend in-person such conference during 4-5 days. But I actually feel more lucky than if I would have, because without traveling I have 9 weeks of content thanks to this incredible new format of Google Next: [Google Next OnAir 2020](https://cloud.withgoogle.com/next/sf/)!

I'm very impressed about the quality, the unicity and the huge amount of content from this conference. Most, if not all, of the sessions are ~20 min long, very convenient. It's very unique because it's during 9 weeks, with for sure sessions but many different other formats to learn about GCP:
- [Session packages](https://cloud.withgoogle.com/next/sf/sessions#session-packages)
- [Cloud Hero](https://go.qwiklabs.com/cloudheronext)
- [Cloud Study Jam](https://cloudonair.withgoogle.com/events/next20-studyjam)
- [Demos](https://cloud.withgoogle.com/next/sf/demos)
- [Live Dev Talks](https://cloudonair.withgoogle.com/events/talks-by-devrel)

I took the opportunity to watch most of the App Modernization sessions, here below are the links and few notes I captured:

# Application Modernization

- [Hands-on Keynote: Building Trust for Speedy Innovation](https://cloud.withgoogle.com/next/sf/sessions?session=GENKEY02#application-modernization) [[Youtube](https://youtu.be/7QR1z35h_yc)]
    - Demo Bank on Anthos: the journey for modernization via Monitoring, Security, CI/CD, Machine learning, etc.
- [Accelerate App Development and Delivery: The Modern Way](https://cloud.withgoogle.com/next/sf/sessions?session=SOLKEY203#application-modernization) [[Youtube](https://youtu.be/x3G2VRDVpbY)]
    - Announce of the new [Google CAMP](https://cloud.google.com/blog/products/application-development/google-camp-shows-you-how-to-operate-at-scale) program to accelerate your Cloud Application Modernization. Improvement on the integration between Cloud Code, buildpacks and Cloud Run to develop, debug and deploy your containerized apps.
- [An App Modernization Story with Cloud Run](https://cloud.withgoogle.com/next/sf/sessions?session=APP236#application-modernization) [[Youtube](https://youtu.be/KY4DozBVV1Y)]
    - Great description of what an app modernization could look like from monolith on-prem to containerized microservices with Cloud Run to get more flexibility, security, resiliency and all of this cheaper!

# GKE and Anthos

- [Getting started with Anthos](https://cloud.withgoogle.com/next/sf/sessions?session=APP100#application-modernization) [[Youtube](https://youtu.be/DM8p_cnc6ZY)]
    - Anthos is a managed application platform for enterprises that want faster modernization and greater consistency in a hybrid and lulti-cloud world.
- [Ship Faster, Spend Less By Going Multi-Cloud with Anthos](https://cloud.withgoogle.com/next/sf/sessions?session=SOLKEY200#application-modernization) [[Youtube](https://youtu.be/98QGt0zBFEg)]
    - A journey to modernization with Anthos in retail explained by application decoupling, lifecycle agility,  systematic delivery, observability and security.
- [Modernizing Texas’ Best Retail Chain with Anthos](https://cloud.withgoogle.com/next/sf/sessions?session=APP102#application-modernization) [[Youtube](https://youtu.be/uU3ulPcjjzA)]
    - A great sttory of modernizatioon from H-E-B by adopting DevOps, Kubernetes, Anthos, SRE and chaos engineering.
- [Build, Deploy, Modernize and Manage Apps using Anthos](https://youtu.be/N8vwVVAuG6g)
    - Anthos can managed GKE, GKE onprem, GKE on Azure, GKE on AWS, AKS or EKS clusters by providing common features such as unified authentication, Anthos Config Management (ACM), Anthos Service Mesh (ASM)
- [Optimize Cost to Performance on Google Kubernetes Engine](https://cloud.withgoogle.com/next/sf/sessions?session=APP218#application-modernization) [[Youtube](https://youtu.be/ry7XfEHivgE)]
    - Cluster Autoscaler, Pod Horizontal Autoscaler and Pod Vertical Autoscaler with the combination of continuous monitoring to the rescue. Did you know that [`VerticalPodAutoscaler`](https://cloud.google.com/kubernetes-engine/docs/how-to/vertical-pod-autoscaling#getting_resource_recommendations) could be used to just recommend which CPU or memory requests your containers need?
- [Designing Google Kubernetes Clusters for Massive Scale and Performance](https://cloud.withgoogle.com/next/sf/sessions?session=APP310#application-modernization) [[Youtube](https://youtu.be/3AAgWBvM5L0)]
    - Twitter shares their experiencee about their microservices at Internet scale. Note: the support of 15K nodes on GKE is coming with version 1.18.
- [Ensuring Business Continuity at Times of Uncertainty and Digital-only Business with GKE](https://cloud.withgoogle.com/next/sf/sessions?session=APP311#application-modernization) [[Youtube](https://youtu.be/FXuTzAy26u4)]
    - Business continuity for Dexcom talking about how to support high availability while reducing risks: reggional clusters, auto-sscaling, GKE reservvation, `PodDisruptionBudget`, Pod Anti/Affinity, Probes, Continuous updates, Surge Node Upgrade, Maintenance & exclusion windows, Multiple environmens, etc.
- [Building Globally Scalable Services with Istio and ASM](https://cloud.withgoogle.com/next/sf/sessions?session=APP210#application-modernization) [[Youtube](https://youtu.be/clu7t0LVhcw)]
    - All about multi clusters pattern and distributed services. Ameer does a really great job to explain the advantages and responsibilities to come from monolith, going to microserives, embracing service mesh to what's the value of Istio and Anthos Service Mesh. In other words, that's the presentation you need if you would like to understand what's a service mesh, and why you may need one (or not)! It's also referencing both resources [Kubernetes Engine (GKE) multi-cluster life cycle management series](http://bit.ly/gke-multicluster-lifecycle) and [ASM Workshop](http://bit.ly/asm-workshop).
- [GitOps Workflows with GitLab and Anthos for Hybrid Cloud](https://cloud.withgoogle.com/next/sf/sessions?session=APP235#application-modernization) [[Youtube](https://youtu.be/npc08ggdTOw)]
    - Great session about GitOps in the context of multi GKE clusters managed via Anthos Configuration Management.
- [Modern CI/CD with Anthos](https://cloud.withgoogle.com/next/sf/sessions?session=ARC203#application-modernization) [[Youtube](https://youtu.be/3mSm_HvvgOs)]
    - All about security, configuration and infrastructure as code and monitoring part of CI/CD. Fundamentals components: Git repos, Container images and Kubernetes Manifests helping for more standardize collaboration between the 3 main personas: Security, Ops and Dev.
- [Mainframe Modernization: Accelerating Legacy Transformation](https://cloud.withgoogle.com/next/sf/sessions?session=APP107#application-modernization) [[Youtube](https://youtu.be/-er5J94hvw0)]
    - Illustration of anti-patterns of mainframe modernization: big-bang rewrite, platform emulation and _in situ_ modernization. Definition of the [Google Cloud G4 Platform](https://cloud.google.com/solutions/mainframe-modernization) with an example of Cobol --> Google Cloud.
- [Integrating VM Workloads into Anthos Service Mesh](https://cloud.withgoogle.com/next/sf/sessions?session=APP211#application-modernization) [[Youtube](https://youtu.be/3qBr0v4QR_w)]
    - Modernize your VMs in place or develop a strategy to migrate your VMs to containers with ASM.
- [Modernize Legacy Java Apps Using Anthos](https://cloud.withgoogle.com/next/sf/sessions?session=APP224#application-modernization) [[Youtube](https://youtu.be/xiX3IdHWjLM)]
    - FIXME
- [Running Anthos on Bare Metal and at the Edge with Major League Baseball](https://cloud.withgoogle.com/next/sf/sessions?session=APP228#application-modernization) [[Youtube](https://youtu.be/FrFYM2W9gj8)]
    - A great story by the MLB for Anthos on-prem on top of VMWare and adding more AI/ML for the new generation of their Statcast solution.
- [Enhance Your Security Posture and Run PCI Compliant Apps with Anthos](https://cloud.withgoogle.com/next/sf/sessions?session=APP238#application-modernization) [[Youtube](https://youtu.be/k2Re-IPjesU)]
    - Prescriptive and opinionated guidance on how to utilize Anthos’s security features for your PCI workloads.
- [Accelerating Application Development with Anthos](https://cloud.withgoogle.com/next/sf/sessions?session=APP239#application-modernization) [[Youtube](https://youtu.be/Dkfqd2zoufE)]
    - After a quick introduction of app modernization with Kubernetes, Cloud Run and Anthos, this session is about how to move seamlessly your PCF workloads into Anthos.
- [Evolve to Zero Trust Security Model‎ with Anthos Security](https://cloud.withgoogle.com/next/sf/sessions?session=APP240#application-modernization) [[Youtube](https://youtu.be/zCVwc3ocYfQ)]
    - A Zero trust production worload security approach with Anthos.
- [Anthos Deep Dive: Part One](https://cloud.withgoogle.com/next/sf/sessions?session=APP316#application-modernization) [[Youtube](https://youtu.be/be_bXETvbuE)]
    - A walk through of ACM, Anthos GKE (on GCP, on-premand on AWS) and Cloud Monitoring and Logging.
- [Anthos Deep Dive: Part Two](https://cloud.withgoogle.com/next/sf/sessions?session=APP317#application-modernization) [[Youtube](https://youtu.be/jIkymJYsCR4)]
    - A walk through of ASM and Cloud Run for Anthos. Great example of chaos test to break a SLO.
- [Anthos Security: Modernize Your Security Posture for Cloud-Native Applications](https://cloud.withgoogle.com/next/sf/sessions?session=SEC230#application-modernization) [[Youtube](https://youtu.be/7IU2SywG_BA)]
    - How Anthos helps getting a better security posture across all your environments with mainly 4 steps: Harden infrastructure, establish guardrails, secure workloads and monitor and detect.
- [Develop Scalable Apps in Anthos](https://cloud.withgoogle.com/next/sf/sessions?session=SVR226#application-modernization) [[Youtube](https://youtu.be/Jupawsr16yM)]
    - A walk through of the [Cloud Run for Anthos Reference Web App](https://github.com/GoogleCloudPlatform/cloud-run-anthos-reference-web-app).

# Demos

- [App Modernization demo](https://cloud.withgoogle.com/next/sf/demos?demo=704#application-modernization)
    - Learn how Anthos brings everything together to balance security with agility, reliability with efficiency, and portability with consistency.
- [Cloud native development demo](https://cloud.withgoogle.com/next/sf/demos?demo=705#application-modernization)
    - A quick and interactive demo about Cloud native development about 3 aareas: Code and Verify, Package and Release and Run and Manage from 3 different personas: Dev, Security and Ops.
- [Experience a Fully Managed, Serverless Environment demo](https://cloud.withgoogle.com/next/sf/demos?demo=706#application-modernization) [[Youtube](https://youtu.be/cL4zK_OajE8)]
    - Discover how to easily build and deploy containerized applications in a fully managed environment using Cloud Run.
- [Explore Anthos](https://cloud.withgoogle.com/next/sf/demos?demo=701#application-modernization) [[Youtube](https://youtu.be/in2L8AimfOQ)]
    - A walk through a sample deployment for Anthos and gain insights about the different Anthos tools—such as ASM and ACM
- [Source-Driven Development with Cloud Code](https://cloud.withgoogle.com/next/sf/demos?demo=702#application-modernization) [[Youtube](https://youtu.be/ofsWr85gltc)]
    - A 5-min video to walk you through Cloud Code for facilitating your local developments with containers, Cloud Run, Kubernetes, and GKE.
- [Serverless Functions in Any Language Everywhere](https://cloud.withgoogle.com/next/sf/demos?demo=703#application-modernization) [[Youtube](https://youtu.be/DJjL6uXADlI)]
    - A 5-min video to walk you through Cloud Run and Cloud Functions and see how it could help you with your serverless applications.

# StudyJam

- [Hands-on Lab: Managing Traffic Routing with Istio and Envoy](https://cloudonair.withgoogle.com/events/next20-studyjam/watch?talk=w7-talk-2) [[Youtube](https://youtu.be/J0bEeh5P9hE)]
    - A 48-min video walking through this Qwiklabs lab: [Managing Traffic Routing with Istio and Envoy](https://www.qwiklabs.com/focuses/8456?parent=catalog).
- [Hands-on Lab: Continuous Delivery with Jenkins in Kubernetes Engine](https://cloudonair.withgoogle.com/events/next20-studyjam/watch?talk=w7-talk-3) [[Youtube](https://youtu.be/dgPA_I6PSoA)]
    - A 47-min video walking trhough this Qwiklabs lab: [Hands-on Lab: Continuous Delivery with Jenkins in Kubernetes Engine](https://www.qwiklabs.com/focuses/1103?parent=catalog).

2020 is a very weird year for sure because of the covid-19 situation, I feel very priviledged to work in IT and very grateful and proud to work for a company like Google, providing such amazing new way to learn and (e-)attend and consume conference. This blog article is mostly focused on the App Modernization area, but like discussed at the beginning of this blog article, [there is more with past or upcoming sessions](https://gregsramblings.com/blog/google-cloud-next-onair-cheat-sheet). I hope you feel like me engergized and envisioned with all of this! ;)

Complementary resources:
- [Accelerate your application development and delivery](https://cloud.google.com/blog/topics/google-cloud-next/developer-productivity-announcements-at-next20-onair)
- [Shining a light on Anthos at Next OnAir application modernization week](https://cloud.google.com/blog/topics/google-cloud-next/cant-miss-application-modernization-sessions-at-next20-onair)
- [I’m looking forward these 8 sessions at Google Cloud Next ’20 OnAir (Week 7)](https://seroter.com/2020/08/24/im-looking-forward-these-8-sessions-at-google-cloud-next-20-onair-weeks-7/)
- [Anthos rising—now easier to use, for more workloads](https://cloud.google.com/blog/topics/google-cloud-next/latest-anthos-release-adds-hybrid-ai-and-other-features)
- [Cloud Solutions Architecture](https://showcase.withgoogle.com/solutions-architecture)
- [[eBook] CIO Guide to application modernization](https://inthecloud.withgoogle.com/cio-guide-app-mod/dl-cd.html)
- [[eBook] Re-architecting to cloud native: an evolutionary approach to increasing developer productivity at scale](https://cloud.google.com/rearchitecting-to-cloud-native-whitepaper)
- [[eBook] Anthos under the hood](https://inthecloud.withgoogle.com/anthos-ebook/dl-cd-typ.html)

Stay safe and healthy, cheers!