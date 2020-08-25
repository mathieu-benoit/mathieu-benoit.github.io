---
title: advanced networking setup with gke
date: 2020-08-25
tags: [gcp, containers, kubernetes, security]
description: let's leverage more advanced networking setup with gke clusters
aliases:
    - /advanced-networking-setup-with-gke/
---
[![](https://storage.googleapis.com/gweb-cloudblog-publish/images/Google_Containers_Uy53clo.max-2200x2200.jpg)](https://storage.googleapis.com/gweb-cloudblog-publish/images/Google_Containers_Uy53clo.max-2200x2200.jpg)

To continue my learning with GKE, [my first week with GCP](FIXME) was about deploying manually a containerized app on a basic/default GKE cluster. [My second week with GCP](FIXME) was about to fine-tune a little bit my GKE cluster with more features. My third week was about deploying a containerized app on GKE via Cloud Build and GCR. And this week will be dedicated on more advanced setups focused on networking.

For this, I'm still leveraging these two resources:
- [Preparing a Google Kubernetes Engine environment for production](https://cloud.google.com/solutions/prep-kubernetes-engine-for-prod)
- [Hardening your cluster's security](https://cloud.google.com/kubernetes-engine/docs/how-to/hardening-your-cluster)

# VPC-native cluster

Since [its announcement in October 2018](https://cloud.google.com/blog/products/gcp/introducing-vpc-native-clusters-for-google-kubernetes-engine), [VPC-native clusters for GKE](https://cloud.google.com/kubernetes-engine/docs/how-to/alias-ips) is the default cluster network mode when you create a GKE cluster from within the Google Console but not yet via REST API nor the Google Cloud SDK/CLI. VPC-native clusters use alias IP ranges for pod networking. This means that the control plane automatically manages the routing configuration for pods instead of configuring and maintaining static routes for each node in the GKE cluster. I have found these resources very valuable to understand why we should use this VPC-native clusters mode for better capabilities around security, performance and integration with other GCP services:
- [VPC-native clusters compared to routes-based clusters](https://cloud.google.com/solutions/prep-kubernetes-engine-for-prod#vpc-native_clusters_compared_to_routes-based_clusters)
- [The ins and outs of networking in Google Container Engine and Kubernetes (Google Cloud Next '17)](https://www.youtube.com/watch?v=y2bhV81MfKQ)
- [VPC-native clusters on Google Kubernetes Engine](https://medium.com/google-cloud/vpc-native-clusters-on-google-kubernetes-engine-b7c022c07510)

_Note: VPC-native clusters tend to consume more IP addresses in the network, so you should take that into account._

So here is now I will create my GKE cluster to leverage this feature:
```
gcloud container clusters create \
  --enable-ip-alias
```

# VPC/Subnet/CIDRs
    - https://cloud.google.com/kubernetes-engine/docs/how-to/alias-ips#cluster_sizing
    - https://cloud.google.com/vpc/docs/alias-ip
    - https://cloud.google.com/kubernetes-engine/docs/how-to/flexible-pod-cidr

Understanding IP address management in GKE
https://cloud.google.com/blog/products/containers-kubernetes/ip-address-management-in-gke

Recommended to have 30 pods per node max, after this as you will scale your nodes you could overload your master nodes.

# Private clusters

> By default, all nodes in a GKE cluster have public IP addresses. A good practice is to create private clusters, which gives all worker nodes only private RFC 1918 IP addresses. This is the most secure option as it prevents all internet access to both masters and nodes.
    - https://cloud.google.com/kubernetes-engine/docs/concepts/private-cluster-concept
    - https://cloud.google.com/kubernetes-engine/docs/how-to/private-clusters
    - https://github.com/GoogleCloudPlatform/gke-private-cluster-demo

_Note: [This table](https://cloud.google.com/kubernetes-engine/docs/concepts/private-cluster-concept#overview) illustrates how you could combine both Private endpoint and Master authorized networks features. Furthermore, [here is the list of requirements, restrictions and limitations](https://cloud.google.com/kubernetes-engine/docs/how-to/private-clusters#req_res_lim) for Private GKE clusters you should be aware of._

So here is now I will create my GKE cluster to get a fully private GKE cluster:
```
gcloud container clusters create \
  --enable-ip-alias \
  --enable-private-nodes \
  --enable-private-endpoint \
  --enable-master-authorized-networks
```

> From other VMs in the cluster's VPC network, you can use `kubectl` to communicate with the private endpoint only if they are in the same region as the cluster and either their internal IP addresses are included in the list of master authorized networks or they are located in the same subnet as the cluster's nodes.

FIXME:
- Talk about Cloud Nat: https://cloud.google.com/nat/docs/gke-example
- what about Cloud Build? 
- What about Container Registry?
  - https://cloud.google.com/vpc-service-controls/docs/set-up-gke
- Test creation of a jumpbox?
  - https://cloud.google.com/solutions/connecting-securely#bastion

# Container-native Load Balancing

Once you have deployed a containerized app in Kubernetes, you have many ways to expose it through a `Service` or an `Ingress`: NodePort Service, ClusterIP Service, Internal LoadBalancer Service, External LoadBalancer Servvice, Internal Ingress, External Ingress or Multi-cluster Ingress. This will walk you through all those concepts: [GKE best practices: Exposing GKE applications through Ingress and Services](https://cloud.google.com/blog/products/containers-kubernetes/exposing-services-on-gke). To expose an `Ingress` on GKE I have found this following resource very valuable: [Ingress features](https://cloud.google.com/kubernetes-engine/docs/how-to/ingress-features) which provides a comprehensive list of supported features for `Ingress` on GCP.

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
- VPC versus Private Registry/Cluster
https://cloud.google.com/vpc-service-controls/docs/supported-products#build
- https://medium.com/google-cloud/mitigating-data-exfiltration-risks-in-gcp-using-vpc-service-controls-part-1-82e2b440197
- https://cloud.google.com/blog/products/identity-security/preventing-lateral-movement-in-google-compute-engine
- https://cloud.google.com/kubernetes-engine/docs/concepts/types-of-clusters#vpc-clusters
  - [VPC-native cluster](https://cloud.google.com/kubernetes-engine/docs/how-to/alias-ips)
      - Network Endpoint Groups (NEG) by annotating the Service with `cloud.google.com/neg: '{ingress": true}'`? Is it related/mandatory?
- [Scalable and Manageable: A Deep-Dive Into GKE Networking Best Practices (Cloud Next '19)](https://www.youtube.com/watch?v=fI-5LkBDap8)
- Load Balancing
https://cloud.google.com/blog/products/containers-kubernetes/exposing-services-on-gke
https://cloud.google.com/kubernetes-engine/docs/how-to/ingress-features
https://cloud.google.com/kubernetes-engine/docs/how-to/container-native-load-balancing
https://cloud.google.com/kubernetes-engine/docs/how-to/flexible-pod-cidr
https://cloud.google.com/load-balancing/docs/forwarding-rule-concepts
- https://www.youtube.com/watch?v=WFwGgo7ULXE
  - VPC Firewall
  - VPC Service Controls
  - Packet Mirroring
  - Cloud Armor (DDoS Protection + WAF) on Load Balancer


More advanced features:
- eBPF : https://cloud.google.com/blog/products/containers-kubernetes/bringing-ebpf-and-cilium-to-google-kubernetes-engine
- 



