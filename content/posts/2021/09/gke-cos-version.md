---
title: check the cos version of your gke nodes
date: 2021-09-14
tags: [gcp, kubernetes, security]
description: let's see how to get the exact 
draft: true
aliases:
    - /gke-cos-version/
---
https://cloud.google.com/anthos/clusters/docs/security-bulletins#gcp-2021-017

As one of the best practice for your Security posture with GKE is to use an `cos-containerd` image type for your nodes.

Recently, I was curious to know more about the version of `containerd` and `COS` of my GKE nodes. Let's see how we could get these information.

Let's create a new dedicated cluster for the purpose of the setup of the following command lines throughout this blog article:
```
zone=us-east4-a
clusterName=test-cos-versions
gcloud container clusters create $clusterName \
    --zone=$zone \
    --image-type cos_containerd \
    --release-channel stable
```

We created a GKE cluster in the `stable` channel. `kubectl get nodes -o wide` gives the following information:
```
VERSION           KERNEL-VERSION   CONTAINER-RUNTIME
v1.18.20-gke.900  5.4.109+         containerd://1.4.3
```

Here we know that we are with the `5.4.109+` of the COS's `KERNEL-VERSION` and `1.4.3` of `containerd`. By using the default version of the channel, we could find the information about which specific version of COS we are using from [here](https://cloud.google.com/kubernetes-engine/docs/release-notes#current_versions): [`cos-85-13310-1260-22`](https://cloud.google.com/container-optimized-os/docs/release-notes/m85#cos-85-13310-1260-22) (dated from Jun 09, 2021 for `COS 85`). If we upgrade this cluster to the latest version in this `stable` channel (`1.19.12-gke.2100` as we speak), we could see that the version is now [`cos-85-13310-1260-26`](https://cloud.google.com/container-optimized-os/docs/release-notes/m85#cos-85-13310-1260-26) (dated from Jun 21, 2021 for `COS 85`).

One way to check the exact COS version is to run this ephemeral container `kubectl debug -it --image=busybox`

Now let's update our cluster to the next channel `regular` and see what we'll have with an upper GKE version:
```
# Change the release channel:
gcloud container clusters update $clusterName \
    --zone $zone \
    --release-channel regular
# Update the controlplane first with the default version of the new release channel:
gcloud container clusters upgrade $clusterName \
    --zone $zone \
    --master
# Update nodepools to align the controlplane:
gcloud container clusters upgrade $clusterName \
    --zone $zone
```
`kubectl get nodes -o wide` now gives the following information:
```
VERSION           KERNEL-VERSION   CONTAINER-RUNTIME
1.20.8-gke.900    5.4.104+         containerd://1.4.3
```
Here we know that we are with the `5.4.104+` of the COS's `KERNEL-VERSION` and `1.4.3` of `containerd`. By using the default version of the channel, we could find the information about which specific version of COS we are using from [here](https://cloud.google.com/kubernetes-engine/docs/release-notes#current_versions): [`cos-89-16108-403-46`](https://cloud.google.com/container-optimized-os/docs/release-notes/m89#cos-89-16108-403-46) (dated from Jun 08, 2021 for `COS 89`).

As I'm writing this blog article you will have the same result with the default version for the `rapid` channel which is the same as the `regular` channel: `1.20.8-gke.900`.

But interestingly if we take any version upper to this one on the `rapid` channel we could see these new and more up to date information:
```
VERSION           KERNEL-VERSION   CONTAINER-RUNTIME
1.20.9-gke.700    5.4.120+         containerd://1.4.4
```
Here we know that we are with the `5.4.120+` of the COS's `KERNEL-VERSION` and `1.4.4` of `containerd`. And by running `` and ``, we could see that the version is now [`cos-85-13310-1260-26`](https://cloud.google.com/container-optimized-os/docs/release-notes/m85#cos-85-13310-1260-26) (dated from Jun 21, 2021 for `COS 85`).



`v1.21.3-gke.110` --> `16108.470.1`
`v1.21.3-gke.2000` --> `16108.470.11`


Statements:
- COS doesn't have latest containerd version, `1.4.3` or `1.4.4` as opposed to `1.4.9`
- GKE doesn't have the latest COS version, `85-13310-1260-22`, `89-16108.403.46` as opposed to `89-16108-470-11` (`gcloud compute images list --project cos-cloud --no-standard-images`)

Recommendations:
- Autoupgrade
- Private GKE clusters to avoid Public IP on Nodes and avoid SSH.
- Policy controller (OPA Gatekeeper)
- Security bulletins alerts https://cloud.google.com/anthos/clusters/docs/security-bulletins

Resources:
https://cloud.google.com/kubernetes-engine/docs/release-schedule
https://cloud.google.com/container-optimized-os/docs/release-notes
https://cloud.google.com/container-optimized-os/docs/concepts/versioning

Stay safe out there, cheers!