---
title: my third week with gcp
date: 2020-08-10
tags: [gcp, security, kubernetes]
description: let's share what I learned during my third week leveraging gcp, focused on gke
draft: true
aliases:
    - /third-week-with-gcp/
---
Continuing the discovery of GKE's features regarding resiliency, performance and security.
- Monitoring
- VPC

Google Cloud's Operations Suite on GKE
https://www.qwiklabs.com/quests/133

https://medium.com/google-cloud/mitigating-data-exfiltration-risks-in-gcp-using-vpc-service-controls-part-1-82e2b440197

https://cloud.google.com/blog/products/identity-security/preventing-lateral-movement-in-google-compute-engine

- [Master authorized networks]()

https://cloud.google.com/kubernetes-engine/docs/concepts/types-of-clusters#vpc-clusters
- [VPC-native cluster](https://cloud.google.com/kubernetes-engine/docs/how-to/alias-ips)
    - Network Endpoint Groups (NEG) by annotating the Service with `cloud.google.com/neg: '{ingress": true}'`? Is it related/mandatory?

- [Stackdriver Kubernetes monitoring and logging]()

- [Harden workload isolation with GKE Sandbox](https://cloud.google.com/kubernetes-engine/docs/how-to/sandbox-pods)

https://www.youtube.com/watch?v=WFwGgo7ULXE
- VPC Firewall
- VPC Service Controls
- Packet Mirroring
- Cloud Armor (DDoS Protection + WAF) on Load Balancer


- CIDRs

- [Scalable and Manageable: A Deep-Dive Into GKE Networking Best Practices (Cloud Next '19)](https://www.youtube.com/watch?v=fI-5LkBDap8)