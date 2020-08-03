Infrastructure Quest and select the IAM Qwik Start lab: https://goo.gl/ez5Vzw

https://medium.com/google-cloud/mitigating-data-exfiltration-risks-in-gcp-using-vpc-service-controls-part-1-82e2b440197

https://medium.com/@jryancanty/stop-downloading-google-cloud-service-account-keys-1811d44a97d9

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

- [Scalable and Manageable: A Deep-Dive Into GKE Networking Best Practices (Cloud Next '19)](https://www.youtube.com/watch?v=fI-5LkBDap8)