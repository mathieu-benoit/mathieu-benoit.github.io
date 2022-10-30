---
title: grpc health probes with kubernetes 1.24+
date: 2022-10-29
tags: [gcp, kubernetes]
description: let's see how we could leverage the new kubernetes 1.24+ grpc health probes features with the onlineboutique sample apps
aliases:
    - /grpc-health-probes/
---
gRPC health probes are natively supported in beta [since Kubernetes 1.24+](https://kubernetes.io/blog/2022/05/13/grpc-probes-now-in-beta/). Before that we needed to add the [`grpc_health_probe` binary in each `Dockerfile`](https://cloud.google.com/blog/topics/developers-practitioners/health-checking-your-grpc-servers-gke).

Since the recent version v0.4.0, the Online Boutique sample provide an option to have its applications supporting this feature. This allows to leverage the native Kubernetes feature as a well as decreasing the size of the container images by 4MB (virtual) and 11MB (on disk) as well as reducing the maintenance and surface of attack that this `grpc_health_probe` binary was added.

## What's the differences?

In your `Dockerfile`, you don't need to [add the `grpc_health_probe` binary like we needed to previously](https://cloud.google.com/blog/topics/developers-practitioners/health-checking-your-grpc-servers-gke):
```dockerfile
RUN GRPC_HEALTH_PROBE_VERSION=v0.4.14 && \
    wget -qO/bin/grpc_health_probe https://github.com/grpc-ecosystem/grpc-health-probe/releases/download/${GRPC_HEALTH_PROBE_VERSION}/grpc_health_probe-linux-amd64 && \
    chmod +x /bin/grpc_health_probe
```

In the Kubernetes manifests for your `Deployments`, here is the updates for example for the `adservice` for both the `readinessProbe` and the `livenessProbe`:
```diff
+           grpc:
+             port: 9555
-           exec:
-             command:
-             - /bin/grpc_health_probe
-             - -addr=:9555
```

## How to deploy the Online Boutique sample with this new feature?

Create a GKE cluster in version 1.24+:
```bash
gcloud container clusters create tests \
    --zone=us-east4-a \
    --machine-type=e2-standard-2 \
    --num-nodes=4 \
    --release-channel=rapid
```
_Note: the default version of [GKE in rapid channel has now been 1.24 for a while](https://cloud.google.com/kubernetes-engine/docs/release-notes-rapid)._

From there, let's deploy the Online Boutique sample with the gRPC health probes experimental variation.

Get the remote Kustomize components:
```bash
mkdir container-images-tag
curl -L https://raw.githubusercontent.com/GoogleCloudPlatform/microservices-demo/main/kustomize/components/native-grpc-health-check/kustomization.yaml > native-grpc-health-check/kustomization.yaml
```

Update the local Kustomize components:
```bash
ONLINE_BOUTIQUE_VERSION=$(curl -s https://api.github.com/repos/GoogleCloudPlatform/microservices-demo/releases | jq -r '[.[]] | .[0].tag_name')
sed -i "s/ONLINE_BOUTIQUE_VERSION/$ONLINE_BOUTIQUE_VERSION/g" native-grpc-health-check/kustomization.yaml
```

Configure the Kustomize overlay:
```bash
cat <<EOF> kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
- github.com/GoogleCloudPlatform/microservices-demo/kustomize/base
components:
- native-grpc-health-check
EOF
```

And deploy it:
```bash
kubectl apply -k .
```

If you wait a little bit, when all the `Pods` are running, you should have your Online Boutique website working successfully.

That's how easy we were able the new [native gRPC health probes with Kubernetes 1.24+](https://kubernetes.io/blog/2022/05/13/grpc-probes-now-in-beta/).

The Online Boutique sample apps are not supporting by default this native gRPC health probes, that's why we need to use Kustomize to use the [associated Kustomize overlay](https://github.com/GoogleCloudPlatform/microservices-demo/tree/main/kustomize/components/native-grpc-health-check).

Happy sailing, cheers!