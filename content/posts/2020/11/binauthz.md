---
title: fixme
date: 2020-11-02
tags: [gcp, containers, kubernetes, security]
description: fixme
draft: true
aliases:
    - /binauthz/
---
[![](https://github.com/GoogleCloudPlatform/gke-binary-auth-demo/raw/master/images/sdlc.png)](https://github.com/GoogleCloudPlatform/gke-binary-auth-demo/raw/master/images/sdlc.png)

> [Binary Authorization](https://cloud.google.com/binary-authorization) is a deploy-time security control that ensures only trusted container images are deployed on Google Kubernetes Engine (GKE). With Binary Authorization, you can require images to be signed by trusted authorities during the development process and then enforce signature validation when deploying. By enforcing validation, you can gain tighter control over your container environment by ensuring only verified images are integrated into the build-and-release process.

The Binary Authorization and Container Analysis APIs are based upon the open source projects:
- [Grafeas](https://grafeas.io/) defines an API spec for managing metadata about software resources, such as container images, Virtual Machine (VM) images, JAR files, and scripts. You can use Grafeas to define and aggregate information about your project’s components.
- [Kritis](https://github.com/grafeas/kritis) defines an API for ensuring a deployment is prevented unless the artifact (container image) is conformant to central policy and optionally has the necessary attestations present.

TODO:
- Setup your cluster
- Apply cluster policies
- See audit logs





## Setup your GKE cluster

```
projectId=FIXME
gcloud config set project $projectId

gcloud services enable container.googleapis.com
gcloud services enable binaryauthorization.googleapis.com

gcloud container clusters create \
    --enable-binauthz

# You could also enable this feature on an existing cluster
gcloud container clusters update $clusterName \
    --enable-binauthz \
    --zone us-east4-a

# Deploy the hello-world container from DockerHub
kubectl create deployment hello-world \
    --image=hello-world
kubectl get pods
kubectl delete deployment hello-world

# Deploy the hello-world container from your private GCR
docker pull hello-world
docker tag hello-world gcr.io/$projectId/hello-world
gcloud auth configure-docker --quiet
docker push gcr.io/$projectId/hello-world
kubectl create deployment hello-world \
    --image=gcr.io/$projectId/hello-world
kubectl get pods
kubectl delete deployment hello-world
```

## Apply cluster policies

Securing the cluster with a policy, as a policy creator:
```
# Get the default policy in place
gcloud container binauthz policy export > policy.yaml
cat /tmp/policy.yaml

# Find all the default additional global policies in place
gcloud container binauthz policy export --project=binauthz-global-policy

# Change the default evaluationMode by ALWAYS-DENY
sed -i "s/evaluationMode: ALWAYS_ALLOW/evaluationMode: ALWAYS_DENY/g" policy.yaml
gcloud container binauthz policy import policy.yaml

# Check that any new deployment will fail with "Denied by default admission rule" error message in events
kubectl create deployment hello-world \
    --image=hello-world
kubectl get event
kubectl create deployment hello-world \
    --image=gcr.io/$projectId/hello-world
kubectl get event

# Change the admissionWhitelistPatterns list by removing the redundant global policies and adding our own GCR
cat > policy.yaml << EOF
admissionWhitelistPatterns:
- namePattern: gcr.io/$projectId/*
defaultAdmissionRule:
  enforcementMode: ENFORCED_BLOCK_AND_AUDIT_LOG
  evaluationMode: ALWAYS_DENY
globalPolicyEvaluationMode: ENABLE
name: projects/$projectId/policy
EOF
gcloud container binauthz policy import policy.yaml

# Check that the DockerHub deployment will fail with "Denied by default admission rule" error message in events but in the other end, the gcr.io/$projectId/hello-world will work now
kubectl create deployment hello-world \
    --image=hello-world
kubectl get event
kubectl create deployment hello-world \
    --image=gcr.io/$projectId/hello-world
kubectl get pod
```

That's how easy it is to whitelist and blacklist container registries on your GKE clusters. You could find [more policies examples here](https://cloud.google.com/binary-authorization/docs/example-policies). An interesting feature to be aware of is the [dry run mode](https://cloud.google.com/binary-authorization/docs/enabling-dry-run) which checks policy compliance at Pod creation time but without actually blocking the Pod from being created. Less radical and more gradual way to integrate Binary authorization on your existing GKE clusters.

## Setup attestor and attestation

https://cloud.google.com/binary-authorization/docs/creating-attestors-cli

https://cloud.google.com/binary-authorization/docs/making-attestations

## Update your Cloud Build definition

https://cloud.google.com/binary-authorization/docs/cloud-build

Further and complementary resources:
- [Binary Authorization pricing](https://cloud.google.com/binary-authorization/pricing)
- [Securing with VPC Service Controls](https://cloud.google.com/binary-authorization/docs/securing-with-vpcsc)