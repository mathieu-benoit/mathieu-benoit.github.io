---
title: gke's service account
date: 2020-10-15
tags: [gcp, containers, kubernetes, security]
description: let's discuss about how to deal with gke's service account
draft: true
aliases:
    - /gke-service-account/
---
I just went through the description of this [CVE-2020-15157 "ContainerDrip" Write-up](https://darkbit.io/blog/cve-2020-15157-containerdrip). I found these information very insightful especially since there is some illustrations and great story with GCP and GKE.

> [CVE-2020-15157](https://nvd.nist.gov/vuln/detail/CVE-2020-15157): If an attacker publishes a public image with a crafted manifest that directs one of the image layers to be fetched from a web server they control and they trick a user or system into pulling the image, they can obtain the credentials used by `ctr/containerd` to access that registry. In some cases, this may be the user’s username and password for the registry. In other cases, this may be the credentials attached to the cloud virtual instance which can grant access to other cloud resources in the account.

Interesting! 

{{< youtube Z-JFVJZ-HDA >}}

https://code.kiwi.com/towards-secure-by-default-google-cloud-platform-service-accounts-244ad9fc772
https://medium.com/@jryancanty/stop-downloading-google-cloud-service-account-keys-1811d44a97d9
https://cloud.google.com/blog/products/identity-security/dont-get-pwned-practicing-the-principle-of-least-privilege

Sharing is caring, stay safe! ;)