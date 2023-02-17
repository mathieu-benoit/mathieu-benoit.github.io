---
title: kyverno
date: 2023-02-17
tags: [fixme]
description: fixme
draft: true
aliases:
    - /kyverno/
---
I needed to give Kyverno a try, to learn more about it, here we are!

KubeCon NA 2022...
https://nirmata.com/2022/11/07/policy-governance-and-automation-crossed-the-chasm-at-kubecon-north-america-2022/

Most recently: https://nirmata.com/2023/02/07/notes-from-cloud-native-securitycon-2023/

I’m very impressed, like any Policies engine you can create policies to add more security and governance in your Kubernetes clusters. But Kyverno can do way more than just that, in a simple manner. Let me show you. In this blog post we will illustrate how to:
- Create a Policy to enforce that any Pod should have a required label
- Evaluate the Policy with the Kyverno CLI
- Evaluate the Policy in a Kubernetes cluster

Kyverno has other powerful features we won’t cover here:
- Mutate resources - https://kyverno.io/docs/writing-policies/mutate/
- Generate resources - https://kyverno.io/docs/writing-policies/generate/
- Test policies - https://kyverno.io/docs/testing-policies/
- Manage policies as OCI images - https://kyverno.io/docs/kyverno-cli/#oci

## Create a Policy to enforce that any `Pod` should have a required label

Create a dedicated folder for the associated files:
```bash
mkdir -p policies
```

Define our first policy to require label `app.kubernetes.io/name` for any `Pods` in non-system namespaces:
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
          - kube-system
    validate:
      message: "label 'app.kubernetes.io/name' is required"
      pattern:
        metadata:
          labels:
            app.kubernetes.io/name: "?*"
EOF
```

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

We just used the Kyverno CLI to evaluate the Policy against our Deployment file, and this locall, without any Kubernetes cluster. This client makes it very convenient to test policies without any Kubernetes cluster! We can for example integrate this test during our Continuous Integration (CI) pipelines.

Another concept we just illustrated is 
 + https://kyverno.io/docs/writing-policies/autogen/

## Evaluate the Policy in a Kubernetes cluster

Create an existing deployment without the required label:
FIXME

Deploy the Policy in the cluster
Try to deploy the deployment without the required label:
FIXME

https://kyverno.io/docs/writing-policies/background/

Policies library - https://kyverno.io/policies/
Install policies for PSS: https://kyverno.io/policies/pod-security/