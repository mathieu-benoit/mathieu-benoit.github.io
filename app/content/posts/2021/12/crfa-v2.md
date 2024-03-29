---
title: crfa v2 with asm
date: 2021-12-06
tags: [gcp, containers, kubernetes, service-mesh]
description: let's see how the new crfa v2 is leveraging asm
aliases:
    - /crfa-v2/
---
_Update on March 2022, [CRfAv2 got Knative service version 1.1.2](https://cloud.google.com/anthos/run/docs/release-notes#February_23_2022) and [ASM MCP can be installed via the Fleet API](https://cloud.google.com/service-mesh/docs/managed/auto-control-plane-with-fleet)._

[On July 2021]({{< ref "/posts/2021/07/crfa.md" >}}) I was blogging about Cloud Run for Anthos (CRfA), but today I will go through its new version, CRfA v2, and its new integration with Anthos Service Mesh (ASM).

That's the same experience based on Knative like illustrated during this recent session about CRfA during Google Cloud Next 2021:
{{< youtube id="uNhgTQw8sUc" title="Using Cloud Run for Anthos for hybrid and multicloud architectures">}}

So, what's new? What are the differences between v1 and v2? [Here you are](https://cloud.google.com/anthos/run/docs/install#newandchanged). What I will illustrate today and the most excited update according to me is the integration with ASM.

> ASM now decouples CRfA from your service mesh administration and maintenance tasks. It brings your installation to parity with the rest of Anthos and also removes the dependencies and limitations of the previously bundled Istio version.

If you have GKE clusters running CRfA v1, [here the upgrade guide to v2](https://cloud.google.com/anthos/run/docs/install/on-gcp/upgrade).

What I will cover today is creating from scratch a brand new GKE cluster with ASM and CRfA, let's see this in actions!

Let's use a given project:
```
projectId=FIXME
gcloud config set project $projectId
projectNumber=$(gcloud projects describe $projectId --format='get(projectNumber)')
```

Create a GKE cluster:
```
zone=FIXME
clusterName=FIXME
gcloud services enable container.googleapis.com
gcloud container clusters create $clusterName \
    --zone=$zone \
    --workload-pool=$projectId.svc.id.goog \
    --labels mesh_id=proj-$projectNumber
```

Register the GKE cluster as an Anthos Fleet:
```
gcloud services enable \
    anthos.googleapis.com \
    gkehub.googleapis.com
gcloud container hub memberships register $clusterName \
    --gke-cluster $zone/$clusterName \
    --enable-workload-identity
```

[Install ASM MCP](https://cloud.google.com/service-mesh/docs/managed/auto-control-plane-with-fleet) for this GKE cluster:
```
gcloud services enable \
    mesh.googleapis.com
gcloud container hub mesh enable
gcloud alpha container hub mesh update \
    --control-plane automatic \
    --membership $clusterName
```

After a few minutes, verify that the control plane `state` is `ACTIVE` and `code` is `REVISION_READY`:
```
gcloud alpha container hub mesh describe
```
Take note of the revision label in the `description:` field, `asm-managed` in the provided output. That's the [ASM release channel](https://cloud.google.com/service-mesh/docs/managed/select-a-release-channel) your GKE cluster is in.

Deploy a public [Ingress Gateway](https://cloud.google.com/service-mesh/docs/gateways):
```
ingressNamespace=asm-ingress
ingressName=asm-ingressgateway
ingressLabel='asm: ingressgateway'
asmRevision=asm-managed
cat <<EOF | kubectl apply -n $ingressNamespace -f -
apiVersion: v1
kind: Namespace
metadata:
  name: asm-ingress
  labels:
    istio.io/rev: ${asmRevision}
---
apiVersion: v1
kind: Service
metadata:
  name: ${ingressName}
  labels:
    ${ingressLabel}
spec:
  ports:
  - name: http
    port: 80
    targetPort: 80
  selector:
    ${ingressLabel}
  type: LoadBalancer
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ${ingressName}
spec:
  selector:
    matchLabels:
      ${ingressLabel}
  template:
    metadata:
      annotations:
        inject.istio.io/templates: gateway
      labels:
        ${ingressLabel}
    spec:
      containers:
      - name: istio-proxy
        image: auto
EOF
```

[Install CRfA](https://cloud.google.com/anthos/run/docs/install/on-gcp/custom) in our GKE cluster:
```
gcloud container hub cloudrun enable
cat <<EOF > cloudrun.yaml
apiVersion: operator.run.cloud.google.com/v1alpha1
kind: CloudRun
metadata:
  name: cloud-run
spec:
  serving:
    ingressService:
      name: ${ingressName}
      namespace: ${ingressNamespace}
      labels:
        ${ingressLabel}
EOF
gcloud container hub cloudrun apply \
    --gke-cluster $zone/$clusterName \
    --config=cloudrun.yaml
```

Deploy a sample app:
```
namespace=helloworld
kubectl create ns $namespace
kubectl label namespace $namespace istio-injection- istio.io/rev=$asmRevision --overwrite
gcloud run deploy helloworld \
    --platform gke \
    --image gcr.io/knative-samples/helloworld-go \
    --cluster=$clusterName \
    --cluster-location=$zone \
    --namespace $namespace
curl http://helloworld.$namespace.kuberun.$elbIp.nip.io/
```

Here you are, that's a wrap!

From here you could now leverage advanced ASM/Istio features for more security like I described in this [secure your apps and your cluster with ASM]({{< ref "/posts/2021/11/asm-security.md" >}}) blog article, where I talk about Istio CNI, mTLS `STRICT`, `AuthorizationPolicy`, `Sidecar`, HTTPS GCLB with Cloud Armor, etc.

Complementary and further resources:
- [CRfA release notes](https://cloud.google.com/anthos/run/docs/release-notes)
- [Additional setups with CRfA like internal ingress gateway, workload identity, etc.](https://cloud.google.com/anthos/run/docs/setup)
- [Knative on Istio - KubeCon Europe 2019](https://static.sched.com/hosted_files/kccnceu19/5f/Knative-on-Istio.pdf)
- [Performance tuning and best practices in a Knative based, large-scale serverless platform with Istio](https://events.istio.io/istiocon-2021/slides/b7p-PerformanceTuningKnative-GongZhang-YuZhuang.pdf)

Hope you enjoyed that one, cheers! ;)
