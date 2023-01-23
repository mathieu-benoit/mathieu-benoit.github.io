---
title: cosign with gke and kms
date: 2023-01-23
tags: [gcp, kubernetes, security, containers]
description: let's see how we could sign our own private container images and then how to only allow them to be deployed in our gke cluster
aliases:
    - /cosign-with-gke/
---
With KubeCon, [GitOpsCon](https://www.youtube.com/playlist?list=PLj6h78yzYM2PVniTC7pKpHx1KsYjsOJnJ), [SigstoreCon](https://www.youtube.com/playlist?list=PLj6h78yzYM2MUNId2hvHBnrGCCbmou_gl) and [SecurityCon](https://www.youtube.com/playlist?list=PLj6h78yzYM2Mwt-aVXI6ItZX5s9izAp0F) NA 2022, Secure Software Supply Chain (S3C) demonstrated that it is not anymore just a trend or a buzz. It's getting more and more serious, we are seeing a lot of simplication about how to set up and leverage such technologies.

> Don't trust registries.

> Sign everything: git commit, npm/rust/java/python packages, container image, Helm chart, Kubernetes manifests, etc.

> Nearly every site runs HTTPS and is, by definition, more secure. This is the model that Sigstore wants to follow.

When I came back from KubeCon NA 2022, I added at the top of my TODO list to play and learn more about [Sigstore and cosign on Kubernetes clusters](https://docs.sigstore.dev/cosign/overview/#kubernetes-integrations). So here I am, like usual, sharing my step by step guide about how to accomplish this while sharing my thoughts and learnings. Hope you'll like it and will learn something!

This blog article consists on two main sections:
- [Sign a container image with Cloud KMS and Sigstore's `cosign`](#sign-a-container-image-with-cloud-kms-and-cosign)
- [Enforce that only signed container images are allowed in a GKE cluster with Sigstore's `policy-controller`](#enforce-that-only-signed-container-images-are-allowed-in-a-gke-cluster-with-sigstores-policy-controller)

Define the common bash variables used throughout this blog article:
```bash
PROJECT_ID=FIXME-WITH-YOUR-EXISTING-PROJECT-ID
gcloud config set project ${PROJECT_ID}
REGION=northamerica-northeast1
```

## Sign a container image with Cloud KMS and `cosign`

In this section you will:
- Create a key in KMS
- Create a Google Artifact Registry repository to store container images
- Push a simple `nginx` container image in this repository
- Install [Sigstore's `cosign`](https://docs.sigstore.dev/cosign/overview/) locally
- Sign this remote private container image

Enable the KMS API in our current project:
```bash
gcloud services enable cloudkms.googleapis.com
```

Create a key in KMS:
```bash
KEY_RING=cosign
gcloud kms keyrings create ${KEY_RING} \
    --location ${REGION}
KEY_NAME=cosign
gcloud kms keys create ${KEY_NAME} \
    --keyring ${KEY_RING} \
    --location ${REGION} \
    --purpose asymmetric-signing \
    --default-algorithm ec-sign-p256-sha256
```

Enable the Artifact Registry API in our current project:
```bash
gcloud services enable artifactregistry.googleapis.com
```

Create a private Google Artifact Registry repository to store our container images:
```bash
REGISTRY_NAME=containers
gcloud artifacts repositories create ${REGISTRY_NAME} \
    --repository-format docker \
    --location ${REGION}
```

Push an `nginx` image in our own private Google Artifact Registry repository:
```bash
docker pull nginx
docker tag nginx ${REGION}-docker.pkg.dev/${PROJECT_ID}/${REGISTRY_NAME}/nginx
gcloud auth configure-docker ${REGION}-docker.pkg.dev
SHA=$(docker push ${REGION}-docker.pkg.dev/${PROJECT_ID}/${REGISTRY_NAME}/nginx | grep digest: | cut -f3 -d" ")
```
_Note: we are grabbing the `SHA` of this remote container image in order to sign this container image later._

Install [`cosign`](https://docs.sigstore.dev/cosign/installation/) locally:
```bash
COSIGN_VERSION=$(curl -s https://api.github.com/repos/sigstore/cosign/releases/latest | jq -r .tag_name)
curl -LO https://github.com/sigstore/cosign/releases/download/${COSIGN_VERSION}/cosign-linux-amd64
sudo mv cosign-linux-amd64 /usr/local/bin/cosign
chmod +x /usr/local/bin/cosign
```

[Generage a key](https://docs.sigstore.dev/cosign/key-generation/#key-generation-and-management) and [sign](https://docs.sigstore.dev/cosign/sign/) this remote container image:
```bash
gcloud auth application-default login
cosign generate-key-pair \
    --kms gcpkms://projects/${PROJECT_ID}/locations/${REGION}/keyRings/${KEY_RING}/cryptoKeys/${KEY_NAME}
cosign sign \
    --key gcpkms://projects/${PROJECT_ID}/locations/${REGION}/keyRings/${KEY_RING}/cryptoKeys/${KEY_NAME} \
    ${REGION}-docker.pkg.dev/${PROJECT_ID}/${REGISTRY_NAME}/nginx@${SHA}
```

We could now see that our Google Artifact Registry repository has two entries, one for the actual container image and the other for the associate `.sig` signature:
```bash
gcloud artifacts docker tags list ${REGION}-docker.pkg.dev/${PROJECT_ID}/${REGISTRY_NAME}/nginx
```
Output similar to:
```plaintext
Listing items under project mabenoit-gatekeeper-oci, location us-east4, repository containers.
TAG                                                                          IMAGE                                                             DIGEST
latest                                                                       us-east4-docker.pkg.dev/mabenoit-gatekeeper-oci/containers/nginx  sha256:4c1c50d0ffc614f90b93b07d778028dc765548e823f676fb027f61d281ac380d
sha256-4c1c50d0ffc614f90b93b07d778028dc765548e823f676fb027f61d281ac380d.sig  us-east4-docker.pkg.dev/mabenoit-gatekeeper-oci/containers/nginx  sha256:f02d7fef0df5c264e34b995a4861590bbdd7001631f6e5f23250f34202359a56
```

## Enforce that only signed container images are allowed in a GKE cluster with Sigstore's `policy-controller`

In this section you will:
- Create a dedicated least privilege Google Service Account for the GKE's nodes
- Create a GKE cluster
- Install [Sigstore's `policy-controller`](https://docs.sigstore.dev/policy-controller/overview/) in this GKE cluster
- Deploy a policy to only allow signed container images
- Test this policy with both signed and unsigned container images

Define a least privilege Google Service Account (GSA) the GKE's nodes ([instead of using the default Compute Engine Service Account](https://cloud.google.com/kubernetes-engine/docs/how-to/hardening-your-cluster#use_least_privilege_sa)):
```bash
CLUSTER_NAME=cosign-test-cluster
GSA_NAME=${CLUSTER_NAME}-sa
GSA_ID=${GSA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com
gcloud iam service-accounts create ${GSA_NAME} \
    --display-name ${GSA_NAME}
roles="roles/logging.logWriter roles/monitoring.metricWriter roles/monitoring.viewer roles/cloudkms.viewer roles/cloudkms.verifier"
for role in $roles; do gcloud projects add-iam-policy-binding ${PROJECT_ID} --member "serviceAccount:${GSA_ID}" --role $role; done
gcloud artifacts repositories add-iam-policy-binding ${REGISTRY_NAME} \
    --location ${REGION} \
    --member "serviceAccount:${GSA_ID}" \
    --role roles/artifactregistry.reader
```
_Note: in addition to the roles for monitoring, we are also granting both `cloudkms.viewer` and `cloudkms.verifier` needed by Sigstore's `policy-controller`._

Enable the GKE API in our current project:
```bash
gcloud services enable container.googleapis.com
```

Create a GKE cluster with this dedicated GSA:
```bash
gcloud container clusters create ${CLUSTER_NAME} \
    --service-account ${GSA_ID} \
    --region ${REGION} \
    --scopes "gke-default,https://www.googleapis.com/auth/cloudkms"
```
_Note: we explicitly add the `https://www.googleapis.com/auth/cloudkms` scope needed by Sistore's `policy-controller`. [`https://www.googleapis.com/auth/cloud-platform`](https://cloud.google.com/kubernetes-engine/docs/how-to/access-scopes) instead is fine too._

Install the [Sigstore's `policy-controller` Helm chart](https://github.com/sigstore/helm-charts/tree/main/charts/policy-controller):
```bash
helm repo add sigstore https://sigstore.github.io/helm-charts
helm repo update
helm install policy-controller \
    -n cosign-system sigstore/policy-controller \
    --create-namespace
```

Deploy a policy only allowing signed container images from our private Google Artifact Registry repository:
```bash
cat << EOF | kubectl apply -f -
apiVersion: policy.sigstore.dev/v1alpha1
kind: ClusterImagePolicy
metadata:
  name: private-signed-images-cip
spec:
  images:
  - glob: ${REGION}-docker.pkg.dev/${PROJECT_ID}/${REGISTRY_NAME}/*
  authorities:
  - key:
        kms: gcpkms://projects/${PROJECT_ID}/locations/${REGION}/keyRings/${KEY_RING}/cryptoKeys/${KEY_NAME}/cryptoKeyVersions/1
EOF
```

Enfore this policy for the `default` namespace:
```bash
kubectl label namespace default policy.sigstore.dev/include=true
```
_Note: you need to apply this label on the namespaces you want this policy to be enforced in._

Test with an unsigned container image and see that it's blocked:
```bash
kubectl create deployment nginx --image=nginx
```
Output similar to:
```plaintext
error: failed to create deployment: admission webhook "policy.sigstore.dev" denied the request: validation failed: no matching policies: spec.template.spec.containers[0].image
index.docker.io/library/nginx@sha256:b8f2383a95879e1ae064940d9a200f67a6c79e710ed82ac42263397367e7cc4e
```

Test with our signed container image and see that it's allowed:
```bash
kubectl create deployment nginx --image=${REGION}-docker.pkg.dev/${PROJECT_ID}/${REGISTRY_NAME}/nginx@${SHA}
```
Output similar to:
```plaintext
deployment.apps/nginx created
```

That's it, congrats! We just enforced our GKE cluster to only allow our private and signed container images on specific namespaces! Wow!

## Resources

- [SigstoreCon NA 2022](https://www.youtube.com/playlist?list=PLj6h78yzYM2MUNId2hvHBnrGCCbmou_gl)
- [Sigstore's `policy-controller`](https://docs.sigstore.dev/policy-controller/overview/)
- [Sigstore Or: How We Learned to Stop Trusting Registries and Love Signatures - Wojciech Kocjan & Tyson Kamp, InfluxData](https://youtu.be/mduvP92bhPs?list=PLj6h78yzYM2MUNId2hvHBnrGCCbmou_gl)

Hope you enjoyed that one! Happy sailing, stay safe out there!