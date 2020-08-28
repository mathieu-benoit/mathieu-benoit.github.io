---
title: fixme
date: 2020-08-10
tags: [fixme]
description: fixme
draft: true
aliases:
    - /fixme/
---
To continue my learning with GKE, [my first week with GCP](FIXME) was about deploying manually a containerized app on a basic/default GKE cluster. [My second week with GCP](FIXME) was about to fine-tune a little bit my GKE cluster with more features. My third week was about deploying a containerized app on GKE via Cloud Build and GCR. And this week will be dedicated on more advanced setups focused on networking.

FIXME - For this, I'm still leveraging these two resources:
- [Preparing a Google Kubernetes Engine environment for production](https://cloud.google.com/solutions/prep-kubernetes-engine-for-prod)
- [Hardening your cluster's security](https://cloud.google.com/kubernetes-engine/docs/how-to/hardening-your-cluster)

# FIXME - Private clusters

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

To check:
- VPC versus Private Registry/Cluster
https://cloud.google.com/vpc-service-controls/docs/supported-products#build
- https://medium.com/google-cloud/mitigating-data-exfiltration-risks-in-gcp-using-vpc-service-controls-part-1-82e2b440197
- https://cloud.google.com/blog/products/identity-security/preventing-lateral-movement-in-google-compute-engine
- https://cloud.google.com/kubernetes-engine/docs/concepts/types-of-clusters#vpc-clusters

# FIXME - VPC/Subnet/CIDRs
    - https://cloud.google.com/kubernetes-engine/docs/how-to/alias-ips#cluster_sizing
    - https://cloud.google.com/vpc/docs/alias-ip
    - https://cloud.google.com/kubernetes-engine/docs/how-to/flexible-pod-cidr
Understanding IP address management in GKE
https://cloud.google.com/blog/products/containers-kubernetes/ip-address-management-in-gke
Recommended to have 30 pods per node max, after this as you will scale your nodes you could overload your master nodes.