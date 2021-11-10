---
title: secure your apps and you cluster with anthos service mesh
date: 2021-11-08
tags: [gcp, security, kubernetes, service-mesh]
description: let's see how you could protect and secure both your apps and your cluster with anthos service mesh (asm)
draft: true
aliases:
    - /asm-security/
---
Even if I already covered how to [protect your service mesh with an HTTPS GCLB and Cloud Armor](), I thought I will describe in more details what are your other options to protect your workloads on GKE thanks to [Anthos Service Mesh (ASM)]().

Here are 7 easy steps to accomplish this:
1. Install ASM
2. Enable ASM with your apps
3. Enable mTLS `STRICT`
4. Define `AuthorizationPolicies`
5. Configure an `IngressGateway`
6. Leverage HTTPS GCLB and Cloud Armor

**First**, you need to install ASM in your cluster:
```
asmcli install \
    --project_id $projectId \
    --cluster_name $clusterName \
    --cluster_location $zone \
    --enable-all \
    --option cni-gcp
```
Note: pay attention to this `--option cni-gcp` which is important if... FIXME

Here, ASM/Istio is installed by not leveraged.

Second, you need 

Ultimately, here is the secure setup we have been trough with this blog article, the OnlineBoutique demo is now more secured. Hope you will be able to leverage this for your own apps/setup.

![Secured OnlineBoutique with advanced ASM setup discussed throughout that blog article.](asm-security.png)

Hope you enjoyed that one, stay safe out there! ;)