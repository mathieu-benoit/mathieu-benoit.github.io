---
title: confidential computing with gke
date: 2020-10-28
tags: [gcp, kubernetes, security]
description: let's see how easy it is to enable confidential computing on a gke cluster
aliases:
    - /confidential-computing/
---
[Confidential Computing](https://cloud.google.com/confidential-computing) is an hardware based memory encryption to keep data and code protected when being processed. It's simple, easy-to-use deployment that doesn't compromise on performance:

{{< youtube id="RUFhIKFNshI" title="Confidential Computing: The next frontier in data protection">}}

You could now leverage Confidential Computing [with GKE, recently announced in Beta](https://cloud.google.com/blog/products/identity-security/confidential-gke-nodes-now-available):

{{< youtube id="1YPpNcOYJvo" title="How do I get started on Confidential GKE Nodes?">}}

So typically, here is the command to create your GKE cluster with Confidential Computing enabled:
```
gcloud beta container clusters create \
  --release-channel=rapid \
  --machine-type=n2d-standard-2 \
  --enable-confidential-nodes
```

And that's it, in addition to data encrypted at rest and in-transit, you now have data encrypted while being processed on your Confidential GKE Nodes! [Shielded GKE Nodes](https://cloud.google.com/kubernetes-engine/docs/how-to/shielded-gke-nodes) feature is also leveraged by default to offer protection against rootkit and bootkits, helping to ensure the integrity of the operating system you run on your Confidential GKE Nodes. It provides an even deeper and multi-layer defense-in-depth protection against data exfiltration attacks.

Furthermore, you don't need to do anything in your apps, you just need to deploy them as-is on your GKE cluster. But optionally, you could use the `nodeSelector` `cloud.google.com/gke-confidential-nodes: true` to ensure your sensitive workloads can only be scheduled on Confidential GKE Nodes.

Further and complementary resources:
- [Encryption in Transit in Google Cloud](https://cloud.google.com/security/encryption-in-transit/resources/encryption-in-transit-whitepaper.pdf)
- [Confidential GKE Nodes Limitations](https://cloud.google.com/kubernetes-engine/docs/how-to/confidential-gke-nodes#limitations)
- [Confidential computing consortium](https://confidentialcomputing.io/)

Hope you enjoyed that one, stay safe, cheers!
