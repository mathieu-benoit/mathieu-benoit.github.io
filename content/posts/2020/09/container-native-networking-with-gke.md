---
title: container native networking with gke
date: 2020-09-15
tags: [gcp, containers, kubernetes, servicemesh]
description: let's see how gcp brings unique and true container native networking with gke
draft: true
aliases:
    - /container-native-networking-with-gke/
---
[![](https://storage.googleapis.com/gweb-cloudblog-publish/images/Google_Containers_Uy53clo.max-2200x2200.jpg)](https://storage.googleapis.com/gweb-cloudblog-publish/images/Google_Containers_Uy53clo.max-2200x2200.jpg)

Networking with containers and Kubernetes is an important piece and it plays a critical role on a security, performance and reliability standpoints (pod-to-pod communications as well as communications in and out a Kubernetes cluster). With this article, I would like to list 4 main networking features GCP is providing for your GKE clusters. Again, those are important concepts to leverage but that's also the opportunity to demonstrate how Google is innovating, contributing and leading in such areas.
- [VPC-native cluster]({{< ref "#vpc-native-cluster" >}})
  - Default for your GKE clusters very soon if not already.
- [Container-native Load Balancing]({{< ref "#container-native-load-balancing" >}})
  - Default for your GKE clusters very soon if not already.
- [GKE Dataplane V2]({{< ref "#gke-dataplane-v2" >}})
  - Interesting future for GKE clusters with eBPF via Cilium.
- [Service Mesh]({{< ref "#service-mesh" >}})
  - Beyond the buzz, that's an important piece when scaling your containerized (but not only) workloads.

# VPC-native cluster

Since [its announcement in October 2018](https://cloud.google.com/blog/products/gcp/introducing-vpc-native-clusters-for-google-kubernetes-engine), [VPC-native clusters for GKE](https://cloud.google.com/kubernetes-engine/docs/how-to/alias-ips) is the default cluster network mode when you create a GKE cluster from within the Google Console but not yet via REST API nor the Google Cloud SDK/CLI. VPC-native clusters use [alias IP ranges](https://cloud.google.com/kubernetes-engine/docs/how-to/alias-ips) for pod networking. This means that the control plane automatically manages the routing configuration for pods instead of configuring and maintaining static routes for each node in the GKE cluster. I have found these following resources very valuable to understand why we should use this VPC-native clusters mode for better capabilities around security, performance and integration with other GCP services:
- [VPC-native clusters compared to routes-based clusters](https://cloud.google.com/solutions/prep-kubernetes-engine-for-prod#vpc-native_clusters_compared_to_routes-based_clusters)
- [The ins and outs of networking in Google Container Engine and Kubernetes (Google Cloud Next '17)](https://www.youtube.com/watch?v=y2bhV81MfKQ)
- [VPC-native clusters on Google Kubernetes Engine](https://medium.com/google-cloud/vpc-native-clusters-on-google-kubernetes-engine-b7c022c07510)

So here is now how I will create my GKE cluster to leverage this feature (FYI you can't update an existing cluster to get this feature):
```
gcloud container clusters create \
  --enable-ip-alias
```

VPC-native clusters tend to consume more IP addresses in the network, so you should take that into account. This guide [Understanding IP address management in GKE](https://cloud.google.com/blog/products/containers-kubernetes/ip-address-management-in-gke) explains really well what you should know about Pod range, Service range, subnet range, etc.
[![](https://storage.googleapis.com/gweb-cloudblog-publish/images/IP_address_management_in_GKE.max-800x800.jpg)](https://storage.googleapis.com/gweb-cloudblog-publish/images/IP_address_management_in_GKE.max-800x800.jpg)

Based on this, the example below is provisioning a cluster with auto-mode IP address management + limiting the IP addresses consumption for both nodes/pods and services:
```
gcloud container clusters create \
  --enable-ip-alias \
  --max-pods-per-node 30 # instead of 110 \
  --default-max-pods-per-node 30 # instead of 110 \
  --services-ipv4-cidr '/25' # instead of /20 \
  --cluster-ipv4-cidr '/20' # instead of /14
```

# Container-native Load Balancing

Once you have deployed a containerized app in Kubernetes, you have many ways to expose it through a `Service` or an `Ingress`: NodePort Service, ClusterIP Service, Internal LoadBalancer Service, External LoadBalancer Service, Internal Ingress, External Ingress or Multi-cluster Ingress. This following resource will walk you through all those concepts: [GKE best practices: Exposing GKE applications through Ingress and Services](https://cloud.google.com/blog/products/containers-kubernetes/exposing-services-on-gke). To expose an `Ingress` on GKE I have found this following resource very valuable as well: [Ingress features](https://cloud.google.com/kubernetes-engine/docs/how-to/ingress-features) which provides a comprehensive list of supported features for `Ingress` on GCP.

Since October 2018, [GCP has introduced a container-native load balancing on GKE](https://cloud.google.com/blog/products/containers-kubernetes/introducing-container-native-load-balancing-on-google-kubernetes-engine).

> Without [container-native load balancing](https://cloud.google.com/kubernetes-engine/docs/concepts/container-native-load-balancing), load balancer traffic travels to the node instance groups and gets routed via iptables rules to Pods which might or might not be in the same node. With container-native load balancing, load balancer traffic is distributed directly to the Pods which should receive the traffic, eliminating the extra network hop. Container-native load balancing also helps with improved health checking since it targets Pods directly.

For this you need to provision your GKE cluster with the `--enable-ip-aliases` parameter and then add the `cloud.google.com/neg: '{"ingress": true}'` annotation on your `Service` (even if you expose it via an `Ingress`). The recommendation is to explicitly set this annotation where you need it, even if in some cases it will be [applied by default under certain conditions](https://cloud.google.com/kubernetes-engine/docs/concepts/ingress#container-native_load_balancing). You could also [find the associated requirements, restrictions and limitations] information about that feature(https://cloud.google.com/kubernetes-engine/docs/concepts/container-native-load-balancing#requirements).

FIXME:
- gcloud get lb
- backendconfig with cloud armor, etc.

https://cloud.google.com/kubernetes-engine/docs/concepts/container-native-load-balancing#requirements
https://cloud.google.com/kubernetes-engine/docs/how-to/container-native-load-balancing#using
https://cloud.google.com/kubernetes-engine/docs/concepts/ingress#limitations
https://cloud.google.com/armor/docs/configure-security-policies

# GKE Dataplane V2

The [New GKE Dataplane V2 (leveraging eBPF via Cilium) which increases security and visibility for containers](https://cloud.google.com/blog/products/containers-kubernetes/bringing-ebpf-and-cilium-to-google-kubernetes-engine) has just been announced recently.

> [eBPF](https://ebpf.io) is a revolutionary technology that can run sandboxed programs in the Linux kernel without recompiling the kernel or loading kernel modules. Over the last few years, eBPF has become the standard way to address problems that previously relied on kernel changes or kernel modules. In addition, eBPF has resulted in the development of a completely new generation of tooling in areas such as networking, security, and application profiling.

> [Cilium](https://cilium.io) is an open source project that has been designed on top of eBPF to address the new scalability, security and visibility requirements of container workloads. Cilium goes beyond a traditional Container Networking Interface (CNI) to provide service resolution, policy enforcement and much more.

On [Cilium's blog article for the announcement](https://cilium.io/blog/2020/08/19/google-chooses-cilium-for-gke-networking), you could also read the story behind that partnership between Cilium, Google and actually the broad open source community, I love that!
> Google clearly has incredible technical chops and could have just built their dataplane directly on eBPF, instead, the GKE team has decided to leverage Cilium and contribute back. This is of course a huge honor for everybody who has contributed to Cilium over the years and shows Google's commitment to open collaboration.

This feature is in _beta_ as we speak, but seems really promising! Like describe in [this tutorial](https://cloud.google.com/kubernetes-engine/docs/how-to/network-policy-logging) you could give it a try by provisioning a new cluster with this command `gcloud beta container clusters create --enable-dataplane-v2`. From there, you will be for example able to leverage new features like [network policy logging](https://cloud.google.com/kubernetes-engine/docs/how-to/network-policy-logging).

# Service Mesh

When talking about networking with containers and Kubernetes, we can't avoid the Service Mesh area. If you are not familiar with Service Mesh or you are wondering why you do (or don't) need a Service Mesh for your own context, I highly encourage you to watch this session [Building Globally Scalable Services with Istio and ASM](https://cloud.withgoogle.com/next/sf/sessions?session=APP210#application-modernization) [[Youtube](https://youtu.be/clu7t0LVhcw)] which is explaining really well what a Service Mesh is.

[Istio](https://istio.io) is one of the Service Mesh out there, you could deploy it on any Kubernetes cluster; with this configuration you need to manage the setup, the update, as well as dealing with the fact that Istio and its components are sharing the same resources of your worloads within your cluster. This article [](https://cloud.google.com/blog/products/networking/welcome-to-the-service-mesh-era-introducing-a-new-istio-blog-post-series) provides more information about Istio and its components and features.
ASM on GKE: https://cloud.google.com/solutions/exposing-service-mesh-apps-through-gke-ingress
Ingress for Anthos: https://cloud.google.com/kubernetes-engine/docs/concepts/ingress-for-anthos
Anthos Service Mesh Deep Dive: https://cloud.google.com/blog/topics/anthos/anthos-service-mesh-deep-dive
Extending your Istio service mesh across GKE clusters and Compute Engine instances: https://cloud.google.com/solutions/extend-istio-service-mesh-across-gke-clusters-compute-instances
Ingress for Anthos - Multi-cluster Ingress and Global Service Load Balancing https://www.linkedin.com/pulse/ingress-anthos-multi-cluster-global-service-load-gokul-chandra/

Another step now is what if you would like a managed Istio service? Here comes Anthos Service Mesh (ASM)!
- ASM and Istio tutorial: https://cloud.google.com/solutions/exposing-service-mesh-apps-through-gke-ingress

The ultimate step is what if you would like a managed Service Mesh's Control Plane? Hhere comes Traffic Director!
- Traffic Director & Envoy-Based L7 ILB for Production-Grade Service Mesh & Istio (Cloud Next '19)
https://youtu.be/FUITCYMCEhU
- https://cloud.google.com/blog/products/networking/traffic-director-global-traffic-management-for-open-service-mesh
- https://medium.com/cloudzone/google-clouds-traffic-director-what-is-it-and-how-is-it-related-to-the-istio-service-mesh-c199acc64a6d
- https://cloud.google.com/traffic-director/docs/set-up-gke-pods-auto
- https://cloud.google.com/blog/products/networking/traffic-director-supports-proxyless-grpc

[Build an Enterprise-Grade Service Mesh with Traffic Director](https://cloud.withgoogle.com/next/sf/sessions?session=NET206#infrastructure) [[Youtube](https://youtu.be/QyxQfW-Izs8)]

> In a service mesh, your application code doesn't need to know about your networking configuration. Instead, your applications communicate over a data plane, which is configured by a control plane that handles service networking. In this guide, Traffic Director is your control plane and the Envoy sidecar proxies are your data plane.

Hope you enjoyed this blog article and hopefully you will be able to leverage such important features transparently if enabled ;)

Complementary and further resources:
- [Cloud Load Balancing Deep Dive and Best Practices (Cloud Next '18)](https://www.youtube.com/watch?v=J5HJ1y6PeyE)
- [GKE Networking Differentiators (Cloud Next '19)](https://www.youtube.com/watch?v=RjcjaXi-vVY&autoplay=1)
- [Scalable and Manageable: A Deep-Dive Into GKE Networking Best Practices (Cloud Next '19)](https://www.youtube.com/watch?v=fI-5LkBDap8)
- [What's new in network security on Google Cloud (Cloud Next '20)](https://www.youtube.com/watch?v=WFwGgo7ULXE)
- [Ready? A Deep Dive into Pod Readiness Gates for Service Health Management](https://www.youtube.com/watch?v=Vw9GmSeomFg)

Cheers! ;)