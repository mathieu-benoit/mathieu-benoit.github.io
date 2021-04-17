---
title: ebpf and cilium, to bring more security and more networking capabilities in gke
date: 2021-04-17
tags: [security, containers, kubernetes, gcp]
description: let's see ebpf and cilium on gke and how they are bringing more security and networking capabilities
aliases:
    - /gke-ebpf/
    - /gke-cilium/
---
![Google, GKE, eBF and Cilium logo.](https://cilium.io/static/1a5e48f755419401103235a6a01de4fd/906b5/google_header.png)

> Extended Berkeley Packet Filter (eBPF) is a new Linux networking paradigm that exposes programmable hooks to the network stack inside the Linux kernel. The ability to enrich the kernel with user-space information—without jumping back and forth between user and kernel spaces—enables context-aware operations on network packets at high speeds.

> Cilium is an open source project that has been designed on top of eBPF to address the new scalability, security and visibility requirements of container workloads. Cilium goes beyond a traditional Container Networking Interface (CNI) to provide service resolution, policy enforcement and much more as seen in the picture below.

![Cilium, beyond the traditional Kubernetes CNI.](https://storage.googleapis.com/gweb-cloudblog-publish/images/Container_Networking_Interface.max-1100x1100.jpg)

Last August 2020, I wrote a blog article about [4 main networking features GCP is providing for your GKE clusters]({{< ref "/posts/2020/09/container-native-networking.md" >}}), the GKE Dataplane V2 was one of them. I haven't tested this feature until today, but today is the day! ;)

> [GKE Dataplane V2](https://cloud.google.com/kubernetes-engine/docs/how-to/dataplane-v2) is an opinionated dataplane that harnesses the power of eBPF and Cilium.

On [Cilium’s blog article for the announcement](https://cilium.io/blog/2020/08/19/google-chooses-cilium-for-gke-networking), you could also read the story behind that partnership between Cilium, Google and actually the broad open source community, I love that!

> Google clearly has incredible technical chops and could have just built their dataplane directly on eBPF, instead, the GKE team has decided to leverage Cilium and contribute back. This is of course a huge honor for everybody who has contributed to Cilium over the years and shows Google’s commitment to open collaboration.

Even if it's still in `Beta`, let's see it in actions with GKE!

First, let's create a new cluster [using Dataplane V2](https://cloud.google.com/kubernetes-engine/docs/how-to/dataplane-v2):
```
gcloud beta container clusters create \
    --enable-dataplane-v2
```

_Note: Dataplane V2 comes with network policy enforcement built-in. This means that you don't need to enable network policy in clusters that use Dataplane V2. As of today, if you try to explicitly enable or disable network policy enforcement in a cluster that uses Dataplane V2, the request will fail._

From here, you could apply your [`NetworkPolicies`]({{< ref "/posts/2019/09/calico.md" >}}) like you used to do with any Kubernetes cluster. But there is more. You could actually leverage the associated [network policy logging](https://cloud.google.com/kubernetes-engine/docs/how-to/network-policy-logging) (both `allow` and `deny`). For this you need to enable them with the below example:
```
kind: NetworkLogging
apiVersion: networking.gke.io/v1alpha1
metadata:
  name: default
spec:
  cluster:
    allow:
      log: true
      delegate: false
    deny:
      log: true
      delegate: false
```

And from here for any `deny` logs for example, you will be able to see them via Cloud Logging:
```
projectName=FIXME
clusterLocation=FIXME
clusterName=FIXME

filter="resource.type=\"k8s_node\" "\
"jsonPayload.disposition=\"deny\" "\
"resource.labels.location=\"${clusterLocation}\" "\
"resource.labels.cluster_name=\"${clusterName}\" "\
"logName=\"projects/${projectId}/logs/policy-action\""

gcloud logging read --project $projectId "$filter"
```

_Tips: if your cluster is enrolled with Anthos, you will also be able to see the number of those `deny` logs on the **Anthos > Security > Policy Summary > Kubernetes network policy** page._

And that's it, that's how easy Cilium (eBPF) on GKE is bringing more security and more visibility for containers. I don't know for you, but the `NetworkLogging` is game changer for me, I finally and easily have visibility on `deny` logs with my `NetworkPolicies`!

Further and complementary resources:
- [eBPF - The Future of Networking & Security](https://cilium.io/blog/2020/11/10/ebpf-future-of-networking/)
- [New GKE Dataplane V2 increases security and visibility for containers](https://cloud.google.com/blog/products/containers-kubernetes/bringing-ebpf-and-cilium-to-google-kubernetes-engine)

Hope you enjoyed that one, stay safe out there, cheers!