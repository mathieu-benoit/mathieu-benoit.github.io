---
title: container native networking with gke
date: 2020-08-25
tags: [gcp, containers, kubernetes, security]
description: let's see how gcp bring unique and true container native networking with gke
draft: true
aliases:
    - /container-native-networking-with-gke/
---
[![](https://storage.googleapis.com/gweb-cloudblog-publish/images/Google_Containers_Uy53clo.max-2200x2200.jpg)](https://storage.googleapis.com/gweb-cloudblog-publish/images/Google_Containers_Uy53clo.max-2200x2200.jpg)

FIXME - Intro

# VPC-native cluster

Since [its announcement in October 2018](https://cloud.google.com/blog/products/gcp/introducing-vpc-native-clusters-for-google-kubernetes-engine), [VPC-native clusters for GKE](https://cloud.google.com/kubernetes-engine/docs/how-to/alias-ips) is the default cluster network mode when you create a GKE cluster from within the Google Console but not yet via REST API nor the Google Cloud SDK/CLI. VPC-native clusters use [alias IP ranges](https://cloud.google.com/kubernetes-engine/docs/how-to/alias-ips) for pod networking. This means that the control plane automatically manages the routing configuration for pods instead of configuring and maintaining static routes for each node in the GKE cluster. I have found these following resources very valuable to understand why we should use this VPC-native clusters mode for better capabilities around security, performance and integration with other GCP services:
- [VPC-native clusters compared to routes-based clusters](https://cloud.google.com/solutions/prep-kubernetes-engine-for-prod#vpc-native_clusters_compared_to_routes-based_clusters)
- [The ins and outs of networking in Google Container Engine and Kubernetes (Google Cloud Next '17)](https://www.youtube.com/watch?v=y2bhV81MfKQ)
- [VPC-native clusters on Google Kubernetes Engine](https://medium.com/google-cloud/vpc-native-clusters-on-google-kubernetes-engine-b7c022c07510)

_Note: VPC-native clusters tend to consume more IP addresses in the network, so you should take that into account._

So here is now I will create my GKE cluster to leverage this feature (FYI you can't update an existing cluster to get this feature):
```
gcloud container clusters create \
  --enable-ip-alias
```

# Container-native Load Balancing

Once you have deployed a containerized app in Kubernetes, you have many ways to expose it through a `Service` or an `Ingress`: NodePort Service, ClusterIP Service, Internal LoadBalancer Service, External LoadBalancer Servvice, Internal Ingress, External Ingress or Multi-cluster Ingress. This following resource will walk you through all those concepts: [GKE best practices: Exposing GKE applications through Ingress and Services](https://cloud.google.com/blog/products/containers-kubernetes/exposing-services-on-gke). To expose an `Ingress` on GKE I have found this following resource very valuable as well: [Ingress features](https://cloud.google.com/kubernetes-engine/docs/how-to/ingress-features) which provides a comprehensive list of supported features for `Ingress` on GCP.

Since October 2018, [GCP has introduced a container-native load balancing on GKE](https://cloud.google.com/blog/products/containers-kubernetes/introducing-container-native-load-balancing-on-google-kubernetes-engine).

> Without [container-native load balancing](https://cloud.google.com/kubernetes-engine/docs/concepts/container-native-load-balancing), load balancer traffic travels to the node instance groups and gets routed via iptables rules to Pods which might or might not be in the same node. With container-native load balancing, load balancer traffic is distributed directly to the Pods which should receive the traffic, eliminating the extra network hop. Container-native load balancing also helps with improved health checking since it targets Pods directly.

https://cloud.google.com/blog/products/containers-kubernetes/introducing-container-native-load-balancing-on-google-kubernetes-engine
Ready? A Deep Dive into Pod Readiness Gates for Service Health Management
https://www.youtube.com/watch?v=Vw9GmSeomFg
https://cloud.google.com/kubernetes-engine/docs/concepts/container-native-load-balancing#requirements
https://cloud.google.com/kubernetes-engine/docs/how-to/container-native-load-balancing#using
https://cloud.google.com/kubernetes-engine/docs/concepts/ingress#limitations
https://cloud.google.com/armor/docs/configure-security-policies

To check:

- [Scalable and Manageable: A Deep-Dive Into GKE Networking Best Practices (Cloud Next '19)](https://www.youtube.com/watch?v=fI-5LkBDap8)
- https://www.youtube.com/watch?v=WFwGgo7ULXE
  - VPC Firewall
  - VPC Service Controls
  - Packet Mirroring
  - Cloud Armor (DDoS Protection + WAF) on Load Balancer

More advanced features:
- eBPF : https://cloud.google.com/blog/products/containers-kubernetes/bringing-ebpf-and-cilium-to-google-kubernetes-engine
- ASM and Istio tutorial: https://cloud.google.com/solutions/exposing-service-mesh-apps-through-gke-ingress
- Traffic Director & Envoy-Based L7 ILB for Production-Grade Service Mesh & Istio (Cloud Next '19)
https://youtu.be/FUITCYMCEhU


Complementary and further resources:
- [Cloud Load Balancing Deep Dive and Best Practices (Cloud Next '18)](https://www.youtube.com/watch?v=J5HJ1y6PeyE)

```
clusterName=mygkecluster2
gcloud container clusters create $clusterName \
    --release-channel rapid \
    --zone us-east1-b \
    --disk-type pd-ssd \
    --machine-type n1-standard-1 \
    --disk-size 100 \
    --image-type cos_containerd \
    --addons NodeLocalDNS,NetworkPolicy,HttpLoadBalancing \
    --enable-shielded-nodes \
    --shielded-secure-boot \
    --enable-autorepair \
    --enable-autoupgrade \
    --enable-ip-alias
```

for ((i=1;i<=100;i++)); do   curl -v 34.120.185.218; done
for ((i=1;i<=100;i++)); do   curl -v 35.186.246.29; done