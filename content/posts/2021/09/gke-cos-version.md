---
title: gke cos version
date: 2021-09-21
tags: [gcp, kubernetes, security]
description: let's see how to get the cos version of your gke nodes 
aliases:
    - /gke-cos-version/
---
One of the best practices for your Security posture with GKE is to use a `cos-containerd` image type for your GKE nodes.

> Based on Chromium OS, [Container-Optimized OS](https://cloud.google.com/container-optimized-os/docs/concepts/security) from Google implements several security design principles to provide a well-configured platform for running production services.

> The [`containerd`](https://cloud.google.com/kubernetes-engine/docs/concepts/using-containerd) runtime is considered more resource efficient and secure when compared to the `Docker` runtime.

Recently, I was curious to know the versions of `containerd` and `COS` of my GKE nodes. Let's see how we could get these information.

Let's create a new dedicated cluster as the setup for the following command lines throughout this blog article:
```
zone=us-east4-a
clusterName=test-cos-versions
gcloud container clusters create $clusterName \
    --zone=$zone \
    --image-type cos_containerd \
    --release-channel stable \
    --num-nodes 2
```

We created a GKE cluster in the `stable` channel. `kubectl get nodes -o wide` gives the following information:
```
VERSION           KERNEL-VERSION   CONTAINER-RUNTIME
v1.19.12-gke.2101 5.4.109+         containerd://1.4.3
```

We know that we are with the `5.4.109+` of the COS's `KERNEL-VERSION` and `1.4.3` of `containerd`. By using the default version of the channel, we could find the information about which specific version of COS we are using from [here](https://cloud.google.com/kubernetes-engine/docs/release-notes#current_versions): [`cos-85-13310-1308-1`](https://cloud.google.com/container-optimized-os/docs/release-notes/m85#cos-85-13310-1308-1) (dated from Jul 12, 2021 for `COS 85`). 

Now let's update our cluster to the next version available in the `stable` channel and see what we'll have with this new version:
```
newVersion=1.19.13-gke.701 # latest version for the stable channel when I wrote this blog
gcloud container clusters upgrade $clusterName --master \
    --zone $zone \
    --cluster-version $newVersion \
    --quiet
gcloud container clusters upgrade $clusterName \
    --zone $zone \
    --quiet
```

`kubectl get nodes -o wide` now gives the following information:
```
VERSION           KERNEL-VERSION   CONTAINER-RUNTIME
1.19.13-gke.701   5.4.129+         containerd://1.4.6
```

Let's check the exact COS version by running this ephemeral container (or you could `ssh` to the GCE):
```
node=$(kubectl get nodes -o jsonpath='{.items[0].metadata.name}')
kubectl debug -it node/$node --image=busybox -- cat /host/etc/os-release
```
We could see that the version is now [`cos-85-13310.1308.1`](https://cloud.google.com/container-optimized-os/docs/release-notes/m85#cos-85-13310-1308-1) (dated from Jul 12, 2021 for `COS 85`).

Now let's update our cluster to the next channel `regular` and see what we'll have with this new version:
```
# Change the release channel:
gcloud container clusters update $clusterName \
    --zone $zone \
    --release-channel regular
# Update the controlplane first with the default version of the new release channel:
gcloud container clusters upgrade $clusterName \
    --zone $zone \
    --master \
    --quiet
# Update nodepools to align the controlplane:
gcloud container clusters upgrade $clusterName \
    --zone $zone \
    --quiet
```

From there we could repeat the previous command lines in order to get the `containerd` and the COS versions for the different GKE versions. As the result, the table below will summarize the different versions found for the three channels: `stable`, `regular` and `rapid`:

| Channel | Kubernetes | Kernel | COS | containerd |
|---|---|---|---|---|
| stable | 1.19.12-gke.2101 | 5.4.109 | [cos-85-13310-1308-1](https://cloud.google.com/container-optimized-os/docs/release-notes/m85#cos-85-13310-1308-1) | 1.4.3 |
| stable | 1.19.13-gke.701 | 5.4.129 | [cos-85-13310.1308.1](https://cloud.google.com/container-optimized-os/docs/release-notes/m85#cos-85-13310-1308-1) | 1.4.6 |
| regular | 1.20.9-gke.701 | 5.4.120 | [cos-89-16108.470.1](https://cloud.google.com/container-optimized-os/docs/release-notes/m89#cos-89-16108-470-1) | 1.4.4 |
| regular | 1.20.9-gke.1001 | 5.4.120 | [cos-89-16108.470.1](https://cloud.google.com/container-optimized-os/docs/release-notes/m89#cos-89-16108-470-1) | 1.4.4 |
| rapid | 1.21.3-gke.2001 | 5.4.120 | [cos-89-16108.470.11](https://cloud.google.com/container-optimized-os/docs/release-notes/m89#cos-89-16108-470-11) | 1.4.4 |
| rapid | 1.21.4-gke.301 | 5.4.120 | [cos-89-16108.470.11](https://cloud.google.com/container-optimized-os/docs/release-notes/m89#cos-89-16108-470-11) | 1.4.4 |

Here are few statements (which will change in the future since updates for GKE or COS happen every week):
- COS doesn't have latest `containerd` version, we see `1.4.3`, `1.4.4` or `1.46` as opposed to latest today `1.4.9` or `1.5.5`
- GKE doesn't have the latest COS version, `85-13310-1308-1`, `89-16108.470.1` or `89-16108.470.11` as opposed to latest or lts `89-16108-534-2` (`gcloud compute images list --project cos-cloud --no-standard-images`)

Is it an issue? Not at all! Because GKE integrates well tested and stable COS images and provide guidance with its [security bulletins](https://cloud.google.com/anthos/clusters/docs/security-bulletins) when necessary.

Is it something to keep in mind? Yes for sure? 

_Note: on 2021-11-19, GKE got the version v1.22.3-gke.700 with associated `containerd` version `1.5.4`, `COS 93` version [`cos-93-16623-39-6`](https://cloud.google.com/container-optimized-os/docs/release-notes/m93#cos-93-16623-39-6) and `COS Kernel` version `5.10.68`._ 

When dealing with a manged Kubernetes service, in this case GKE, there is a [shared responsibilities model](https://cloud.google.com/blog/products/containers-kubernetes/exploring-container-security-the-shared-responsibility-model-in-gke-container-security-shared-responsibility-model-gke) to have in mind. And one of them is to make sure your GKE cluster is up-to-date, [node auto-upgrade](https://cloud.google.com/kubernetes-engine/docs/how-to/node-auto-upgrades) to the rescue! Node auto-upgrade is upgrading your cluster to the new default version of channel of your GKE cluster. You may also want in some cases to [manually update your cluster](https://cloud.google.com/kubernetes-engine/docs/how-to/upgrading-a-cluster) to the latest version in that channel.

In addition to by [default secured features enabled](https://cloud.google.com/kubernetes-engine/docs/how-to/hardening-your-cluster#secure_defaults), here is also couple of features you could leverage in order to mitigate let's say a known CVE on your GKE nodes:
- [Private GKE clusters](https://cloud.google.com/kubernetes-engine/docs/how-to/private-clusters)
- [Policy controller (OPA Gatekeeper)]({{< ref "/posts/2021/03/policy-controller.md" >}})
- [Binary Authorization]({{< ref "/posts/2020/11/binauthz.md" >}})
- [Container Threat detection with SCC](https://cloud.google.com/security-command-center/docs/concepts-container-threat-detection-overview)
- and many more!

Complementary and further resources:
- [`containerd` releases](https://github.com/containerd/containerd/releases)
- [GKE release schedule](https://cloud.google.com/kubernetes-engine/docs/release-schedule)
- [Container-Optimized OS Release Notes](https://cloud.google.com/container-optimized-os/docs/release-notes)
- [COS LTS Refresh releases](https://cloud.google.com/container-optimized-os/docs/concepts/versioning#lts_refresh_releases)
- [GKE Release notes](https://cloud.google.com/kubernetes-engine/docs/release-notes)
- [Hardening your cluster's security](https://cloud.google.com/kubernetes-engine/docs/how-to/hardening-your-cluster)

Hope you enjoyed that one, stay safe out there, cheers!