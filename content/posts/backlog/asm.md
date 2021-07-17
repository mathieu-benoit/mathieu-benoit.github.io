---
title: service mesh to the rescue of completing my kubernetes journey
date: 2021-03-18
tags: [containers, security, gcp, kubernetes, service-mesh, sre]
description: let's see why a service mesh is an important piece for your kubernetes journey
draft: true
aliases:
    - /asm/
---
Parler de unprivileged container/pod par default (security context, non-root, etc.)


Managed ASM:
- https://cloud.google.com/service-mesh/docs/release-notes#March_04_2021
- https://cloud.google.com/service-mesh/docs/managed-control-plane
- https://cloud.google.com/service-mesh/docs/supported-features-mcp

Canary, Rollouts are progressive, organized in stages

Zero Configuration Istio
https://istio.io/latest/blog/2021/zero-config-istio/

I recently learned what a Service Mesh is for and what it could bring, Istio and Anthos Service Mesh (ASM), here is my story to illustrate how it was the missing piece of my Kubernetes journey.

I have a developer background and until my introduction to Kubernetes, my DevOps definition was about CI/CD, IaC and continuous monitoring/learning mostly (roughly summarized).

Then I discovered containers, I discovered the universal way to package and run stuffs, and by stuffs I mean any programming languages, any apps. Wow!

I eventually started with Kubernetes, it was rough, tough but in the meantime mindblowing!
I quickly understood that Kubernetes was not for app developers but was more a robuste and consistent platform where developers will deploy their apps. And that's where I started to extend my skills with more infrastructure and security perspectives. Actually I have been trying since then to learn and wear the different hats of the different personas involved with Kubernetes. What I have learned is that an **Apps developer** shouldn't do Kubernetes, it should just write code (robust, resilient, secure, bringing value to the end users, etc.) and then come the different personas:
- **Apps operator**: packaging app and building the CI pipelines
- **Platform operator**: building the CD pipelines and deploying apps
- **Security operator**: setting security practices at the apps, platform and infrastructure levels
- **Infrastructure operator**: build and maintaining the infrastructure required to host the platform

From here 

![Workflow and Personas from code to monitoring by going through CI/CD.](https://github.com/mathieu-benoit/sail-sharp/raw/main/personas.png)

So once I had my apps containerized running on Kubernetes, that was amazing, etc. But I was missing some things here.

Should developers be implementing all that list on their own?
Should the platform provide an abstraction?

But I was missing something here... something I was not comfortable with: observability.



separating business logics from security, network resilience, policies and observability

service registry, security (workload certs, mTLS, authN), policies enforcement (rate limiting, quota, authZ), traffic management (traffic split, canary rollouts, mirroring drain, secure ingress), resiliency (circuit breaking, fault injection) and observability (metrics, logs, traces)

curl https://storage.googleapis.com/csm-artifacts/asm/install_asm_1.9 > install_asm
./install_asm \
  --project_id $projectId \
  --cluster_name $clusterName \
  --cluster_location $zone \
  --mode install \
  --enable-all

k get istio-system
k get asm-system

k annotate ns

k rollout pods

k get pods --> 2/2

ASM in portal

The Four Golden Signals
https://sre.google/sre-book/monitoring-distributed-systems/#xref_monitoring_golden-signals

SLOs

Cloud Trace

mTLS

```
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  components:
    ingressGateways:
      - name: istio-ingressgateway
        enabled: true
        k8s:
          serviceAnnotations:
            cloud.google.com/neg: '{"ingress": true}'
```

https://cloud.google.com/service-mesh/docs/scripted-install/gke-upgrade
Update ASM:
```
./install_asm \
  --project_id $projectId \
  --cluster_name $clusterName \
  --cluster_location $zone \
  --mode upgrade \
  --enable-all
oldVersion=asm-183-2
kubectl delete Service,Deployment,HorizontalPodAutoscaler,PodDisruptionBudget istiod-$oldVersion -n istio-system --ignore-not-found=true
kubectl delete IstioOperator installed-state-$oldVersion -n istio-system
```

Further and complementary resources:
- [How a $4 billion retailer built an enterprise-ready Kubernetes platform powered by Linkerd](https://www.cncf.io/blog/2021/02/19/how-a-4-billion-retailer-built-an-enterprise-ready-kubernetes-platform-powered-by-linkerd/)
- [Service Mesh Is Still Hard](https://www.cncf.io/blog/2020/10/26/service-mesh-is-still-hard/)

I definitely now think that's not leveraging a Service Mesh on your Kubernete clusters is missing something, especially as you are increasing and scaling the number of workloads, getting more experience with Kubernetes and would like to have better collaboration and visibility between the different stakeholders: Apps developer, Apps operator, Security operator, Platform operator, Services operator and Infrastructure operator.

Hope you enjoyed that one, happy sailing!