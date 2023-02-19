---
title: kyverno
date: 2023-02-17
tags: [fixme]
description: fixme
draft: true
aliases:
    - /kyverno/
---
I needed to give Kyverno a try, to learn more about it. Here we are!

KubeCon NA 2022...
https://nirmata.com/2022/11/07/policy-governance-and-automation-crossed-the-chasm-at-kubecon-north-america-2022/

Most recently: https://nirmata.com/2023/02/07/notes-from-cloud-native-securitycon-2023/

In this blog post we will illustrate how to:
- Create a Policy to enforce that any Pod should have a required label
- Evaluate the Policy with the Kyverno CLI
- Evaluate the Policy in a Kubernetes cluster

Kyverno has other powerful features we won’t cover here:
- [Mutate resources](https://kyverno.io/docs/writing-policies/mutate/)
- [Generate resources](https://kyverno.io/docs/writing-policies/generate/)
- [Test policies](https://kyverno.io/docs/testing-policies/)

## Create a Policy to enforce that any `Pod` should have a required label

Create a dedicated folder for the associated files:
```bash
mkdir -p policies
```

Define our first policy to require label `app.kubernetes.io/name` for any `Pods`:
```bash
cat <<EOF > policies/pod-require-name-label.yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: pod-require-name-label
spec:
  validationFailureAction: Enforce
  rules:
  - name: check-for-name-label
    match:
      any:
      - resources:
          kinds:
          - Pod
    exclude:
      any:
      - resources:
          namespaces:
          - my-namespace-excluded
    validate:
      message: "label 'app.kubernetes.io/name' is required"
      pattern:
        metadata:
          labels:
            app.kubernetes.io/name: "?*"
EOF
```
_In this example we also illustrate that we don’t want this Policy to be enforced in our `my-namespace-excluded` namespace. Note that by default, Kyverno skips any Policies in the following namespaces: `kyverno`, `kube-system`, `kube-public` and `kube-node-lease`. You can learn more about this resource filters configuration [here](https://kyverno.io/docs/installation/#resource-filters)._

Policies library - https://kyverno.io/policies/
Install policies for PSS: https://kyverno.io/policies/pod-security/

## Evaluate the Policy with the Kyverno CLI

Define locally a Deployment without the required label:
```bash
kubectl create deployment nginx --image=nginx --dry-run=client -o yaml > deploy-without-name-label.yaml
```

Test locally the Policy against this deployment:
```bash
kyverno apply policies/ -r deploy-without-name-label.yaml
```
Output similar to:
```plaintext
Applying 1 policy rule to 1 resource...

policy pod-require-name-label -> resource default/Deployment/nginx failed:
1. autogen-check-for-name-label: validation error: label 'app.kubernetes.io/name' is required. rule autogen-check-for-name-label failed at path /spec/template/metadata/labels/app.kubernetes.io/name/

pass: 0, fail: 1, warn: 0, error: 0, skip: 2
```
Wow, wait! What just happened?!

We just used the [Kyverno CLI](https://kyverno.io/docs/kyverno-cli) to evaluate the Policy against our local Deployment file. This client makes it very convenient to test policies without any Kubernetes cluster! We can for example integrate this test during our Continuous Integration (CI) pipelines.

Another very important concept we just illustrated is the [Auto-Gen rules for Pod Controllers](https://kyverno.io/docs/writing-policies/autogen/) feature. In our case, we defined our Policy on Pods, but in our test, we evaluate this Policy against a Deployment definition. Very powerful feature here, the non compliant `Deployment` resource is directly blocked!

## Evaluate the Policy in a Kubernetes cluster

Create an existing deployment without the required label:
```bash
kubectl apply -f deploy-without-name-label.yaml
```

Deploy the Policy in the cluster:
```bash

```

Try to deploy the deployment without the required label:
```bash
kubectl apply -f deploy-without-name-label.yaml
```
Output similar to:
```plaintext
FIXME
```

Check that the existing deployment without the required label is reported:
https://kyverno.io/docs/writing-policies/background/

## Create a Policy to enforce that any container image should be signed with Cosign

https://kyverno.io/docs/writing-policies/verify-images/

## Create a Policy to enforce that any container image should have a required data in its manifest

https://kyverno.io/docs/writing-policies/external-data-sources/#variables-from-image-registries

## Bundle and share Policies as OCI images

[Manage policies as OCI images](https://kyverno.io/docs/kyverno-cli/#oci)

One way to store and share your Policies is to store them in a Git repository. But another option is to store them in an OCI registry. The Kyverno CLI allows to `push` and `pull` Policies as OCI image with your OCI registry.

Bundle and push our Policies in our OCI registry:
```bash
REGISTRY=FIXME
kyverno oci push -i $REGISTRY/policies:1 --policy policies/
```

Check the OCI image manifest:
```bash
oras manifest fetch $REGISTRY/policies:1 | jq
```
Output similar to:
```plaintext
{
  "schemaVersion": 2,
  "mediaType": "application/vnd.oci.image.manifest.v1+json",
  "config": {
    "mediaType": "application/vnd.cncf.kyverno.config.v1+json",
    "size": 233,
    "digest": "sha256:40d87721b725bf77c87e102d4e4564a2a8efe94140a81eeef0c8d690ab83acec"
  },
  "layers": [
    {
      "mediaType": "application/vnd.cncf.kyverno.policy.layer.v1+yaml",
      "size": 740,
      "digest": "sha256:83ba733ea934fce32f88be938e12e9ae14f6c3a1c743cde238df02462d1bb2ee",
      "annotations": {
        "io.kyverno.image.apiVersion": "kyverno.io/v1",
        "io.kyverno.image.kind": "ClusterPolicy",
        "io.kyverno.image.name": "pod-require-name-label"
      }
    }
  ]
}
```

From here, you can use `kyverno pull` to download these policies.

## Conclusion

I’m very impressed, like any Policies engine you can create policies to add more security and governance in your Kubernetes clusters. But Kyverno can do way more than just that, in a simple manner.