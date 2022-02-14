---
title: gitops with config controller
date: 2022-02-14
tags: [gcp, kubernetes, security]
description: let's see with config controller how we could set up gitops to actually deploy kubernetes manifests
draft: true
aliases:
    - /config-controller-gitops/
    - /config-controller-config-sync/
---
So with the previous article about [Introduction to Config Controller in action](), you could ask these questions:
- _Ok, but that's a lot of `kubectl apply` commands... how to simplify this if I don't have access to the Config Controller endpoint for security and networking reasons?_
- _I thought Config Controller includes Config Sync too in order to deploy Kubernetes manifests in a GitOps way?_

Exactly, spot on! The previous article was already full of content and concetps to show the powers of Config Controller, but glad you asked, let's demonstrate this GitOps/Config Sync story now! ;)

