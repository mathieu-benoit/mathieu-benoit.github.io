---
title: distroless asm proxy
date: 2021-12-13
tags: [gcp, security, kubernetes, service-mesh, containers]
description: fixme
draft: true
aliases:
    - /distroless-asm-proxy/
    - /asm-proxy/
---
[Anthos Service Mesh (ASM) 1.12](https://cloud.google.com/service-mesh/docs/release-notes#December_09_2021) now supports deploying a proxy built on the [distroless base image](https://istio.io/latest/docs/ops/configuration/security/harden-docker-images/).

> The distroless base image ensures that the proxy image contains the minimal number of packages required to run the proxy. This improves security posture by reducing the overall attack surface of the image and gets cleaner results with CVE scanners.

Here is in action how you could [leverage the distroless base image while installing ASM](https://cloud.google.com/service-mesh/docs/unified-install/options/enable-optional-features#distroless_proxy_image):
```
curl https://storage.googleapis.com/csm-artifacts/asm/asmcli_1.12 > ~/asmcli
chmod +x ~/asmcli
cat <<EOF > ditroless-proxy.yaml
---
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  meshConfig:
    defaultConfig:
      image:
        imageType: distroless
EOF
~/asmcli install \
    --project_id $projectId \
    --cluster_name $clusterName \
    --cluster_location $zone \
    --enable-all \
    --custom_overlay distroless-proxy.yaml
```

Then when you will inject the istio-proxy sidecar, it will use the distroless image.

If we look a little bit closer to the container images, we could see that we save 82MB with the distroless image:
```
REPOSITORY                       TAG                       IMAGE ID       CREATED        SIZE
gcr.io/gke-release/asm/proxyv2   1.12.0-asm.3-distroless   d24aa6379321   10 days ago    173MB
gcr.io/gke-release/asm/proxyv2   1.12.0-asm.3              7af54ec04d1c   10 days ago    255MB
```

Furtermore, if we do a container scanning, we could see that the distroless image has only 9 vulnerabilities as opposed to 26 for the other one.

Quite good news, isn't it!?

_Note: [when deploying your own gateways](https://cloud.google.com/service-mesh/docs/gateways), you may end up with `error   envoy config    listener '0.0.0.0_80' failed to bind or apply socket options: cannot bind '0.0.0.0:80': Permission denied`. That's because the distroless image runs as non root. You need to set explicit `targetPort` for the gateways's `Service` with `8080` or `8443` for example._

Hope you enjoyed that one to improve your security posture, stay safe out there! ;)