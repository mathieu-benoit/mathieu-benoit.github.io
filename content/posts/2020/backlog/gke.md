---
title: fixme
date: 2020-08-10
tags: [fixme]
description: fixme
draft: true
aliases:
    - /fixme/
---
Best practices for operating containers
https://cloud.google.com/solutions/best-practices-for-operating-containers
Preparing a Google Kubernetes Engine environment for production
https://cloud.google.com/solutions/prep-kubernetes-engine-for-prod


Understanding IP address management in GKE
https://cloud.google.com/blog/products/containers-kubernetes/ip-address-management-in-gke

Architecting with Google Kubernetes Engine: Workloads
https://www.coursera.org/learn/deploying-workloads-google-kubernetes-engine-gke

Cloud Native LB
https://cloud.google.com/kubernetes-engine/docs/concepts/container-native-load-balancing

Architecting with Google Kubernetes Engine: Production
https://www.coursera.org/learn/deploying-secure-kubernetes-containers-in-production


VPC versus Private Registry/Cluster
https://cloud.google.com/vpc-service-controls/docs/supported-products#build


https://medium.com/google-cloud/mitigating-data-exfiltration-risks-in-gcp-using-vpc-service-controls-part-1-82e2b440197

https://cloud.google.com/blog/products/identity-security/preventing-lateral-movement-in-google-compute-engine

- [Master authorized networks]()

https://cloud.google.com/kubernetes-engine/docs/concepts/types-of-clusters#vpc-clusters
- [VPC-native cluster](https://cloud.google.com/kubernetes-engine/docs/how-to/alias-ips)
    - Network Endpoint Groups (NEG) by annotating the Service with `cloud.google.com/neg: '{ingress": true}'`? Is it related/mandatory?

- [Harden workload isolation with GKE Sandbox](https://cloud.google.com/kubernetes-engine/docs/how-to/sandbox-pods)

https://www.youtube.com/watch?v=WFwGgo7ULXE
- VPC Firewall
- VPC Service Controls
- Packet Mirroring
- Cloud Armor (DDoS Protection + WAF) on Load Balancer


- CIDRs
- Nodepools Sandbox
- Workload identity

- [Scalable and Manageable: A Deep-Dive Into GKE Networking Best Practices (Cloud Next '19)](https://www.youtube.com/watch?v=fI-5LkBDap8)

https://cloud.google.com/solutions/prep-kubernetes-engine-for-prod
https://cloud.google.com/kubernetes-engine/docs/how-to/hardening-your-cluster

Load Balancing
https://cloud.google.com/blog/products/containers-kubernetes/exposing-services-on-gke
https://cloud.google.com/kubernetes-engine/docs/how-to/ingress-features
https://cloud.google.com/kubernetes-engine/docs/how-to/container-native-load-balancing
https://cloud.google.com/kubernetes-engine/docs/how-to/flexible-pod-cidr
https://cloud.google.com/load-balancing/docs/forwarding-rule-concepts