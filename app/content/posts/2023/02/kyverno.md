---
title: kyverno
date: 2023-02-17
tags: [fixme]
description: fixme
draft: true
aliases:
    - /kyverno/
---
I wanted to give Kyverno a try, to learn more about it. Here we are!

When I was attending KubeCon NA 2022, I noticed the [maturity and importance of Kyverno](https://nirmata.com/2022/11/07/policy-governance-and-automation-crossed-the-chasm-at-kubecon-north-america-2022/). Concrete use cases and advanced scenarios presented by customers and partners piqued my curiosity. With the recent [Cloud Native SecurityCon 2023](https://nirmata.com/2023/02/07/notes-from-cloud-native-securitycon-2023/), same feeling.

In this blog post we will illustrate how to:
- Create a policy to enforce that any Pod should have a required label
- Evaluate the policy with the Kyverno CLI
- Evaluate the policy in a Kubernetes cluster
- Create a policy to enforce that any container image should be signed with Cosign
- Bundle and share policies as OCI images

Kyverno has other powerful features we won’t cover here:
- [Use external data sources in Policies](https://kyverno.io/docs/writing-policies/external-data-sources)
- [Mutate resources](https://kyverno.io/docs/writing-policies/mutate/)
- [Generate resources](https://kyverno.io/docs/writing-policies/generate/)
- [Test policies](https://kyverno.io/docs/testing-policies/)

## Create a policy to enforce that any `Pod` should have a required label

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
          - kube-system
    validate:
      message: "label 'app.kubernetes.io/name' is required"
      pattern:
        metadata:
          labels:
            app.kubernetes.io/name: "?*"
EOF
```
_Note: In this example we also illustrate that we don’t want this policy to be enforced in the `kube-system` namespace._

Policies library - https://kyverno.io/policies/
Install policies for PSS: https://kyverno.io/policies/pod-security/

## Evaluate the policy with the Kyverno CLI

Define locally a Deployment without the required label:
```bash
kubectl create deployment nginx --image=nginx --dry-run=client -o yaml > deploy-without-name-label.yaml
```

Test locally the policy against this deployment:
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

We just used the [Kyverno CLI](https://kyverno.io/docs/kyverno-cli) to evaluate the policy against our local Deployment file. This client makes it very convenient to test policies without any Kubernetes cluster! We can for example integrate this test during our Continuous Integration (CI) pipelines.

Another very important concept we just illustrated is the [Auto-Gen rules for Pod Controllers](https://kyverno.io/docs/writing-policies/autogen/) feature. In our case, we defined our policy on Pods, but in our test, we evaluate this policy against a Deployment definition. Very powerful feature here, the non compliant `Deployment` resource is directly blocked!

## Evaluate the policy in a Kubernetes cluster

You can [install Kyverno](https://kyverno.io/docs/installation/) in any Kubernetes cluster.

Deploy a deployment without the required label:
```bash
kubectl create deployment nginx --image=nginx
```

Deploy the policy in the cluster:
```bash
kubectl apply -f policies/pod-require-name-label.yaml
```

Try to deploy a deployment without the required label:
```bash
kubectl create deployment nginx2 --image=nginx
```
Output similar to:
```plaintext
error: failed to create deployment: admission webhook "validate.kyverno.svc-fail" denied the request: 

policy Deployment/default/nginx2 for resource violation: 

pod-require-name-label:
  autogen-check-for-name-label: 'validation error: label ''app.kubernetes.io/name''
    is required. rule autogen-check-for-name-label failed at path /spec/template/metadata/labels/app.kubernetes.io/name/'
```

Check that the existing deployment without the required label is reported:
```bash
kubectl get policyreport -A
```
Output similar to:
```plaintext
NAMESPACE   NAME                          PASS   FAIL   WARN   ERROR   SKIP   AGE
default     cpol-pod-require-name-label   0      3      0      0       0      5m40s
kyverno     cpol-pod-require-name-label   6      0      0      0       0      5m40s
```
_Note: We are seeing 3 `FAIL` for our deployment in the `default` namespace because there is one error for each resource: the `Deployment`, its `ReplicaSet` and its `Pod`._

This [policy report](https://kyverno.io/docs/policy-reports/) is in place with policies with [`background: true`](https://kyverno.io/docs/writing-policies/background/), which is the default value for any policy.

You can see the error message by running this command: `kubectl get policyreport cpol-pod-require-name-label -n default -o yaml`.

## Create a Policy to enforce that any container image should be signed with Cosign

https://kyverno.io/docs/writing-policies/verify-images/

Get the nginx container image in your private registry
```bash
REGISTRY=FIXME
oras cp docker.io/library/nginx:latest $REGISTRY/nginx:latest
```

Get the associated digest of this image:
```bash
SHA=$(oras manifest fetch $REGISTRY/nginx:latest --descriptor --pretty | jq -r .digest)
```

Generate a public-private key pair with Cosign:
```bash
cosign generate-key-pair
```

Sign the container image with Cosign:
```bash
cosign sign --key cosign.key $REGISTRY/nginx@$SHA
```

## Bundle and share policies as OCI images

[Manage policies as OCI images](https://kyverno.io/docs/kyverno-cli/#oci)

One way to store and share your policies is to store them in a Git repository. But another option is to store them in an OCI registry. The Kyverno CLI allows to `push` and `pull` policies as OCI image with your OCI registry.

Bundle and push our policies in our OCI registry:
```bash
REGISTRY=FIXME
kyverno oci push -i $REGISTRY/policies:1 --policy policies/
```

Check the OCI image manifest:
```bash
oras manifest fetch $REGISTRY/policies:1 --pretty
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

I’m very impressed, like any policies engine you can create policies to add more security and governance in your Kubernetes clusters. But Kyverno can do way more than just that, and in a simple manner.