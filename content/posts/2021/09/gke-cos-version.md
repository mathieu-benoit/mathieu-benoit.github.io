---
title: gke cos version
date: 2021-09-21
tags: [gcp, kubernetes, security]
description: let's see how to get the version of the cos version of your gke nodes 
draft: true
aliases:
    - /gke-cos-version/
---
As one of the best practices for your Security posture with GKE is to use a `cos-containerd` image type for your nodes.

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

Statements:
- COS doesn't have latest containerd version, `1.4.3` or `1.4.4` as opposed to `1.4.9`
- GKE doesn't have the latest COS version, `85-13310-1260-22`, `89-16108.403.46` as opposed to `89-16108-470-11` (`gcloud compute images list --project cos-cloud --no-standard-images`)

Recommendations:
- Autoupgrade
- Private GKE clusters to avoid Public IP on Nodes and avoid SSH.
- Policy controller (OPA Gatekeeper)
- Security bulletins alerts https://cloud.google.com/anthos/clusters/docs/security-bulletins

Complementary and further resources:
- [`containerd` releases](https://github.com/containerd/containerd/releases)
- [GKE release schedule](https://cloud.google.com/kubernetes-engine/docs/release-schedule)
- [Container-Optimized OS Release Notes](https://cloud.google.com/container-optimized-os/docs/release-notes)
- [COS LTS Refresh releases](https://cloud.google.com/container-optimized-os/docs/concepts/versioning#lts_refresh_releases)
- [GKE Release notes](https://cloud.google.com/kubernetes-engine/docs/release-notes)
- [GKE Security bulletins](https://cloud.google.com/anthos/clusters/docs/security-bulletins)

Hope you enjoyed that one, stay safe out there, cheers!