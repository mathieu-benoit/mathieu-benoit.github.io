---
title: ebpf and cilium, to bring more security and more networking capabilities in gke
date: 2020-08-10
tags: [fixme]
description: fixme
draft: true
aliases:
    - /gke-ebpf/
---
> Enter Extended Berkeley Packet Filter (eBPF), a new Linux networking paradigm that exposes programmable hooks to the network stack inside the Linux kernel.

Last August 2020, I wrote a blog article about [4 main networking features GCP is providing for your GKE clusters]({{< ref "/posts/2020/09/container-native-networking.md" >}}).

> GKE Dataplane V2 is an opinionated dataplane that harnesses the power of eBPF and Cilium, an open source project that makes the Linux kernel Kubernetes-aware using eBPF.

On Cilium’s blog article for the announcement, you could also read the story behind that partnership between Cilium, Google and actually the broad open source community, I love that!

> Google clearly has incredible technical chops and could have just built their dataplane directly on eBPF, instead, the GKE team has decided to leverage Cilium and contribute back. This is of course a huge honor for everybody who has contributed to Cilium over the years and shows Google’s commitment to open collaboration.

https://cloud.google.com/blog/products/containers-kubernetes/bringing-ebpf-and-cilium-to-google-kubernetes-engine
https://cloud.google.com/kubernetes-engine/docs/how-to/dataplane-v2
https://cilium.io/blog/2020/08/19/google-chooses-cilium-for-gke-networking
https://cilium.io/blog/2020/11/10/ebpf-future-of-networking/

Even if it's still in Beta, let's it in actions!

First, let's create a new cluster [using Dataplane V2](https://cloud.google.com/kubernetes-engine/docs/how-to/dataplane-v2):
```
gcloud beta container clusters create cluster-name \
    --enable-dataplane-v2 \
    {--region region-name | --zone zone-name}
```

_Dataplane V2 comes with network policy enforcement built-in. This means that you don't need to enable network policy in clusters that use Dataplane V2. If you try to explicitly enable or disable network policy enforcement in a cluster that uses Dataplane V2, the request will fail._

From here, you could apply your `NetworkPolicies`. But there is more. You could actually leverage the associated [network policy logging](https://cloud.google.com/kubernetes-engine/docs/how-to/network-policy-logging) (both allow and deny). For this you need to enable them with the below example:
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

And from here for any deny logs, you will be able to see them via Cloud Logging:
```
projectName=FIXME
clusterLocation=FIXME
clusterName=FIXME

filter="resource.type=\"k8s_node\" "\
"resource.labels.location=\"${clusterLocation}\" "\
"resource.labels.cluster_name=\"${clusterName}\" "\
"logName=\"projects/${projectId}/logs/policy-action\""

gcloud logging read --project $projectId "$filter"
```

_Tips: if your cluster is enrolled with Anthos, you will be able to see the number those `deny` logs on the Anthos > Security > Policy Summary > Kubernetes network policy page.