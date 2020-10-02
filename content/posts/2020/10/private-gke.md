---
title: private gke cluster
date: 2020-08-10
tags: [gcp, kubernetes, security]
description: let's see how to properly setup a totally private gke cluster
draft: true
aliases:
    - /private-gke/
---
https://gkesecurity.guide/
https://medium.com/google-cloud/completely-private-gke-clusters-with-no-internet-connectivity-945fffae1ccd
https://github.com/andreyk-code/no-inet-gke-cluster


--> https://cloud.google.com/kubernetes-engine/docs/how-to/private-clusters#gcloud

# Networking

Talk about Cloud Nat: https://cloud.google.com/nat/docs/gke-example

```
network=mygkecluster-network
subnet=mygkecluster-subnet
gcloud compute networks create $network \
  --subnet-mode custom
gcloud compute networks subnets create $subnet \
  --network $network \
  --range 10.10.10.0/24 \
  --region us-central1 \
  --enable-private-ip-google-access \
  --secondary-range services=10.10.11.0/24,pods=10.1.0.0/16
  # 10.0.0.0/24 --> 10.2.0.0/20 --> 10.1.0.0/16
  # 192.168.0.0/20 --> 10.0.32.0/20 --> 10.4.0.0/14
  # 10.5.0.0/20 --> 10.4.0.0/19 --> 10.0.0.0/14
  #* 10.150.0.0/20 --> 10.53.16.0/25 --> 10.53.0.0/20
```

# Private GKE clusters

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
  --enable-master-authorized-networks \
  --network $network \
  --subnetwork $subnet \
  --cluster-secondary-range-name pods \
  --services-secondary-range-name services \
```

> From other VMs in the cluster's VPC network, you can use `kubectl` to communicate with the private endpoint only if they are in the same region as the cluster and either their internal IP addresses are included in the list of master authorized networks or they are located in the same subnet as the cluster's nodes.

# Jumpbox

https://cloud.google.com/solutions/connecting-securely#bastion
https://medium.com/google-cloud/how-to-ssh-into-your-gce-machine-without-a-public-ip-4d78bd23309e

# Google Container Registry

https://cloud.google.com/vpc-service-controls/docs/set-up-gke

# Cloud Build

https://cloud.google.com/vpc-service-controls/docs/supported-products#build
https://cloud.google.com/access-context-manager/docs/create-basic-access-level#members-example



region=us-east4
randomSuffix=$(shuf -i 100-999 -n 1)
clusterName=mygkecluster$randomSuffix
gcloud container clusters create $clusterName \
    --workload-metadata-from-node SECURE \
    --release-channel rapid \
    --region $region \
    --disk-type pd-ssd \
    --machine-type n2d-standard-2 \
    --disk-size 256 \
    --image-type cos_containerd \
    --enable-network-policy \
    --addons NodeLocalDNS,HttpLoadBalancing \
    --enable-shielded-nodes \
    --shielded-secure-boot \
    --enable-ip-alias \
    --enable-autorepair \
    --enable-autoupgrade \
    --enable-stackdriver-kubernetes \
    --max-pods-per-node 30 \
    --default-max-pods-per-node 30 \
    --services-ipv4-cidr '/25' \
    --cluster-ipv4-cidr '/20' \
    --enable-master-authorized-networks \
    --enable-private-nodes \
    --enable-private-endpoint

Complementary and further resources:
- [Preparing a Google Kubernetes Engine environment for production](https://cloud.google.com/solutions/prep-kubernetes-engine-for-prod)
- [Hardening your cluster's security](https://cloud.google.com/kubernetes-engine/docs/how-to/hardening-your-cluster)
- [Preventing lateral movement in Google Compute Engine](https://cloud.google.com/blog/products/identity-security/preventing-lateral-movement-in-google-compute-engine)
- [Mitigating Data Exfiltration Risks in GCP using VPC Service Controls](https://medium.com/google-cloud/mitigating-data-exfiltration-risks-in-gcp-using-vpc-service-controls-part-1-82e2b440197)