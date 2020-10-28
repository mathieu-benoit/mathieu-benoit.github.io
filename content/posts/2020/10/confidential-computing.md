---
title: confidential computing with gke
date: 2020-10-28
tags: [gcp, kubernetes, security]
description: let's see how easy it is to enable confidential computing on a gke cluster
aliases:
    - /confidential-computing/
---
> Hardware based memory encryption to keep data and code protected when being processed.

{{< youtube RUFhIKFNshI >}}

You could now leverage Confidential Computing [with GKE, recently announced in Beta](https://cloud.google.com/blog/products/identity-security/confidential-gke-nodes-now-available):

{{< youtube 1YPpNcOYJvo >}}

So typically, here is the command to create your GKE cluster with Confidential Computing enabled:
```
gcloud beta container clusters create \
  --release-channel=rapid \
  --machine-type=n2d-standard-2 \ 
  --enable-confidential-nodes
```

And that's it in addition to data encrypted at rest and in transit, you now have data encrypted while being processed! Furthermore, you don't need to do anything in your apps, you just need to deploy them as usual on your GKE cluster.

Further and complementary resources:
- [Encryption in Transit in Google Cloud](https://cloud.google.com/security/encryption-in-transit/resources/encryption-in-transit-whitepaper.pdf)
- [Confidential Computing](https://cloud.google.com/confidential-computing)
- [Limitations](https://cloud.google.com/kubernetes-engine/docs/how-to/confidential-gke-nodes#limitations)
- [Confidential computing consortium](https://confidentialcomputing.io/)

Hope you enjoyed that one, cheers!