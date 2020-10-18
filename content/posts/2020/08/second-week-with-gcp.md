---
title: my second week with gcp
date: 2020-08-03
tags: [gcp, security, kubernetes]
description: let's share some learnings during my second week leveraging gcp, focused on gke
aliases:
    - /second-week-with-gcp/
---
[![](https://media-exp1.licdn.com/dms/image/C4E16AQHxLntx_KDIlA/profile-displaybackgroundimage-shrink_350_1400/0?e=1600905600&v=beta&t=n9sWYjd0vqL108qKfABjKX_5WDERMlE43wYS-tGbFr0)](https://media-exp1.licdn.com/dms/image/C4E16AQHxLntx_KDIlA/profile-displaybackgroundimage-shrink_350_1400/0?e=1600905600&v=beta&t=n9sWYjd0vqL108qKfABjKX_5WDERMlE43wYS-tGbFr0)

Since [last week]({{< ref "/posts/2020/07/first-week-with-gcp.md" >}}) and to continue the beginning of my learning journey with GCP, this week I would like to deep dive with GKE, around few advanced setup and features.

First I needed to complete the setup of this blog on GKE by setting up my SSL certificate and map my DNS https://alwaysupalwayson.com with the new Public IP address exposed. To accomplish this I'm using the [Google-managed SSL certificates](https://cloud.google.com/kubernetes-engine/docs/how-to/managed-certs) (which is still in Beta as we speak). Pretty straight forward by following the tutorial. I just needed to align the version of my cluster and the version of the Managed Certificates feature:
- < `1.16.5-gke.1` = `v1beta1`
- \>= `1.16.5-gke.1` = `v1beta2`

Create a Public static IP address:
```
staticIpName=myblog-static-ip
gcloud compute addresses create $staticIpName \
    --global
staticIpAddress=$(gcloud compute addresses describe $staticIpName \
    --global \
    --format "value(address)")
```
Grab this `$staticIpAddress` variable value and put it on my DNS where I host my domain name, it will guarantee that I own that domain for the following steps.
Then, I need to expose `myblog` with a `NodePort` Service:
```
$projectId=FIXME
kubectl run myblog \
    --image=gcr.io/$projectId/myblog \
    --generator=run-pod/v1
kubectl expose pod myblog \
    --type NodePort \
    --port=8080 \
    --target-port=8080
```
Create the `ManagedCertificate` resource:
```
domainName=FIXME
kubectl apply -f - <<EOF
apiVersion: networking.gke.io/v1beta2
kind: ManagedCertificate
metadata:
  name: myblog
spec:
  domains:
    - $domainName
EOF
```
And then, create the associated `Ingress` resource:
```
kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1beta1
kind: Ingress
metadata:
  name: myblog
  annotations:
    kubernetes.io/ingress.global-static-ip-name: $staticIpName
    networking.gke.io/managed-certificates: myblog
spec:
  backend:
    serviceName: myblog
    servicePort: 8080
EOF
```
After waiting for few minutes for the load balancer and the certificate to be provisioned, here we are, that's it! :metal: I have now `myblog` up-and-running with an SSL certificate configured: https://alwaysupalwayson.com :rocket:


That's cool, but now let's get more insights around the features of my current GKE cluster:
```
gcloud container clusters describe $clusterName \
    --zone $zone
```

`addonsConfig.kubernetesDashboard.disabled: true`, having the Kubernetes dashboard disabled by default is good practice on a security standpoint. If you need more UI interactions with your GKE clusters you could securely leverage the [GKE Workloads menu in Cloud Console](https://cloud.google.com/kubernetes-engine/docs/how-to/deploying-workloads-overview#console).

`addonsConfig.networkPolicyConfig.disabled: true`, [Network Policies](https://cloud.google.com/kubernetes-engine/docs/how-to/network-policy) is an important feature for your Security Posture with Kubernetes. By default it's not enabled, but good news, you could enable/disable Network Policy (Calico) on your GKE cluster without recreating your cluster: `gcloud container clusters update --update-addons=NetworkPolicy=ENABLED` or `gcloud container clusters update --enable-network-policy`. We could then apply few Network Policies like illustrated [here]({{< ref "/posts/2019/09/calico.md" >}}).

`currentMasterVersion` and `currentNodeVersion`, you could [learn more about Release channel](https://cloud.google.com/kubernetes-engine/docs/concepts/release-channels): `none`, `rapid`, `regular` or `stable`. `regular` is the default one, and `stable` is the one eligible for the [GKE's SLA](https://cloud.google.com/kubernetes-engine/sla). This Release Channel is how you could manage your GKE's version (master versus worker nodes, auto-upgrade, etc.). Complementary to this, we could see that `management.autoUpgrade: true` is by default, which is really great and important. [Maintenance windows and exclustions](https://cloud.google.com/kubernetes-engine/docs/concepts/maintenance-windows-and-exclusions) features will bring flexibility and fine-grained control with your upgrades.
_Note: There is also the concept of [Alpha clusters](https://cloud.google.com/kubernetes-engine/docs/concepts/alpha-clusters)._

`databaseEncryption.state: DECRYPTED`, you have the [option to encrypt your Kubernetes' Secrets (etcd) with your own key via Cloud KMS](https://cloud.google.com/kubernetes-engine/docs/how-to/encrypting-secrets).

`location` and `zone`: there is [3 choices regarding the availability](https://cloud.google.com/kubernetes-engine/docs/concepts/types-of-clusters#availability) of your cluster: Single-zone, Multi-zonal or Regional. If you choose a Region with 3 Zones, your will have the control plane nodes as well as the number of your nodes replicated on the 3 zones of that region. The choice to make your cluster Regional or Zonal will influence the [GKE's SLA](https://cloud.google.com/kubernetes-engine/sla) too.

`diskType: pd-standard`, for better performance for your workloads, but with a cost, you may want to opt-in for a [custom boot disk with SSD](https://cloud.google.com/kubernetes-engine/docs/how-to/custom-boot-disks): `pd-ssd`.

`machine-type: n1-standard-1` is by default with 1vCPU and 3.75GB memory (FYI: [soon it will be `e2-medium`](https://cloud.google.com/kubernetes-engine/docs/release-notes#july_28_2020_r25)). I found very interesting this session [Choosing the Right Compute Engine Instance Type for Your Workload](https://cloud.withgoogle.com/next/sf/sessions?session=CMP102) to see the differences between the [VM's families and types](https://cloud.google.com/compute/docs/machine-types). By default, you get benefit of the [Sustained used discounts](https://cloud.google.com/compute/docs/sustained-use-discounts), and you could also get more discounts with more commitments with [Commited use discounts](https://cloud.google.com/compute/docs/instances/signing-up-committed-use-discounts). Finally, you may want to [consume reservations with GKE](https://cloud.google.com/kubernetes-engine/docs/how-to/consuming-reservations).

`nodeConfig.diskSizeGb: 100`, choosing the proper size of your OS disk could be important, especially if you are facing application performance throttling. [The section](https://cloud.google.com/compute/docs/disks/performance#performance_factors) will guide you through the factors that affect performance between the OS disk and the Node type that you should be aware of.

`nodeConfig.imageType: COS`. Here are the [different Node image types you could use](https://cloud.google.com/kubernetes-engine/docs/how-to/node-images). On my end, I would like to go with `containerd` for a security standpoint, you could read more about the [differences between the `Docker/Moby` versus `containerd` approach](https://cloud.google.com/kubernetes-engine/docs/concepts/using-containerd) to see what fits best for your own context. I could actually upgrade my existing cluster with the new `COS_CONTAINERD` image type: `gcloud container clusters upgrade --image-type COS_CONTAINERD`.

`management.autoRepair: true`, [Nodes auto-repair](https://cloud.google.com/kubernetes-engine/docs/how-to/node-auto-repair) is enabled by default with version 1.17+, which is important to guarantee your nodes are healthy.

`shieldedNodes: {}`, [Shielded GKE nodes](https://cloud.google.com/kubernetes-engine/docs/how-to/shielded-gke-nodes) bring a more security node credentials boostrapping implementation, starting with version `1.18` clusters will have shielded GKE nodes by default. We could even update a current GKE cluster without this feature enabled at creation time: `gcloud container clusters update --enable-shielded-nodes`.

[NodeLocal DNSCache](https://cloud.google.com/kubernetes-engine/docs/how-to/nodelocal-dns-cache), if you think you have Kubernetes' DNS issues, great option for stability and performance within your cluster, especially with large clusters. Good news, you could enable/disable without recreating your cluster: `gcloud container clusters update --update-addons NodeLocalDNS=ENABLED|DISABLED`.

That's a lot of concepts and there is more for sure (VPC, Monitoring, etc.), but anyway, that's what you need to know and learn about to have a proper GKE cluster for Production. I don't know for you but I love the flexibility with the `gcloud container clusters update|upgrade` commands to be able to enable/disable features on existing GKE cluster without having to recreate a cluster.

Last week I went with this very simple command line to create a straight forward GKE cluster: `gcloud container clusters create --zone`. With few concepts and features about resiliency, performance and security discussed throughout this blog article, I will better go now on with:
```
gcloud container clusters create \
    --release-channel rapid \
    --region \
    --disk-type pd-ssd \
    --machine-type n2d-standard-2 \
    --disk-size 256 \
    --image-type cos_containerd \
    --enable-network-policy \
    --addons NodeLocalDNS \
    --enable-shielded-nodes \
    --shielded-secure-boot \
    --enable-autorepair \
    --enable-autoupgrade
```
And there is more concepts and features not discussed in this blog article, so I will adjust this snippet accordingly as I'm diving more deeply with GCP/GKE.

Complementary resources:
- [GKE Pricing](https://cloud.google.com/kubernetes-engine/pricing)
- [GKE Release Notes](https://cloud.google.com/kubernetes-engine/docs/release-notes)
- [GKE Security Bulletin](https://cloud.google.com/kubernetes-engine/docs/security-bulletins)
- [GKE Shared responsibilities](https://cloud.google.com/kubernetes-engine/docs/concepts/control-plane-security)

Awesome learnings, isn't it!? More to come during the coming weeks for sure, cheers!