---
title: kyverno
date: 2023-02-20
tags: [kubernetes, policies, security]
description: let’s see the capabilities of kyverno to manage policies in kubernetes cluster
aliases:
    - /kyverno/
---
I wanted to give [Kyverno](https://kyverno.io/) a try, to learn more about it. Here we are!

When I was attending KubeCon NA 2022, I noticed the [maturity and importance of Kyverno](https://nirmata.com/2022/11/07/policy-governance-and-automation-crossed-the-chasm-at-kubecon-north-america-2022/). Concrete use cases and advanced scenarios presented by customers and partners piqued my curiosity. With the recent [Cloud Native SecurityCon 2023](https://nirmata.com/2023/02/07/notes-from-cloud-native-securitycon-2023/), same feeling.

In this blog post we will illustrate how to:
- [Create a policy to enforce that any Pod should have a required label](#create-a-policy-to-enforce-that-any-pod-should-have-a-required-label)
- [Evaluate the policy locally with the Kyverno CLI](#evaluate-the-policy-locally-with-the-kyverno-cli)
- [Evaluate the policy in a Kubernetes cluster](#evaluate-the-policy-in-a-kubernetes-cluster)
- [Create a policy to enforce that any container image should be signed with Cosign](#create-a-policy-to-enforce-that-any-container-image-should-be-signed-with-cosign)
- [Bundle and share policies as OCI images](#bundle-and-share-policies-as-oci-images)

## Create a policy to enforce that any `Pod` should have a required label

Create a dedicated folder for the associated files:
```bash
mkdir -p policies
```

Define our first policy to require the label `app.kubernetes.io/name` for any `Pods`:
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
          - kyverno
    validate:
      message: "label 'app.kubernetes.io/name' is required"
      pattern:
        metadata:
          labels:
            app.kubernetes.io/name: "?*"
EOF
```
_Note: In this example we also illustrate that we don’t want this policy to be enforced in the `kube-system` and `kyverno` namespaces._

Kyverno has a library of policies (https://kyverno.io/policies/). This library is very helpful, we can deploy the ready-to-use policies as well as taking inspiration of them to write our own custom policies.

## Evaluate the policy locally with the Kyverno CLI

Define locally a `Deployment` without the required label:
```bash
kubectl create deployment nginx \
    --image=nginx \
    --dry-run=client \
    -o yaml > deploy-without-name-label.yaml
```

Test locally the policy against this `Deployment`:
```bash
kyverno apply policies/ \
    -r deploy-without-name-label.yaml
```
Output similar to:
```plaintext
Applying 1 policy rule to 1 resource...

policy pod-require-name-label -> resource default/Deployment/nginx failed:
1. autogen-check-for-name-label: validation error: label 'app.kubernetes.io/name' is required. rule autogen-check-for-name-label failed at path /spec/template/metadata/labels/app.kubernetes.io/name/

pass: 0, fail: 1, warn: 0, error: 0, skip: 2
```
Wow, wait! What just happened?!

We just used the [Kyverno CLI](https://kyverno.io/docs/kyverno-cli) to evaluate the policy against our local `Deployment` file. This client makes it very convenient to test policies without any Kubernetes cluster. We can for example integrate this test during our Continuous Integration (CI) pipelines.

Another very important concept we just illustrated is the [Auto-Gen rules for Pod Controllers](https://kyverno.io/docs/writing-policies/autogen/) feature. In our case, we defined our policy on Pods, but in our test, we evaluate this policy against a Deployment definition. The non compliant `Deployment` resource is directly blocked.

## Evaluate the policy in a Kubernetes cluster

[Install Kyverno](https://kyverno.io/docs/installation/) in any Kubernetes cluster.

Deploy a `Deployment` without the required label that we will reuse later in this post:
```bash
kubectl create deployment nginx \
    --image=nginx
```

Deploy the policy in the cluster:
```bash
kubectl apply \
    -f policies/pod-require-name-label.yaml
```

Try to deploy a `Deployment` without the required label:
```bash
kubectl create deployment nginx2 \
    --image=nginx
```
Output similar to:
```plaintext
error: failed to create deployment: admission webhook "validate.kyverno.svc-fail" denied the request: 

policy Deployment/default/nginx2 for resource violation: 

pod-require-name-label:
  autogen-check-for-name-label: 'validation error: label ''app.kubernetes.io/name''
    is required. rule autogen-check-for-name-label failed at path /spec/template/metadata/labels/app.kubernetes.io/name/'
```
Great, any `Pod` (or associated resources like `Deployment`, `ReplicaSet`, `Job`, `Daemonset`, etc.) needs to have this required label, otherwise they can’t be deployed.

Check that the existing `Deployment` without the required label is reported too:
```bash
kubectl get policyreport -A
```
Output similar to:
```plaintext
NAMESPACE   NAME                          PASS   FAIL   WARN   ERROR   SKIP   AGE
default     cpol-pod-require-name-label   0      2      0      0       0      5m40s
```

This [policy report](https://kyverno.io/docs/policy-reports/) is in place with policies with [`background: true`](https://kyverno.io/docs/writing-policies/background/), which is the default value for any policy.

We can see the error message by running the following command:
```bash
kubectl get policyreport cpol-pod-require-name-label \
    -n default \
    -o yaml
```

## Create a Policy to enforce that any container image should be signed with Cosign

Let’s now illustrate an advanced scenario where we want to make sure that [any container images deployed in our cluster is signed by Cosign with our own signature](https://kyverno.io/docs/writing-policies/verify-images/).

Get the `nginx` container image in our private registry to illustrate this section. We use the [ORAS CLI](https://oras.land/) for this:
```bash
PRIVATE_REGISTRY=FIXME
oras cp docker.io/library/nginx:latest $PRIVATE_REGISTRY/nginx:latest
```

Get the associated digest of this image:
```bash
SHA=$(oras manifest fetch $PRIVATE_REGISTRY/nginx:latest \
    --descriptor \
    | jq -r .digest)
```

Generate a public-private key pair with [Cosign](https://docs.sigstore.dev/cosign/overview/):
```bash
cosign generate-key-pair
```

Sign the container image with Cosign:
```bash
cosign sign \
    --key cosign.key $PRIVATE_REGISTRY/nginx@$SHA
```

Define the policy to require the appropriate Cosign signature for the container images of any `Pods`:
```bash
cat <<EOF > policies/container-images-need-to-be-signed.yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: container-images-need-to-be-signed
spec:
  validationFailureAction: Enforce
  rules:
  - name: container-images-need-to-be-signed
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
          - kyverno
    verifyImages:
      - imageReferences:
        - "*"
        attestors:
        - count: 1
          entries:
          - keys:
              secret:
                name: cosign-public-key
                namespace: default
EOF
```

Create the associated `Secret` with our Cosign signature public key:
```bash
kubectl create secret generic cosign-public-key \
    --from-file=cosign.pub
```

Deploy this policy:
```bash
kubectl apply \
    -f policies/container-images-need-to-be-signed.yaml
```

Try to deploy a `Deployment` without the appropriate container image signed:
```bash
kubectl create deployment nginx2 \
    --image=nginx
```
Output similar to:
```plaintext
error: failed to create deployment: admission webhook "mutate.kyverno.svc-fail" denied the request: 

policy Deployment/default/nginx2 for resource violation: 

container-images-need-to-be-signed:
  autogen-container-images-need-to-be-signed: |
    failed to verify image docker.io/nginx:latest: .attestors[0].entries[0].keys: no matching signatures:
```
Great, any `Pod` (or associated resources like `Deployment`, `ReplicaSet`, `Job`, `Daemonset`, etc.) needs to have its container images signed by Cosign, otherwise they can’t be deployed.

Deploy a `Pod` with the appropriate container image signed earlier and with the required label:
```bash
kubectl run nginx3 \
    --image $PRIVATE_REGISTRY/nginx@$SHA \
    --labels app.kubernetes.io/name=nginx
```
Success! Wow, congrats! We just enforced that any container images deployed in our cluster should be signed.

## Bundle and share policies as OCI images

Let’s use one more feature of the [Kyverno CLI](https://kyverno.io/docs/kyverno-cli).

One way to store and share our policies is to store them in a Git repository. But another option is to store them in an OCI registry. The Kyverno CLI allows to [`push` and `pull` policies as OCI image](https://kyverno.io/docs/kyverno-cli/#oci) with our OCI registry.

Bundle and push our policies in our OCI registry:
```bash
kyverno oci push \
    -i $PRIVATE_REGISTRY/policies:1 \
    --policy policies/
```

Check the OCI image manifest:
```bash
oras manifest fetch $PRIVATE_REGISTRY/policies:1 --pretty
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

From here, we can use `kyverno pull` to download these policies.

## Conclusion

I’m very impressed by the capabilities of Kyverno. Like any policies engine we can manage policies to add more security and governance in our Kubernetes clusters. But Kyverno can do way more than just that, and in a simple manner. The two features illustrated in this post which blow my mind are: [check the image signatures](https://kyverno.io/docs/writing-policies/verify-images/) and [automatically generate rules for `Pod` controllers](https://kyverno.io/docs/writing-policies/autogen/).

Kyverno has more powerful features we didn’t cover in this post:
- [Use external data sources in Policies](https://kyverno.io/docs/writing-policies/external-data-sources)
- [Mutate resources](https://kyverno.io/docs/writing-policies/mutate/)
- [Generate resources](https://kyverno.io/docs/writing-policies/generate/)
- [Test policies](https://kyverno.io/docs/testing-policies/)

Happy policies, happy sailing, cheers!