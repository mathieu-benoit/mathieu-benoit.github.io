---
title: fixme
date: 2020-08-10
tags: [fixme]
description: fixme
draft: true
aliases:
    - /fixme/
---
https://www.coursera.org/specializations/architecting-google-kubernetes-engine
--> https://www.coursera.org/learn/deploying-workloads-google-kubernetes-engine-gke
--> https://www.coursera.org/learn/deploying-secure-kubernetes-containers-in-production

GCP's Ops Suite on GKE - https://www.qwiklabs.com/quests/133
```
--enable-stackdriver-kubernetes
```
https://cloud.google.com/stackdriver/docs/solutions/gke/observing
Logging --> Kubernetes Container, stackdriver-logging, default

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

502 - backend_connection_closed_before_data_sent_to_client
https://console.cloud.google.com/support/cases/detail/24439599?project=coretech-ludia
Ingress (pas nginx) + POST
3 (try 10) gateway
https://blog.percy.io/tuning-nginx-behind-google-cloud-platform-http-s-load-balancer-305982ddb340#.btzyusgi6
https://amoss.me/2019/01/debugging-http-502-errors-on-google-kubernetes-engine/
https://groups.google.com/g/gce-discussion/c/7ETsl0YH1iQ
https://medium.com/@gaplyk/tcp-i-o-timeouts-on-gke-9896c7066258