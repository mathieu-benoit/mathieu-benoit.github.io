---
title: fixme
date: 2020-08-10
tags: [fixme]
description: fixme
draft: true
aliases:
    - /fixme/
---
https://cloud.google.com/service-mesh/docs/release-notes#December_09_2021

> Anthos Service Mesh now supports deploying a proxy built on the distroless base image. The distroless base image ensures that the proxy image contains the minimal number of packages required to run the proxy. This improves security posture by reducing the overall attack surface of the image and gets cleaner results with CVE scanners.

https://cloud.google.com/service-mesh/docs/unified-install/options/enable-optional-features#distroless_proxy_image

docker pull gcr.io/gke-release/asm/proxyv2:1.12.0-asm.3
docker pull gcr.io/gke-release/asm/proxyv2:1.12.0-asm.3-distroless

docker images
REPOSITORY                       TAG                       IMAGE ID       CREATED        SIZE
gcr.io/gke-release/asm/proxyv2   1.12.0-asm.3-distroless   d24aa6379321   10 days ago    173MB
gcr.io/gke-release/asm/proxyv2   1.12.0-asm.3              7af54ec04d1c   10 days ago    255MB


https://github.com/istio/istio/issues/35902

2021-12-11T14:05:39.566883Z     error   envoy config    listener '0.0.0.0_80' failed to bind or apply socket options: cannot bind '0.0.0.0:80': Permission denied
2021-12-11T14:05:39.567281Z     warning envoy config    gRPC config for type.googleapis.com/envoy.config.listener.v3.Listener rejected: Error adding/updating listener(s) 0.0.0.0_80: cannot bind '0.0.0.0:80': Permission denied