---
title: my second week with gcp
date: 2020-08-01
tags: [gcp, security, kubernetes]
description: let's share what I learned during my second week leveraging gcp, focused on gke
draft: true
aliases:
    - /second-week-with-gcp/
---
https://cloud.google.com/kubernetes-engine/docs/how-to/managed-certs

```
staticIpName=myblog-static-ip
gcloud compute addresses create $staticIpName \
    --global
staticIpAddress=$(gcloud compute addresses describe $staticIpName \
    --global \
    --format "value(address)")
```

```
kubectl run myblog \
    --image=gcr.io/$projectId/myblog:3 \
    --generator=run-pod/v1
kubectl expose pod myblog \
    --type NodePort \
    --port=8080 \
    --target-port=8080
```

While running `kubectl apply -f managedcertificate.yaml` I got an error pointing me with the fact that I'm with a Kubernetes cluster with an unsupported version for this component: `v1.14.10-gke.36`. It happened that I used the default version when I created my GKE cluster, you could monitor which version is the default and when it changes at the official [GKE releases page](https://cloud.google.com/kubernetes-engine/docs/release-notes).

So that's a good opportunity for me to play with the [`gcloud container clusters upgrade`](https://cloud.google.com/kubernetes-engine/docs/how-to/upgrading-a-cluster) command.
```
clusterName=FIXME
zone=FIXME
# Update master first, just one minor version up to the current one:
kubectl version
gcloud container clusters upgrade $clusterName \
    --master \
    --cluster-version 1.15.12-gke.9 \
    --zone $zone
kubectl version

# Update nodes by aligning with master's version:
kubectl get nodes
gcloud container clusters upgrade $clusterName \
    --zone $zone
kubectl get nodes
```

Now I could successfuly run `kubectl apply -f managedcertificate.yaml`.

Now let's get few more insights and discoveries with my GKE cluster:
```
gcloud container clusters describe $clusterName \
    --zone $zone
```

Here are few features I would like to highlight:
- `addonsConfig.kubernetesDashboard.disabled: true`, which is great on a security standpoint. If you need more UI interactions with your GKE clusters you could securely leverage the [GKE Workloads menu in Cloud Console](https://cloud.google.com/kubernetes-engine/docs/how-to/deploying-workloads-overview#console).
- `addonsConfig.networkPolicyConfig.disabled: true`. Good news, you could enable/disable Network Policy (Calico) on your GKE cluster without recreating your cluster: `gcloud container clusters update --update-addons=NetworkPolicy=ENABLED`.
- `databaseEncryption.state: DECRYPTED`, you have the [option to encrypt your Kubernetes' Secrets via Cloud KMS](https://cloud.google.com/kubernetes-engine/docs/how-to/encrypting-secrets).
- `loggingService: logging.googleapis.com/kubernetes`, FIXME
- `monitoringService: monitoring.googleapis.com/kubernetes`, FIXME
- `network: default` and `subNetwork: default`, FIXME
- `location` and `zone`: Zone versus Region
- `nodeConfig.diskSizeGb: 100`, `diskType: pd-standard` and `machine-type: n1-standard-1`: FIXME
- `nodeConfig.imageType: COS`. Here are the [different Node image types you could use](https://cloud.google.com/kubernetes-engine/docs/how-to/node-images). On my end, I would like to go with `containerd` for a security standpoint, you could read more about the [differences between the `Docker/Moby` versus `containerd` approach](https://cloud.google.com/kubernetes-engine/docs/concepts/using-containerd) to see what fits best for your own context. I could actually upgrade my existing cluster with the new `COS_CONTAINERD` image type: `gcloud container clusters upgrade --image-type COS_CONTAINERD`
- `management.autoRepair: true` and `management.autoUpgrade: true` by default, which is really great and important: FIXME
- `shieldedNodes: {}`, more security node credentials boostrapping implementation, starting with version `1.18`, clusters will have shielded GKE nodes by default. FIXME for the link.

Other callouts:
- [NodeLocal DNSCache](https://cloud.google.com/kubernetes-engine/docs/how-to/nodelocal-dns-cache), if you think you have Kubernetes' DNS issues, great option for stability and performance within your cluster, especially with large clusters. Good news, you could enable/disable without recreating your cluster: `--update-addons NodeLocalDNS=ENABLED|DISABLED`.
- [Autoscaling]()
- [Binauthz]()
- [Intra-node visibility](https://cloud.google.com/kubernetes-engine/docs/how-to/intranode-visibility)
- [Master authorized networks]()
- [Stackdriver Kubernetes monitoring and logging]()
- [Vertical Pod autoscaling]()
- [Maintenance window]()
- [Release channel](): None, rapid, regular, stable.
- [VPC-native cluster](https://cloud.google.com/kubernetes-engine/docs/how-to/alias-ips)
- [Consuming reservations](https://cloud.google.com/kubernetes-engine/docs/how-to/consuming-reservations) - FIXME
- [Harden workload isolation with GKE Sandbox](https://cloud.google.com/kubernetes-engine/docs/how-to/sandbox-pods)

- Monitoring
- VPC
- Kured?
- Node OS update?

That's a lot of concepts for sure, but anyway, that's what we/you need to know and learn about to have a proper GKE cluster for Production. I don't know for you but I love the flexibility with the `update|upgrade` commands to be able to enable/disable features on existing GKE cluster without having to recreate a cluster.

Last week I went with this very simple command line to create a straight forward GKE cluster: `gcloud container clusters create --zone`. With few concepts about resiliency, performance and security discussed throughout this blog article, I will better go now on with:
```
gcloud container clusters create \
    --version 1.16.13-gke.1 \
    --zone \
    --machine-type n1-standard-1 \
    --image-type image-name COS_CONTAINERD \

FIXME:
- maxPod
- Subnet
- CIDRs
```
And I'm sure I missed few concepts and features, so I will adjust this snippet accordingly as I'm diving more deeply with GCP/GKE.

Awesome learnings, isn't it!? More to come during the coming weeks for sure, cheers!

Resources:
- [Scalable and Manageable: A Deep-Dive Into GKE Networking Best Practices (Cloud Next '19)](https://www.youtube.com/watch?v=fI-5LkBDap8)
- [GKE Release Notes](https://cloud.google.com/kubernetes-engine/docs/release-notes)
- [GKE Security Bulletin](https://cloud.google.com/kubernetes-engine/docs/security-bulletins)