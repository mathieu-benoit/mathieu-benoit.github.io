---
title: fixme
date: 2020-08-10
tags: [fixme]
description: fixme
draft: true
aliases:
    - /fixme/
---
What if you don't need Git anymore to deploy your Kubernetes manifests via GitOps!?


```
# Set current GCP project
project=FIXME
region=us-east4
zone=us-east4-a
gcloud config set project $project

# Create a GKE cluster
gcloud services enable container.googleapis.com
clusterName=FIXME
gcloud container clusters create $clusterName \
    --workload-pool=$project.svc.id.goog \
    --zone $zone

# Register the GKE cluster in an Anthos Fleet
gcloud services enable anthos.googleapis.com
gcloud container fleet memberships register $clusterName \
    --gke-cluster $zone/$clusterName \
    --enable-workload-identity

# Create an Artifact Registry repository
gcloud services enable artifactregistry.googleapis.com
containerRegistryName=oci-artifacts
gcloud artifacts repositories create $containerRegistryName \
    --location $region \
    --repository-format docker
```

```
gsaName=configsync-oci-sa
gsaId=$gsaName@$project.iam.gserviceaccount.com
gcloud iam service-accounts create $gsaName \
  --display-name=$gsaName
gcloud artifacts repositories add-iam-policy-binding $containerRegistryName \
    --location $region \
    --member "serviceAccount:$gsaId" \
    --role roles/artifactregistry.reader
```

```
# Enable Config Sync on that GKE cluster
gcloud beta container fleet config-management enable
cat <<EOF > acm-config.yaml
applySpecVersion: 1
spec:
  configSync:
    enabled: true
    sourceFormat: unstructured
    sourceType: oci
    oci:
      image: us-docker.pkg.dev/stolos-dev/config-sync-ci-public/kustomize-components:latest
      dir: tenant-a
      auth: gcpserviceaccount
      gcpServiceAccountEmail: ${gsaId}
EOF
gcloud beta container fleet config-management apply \
    --membership $clusterName \
    --config acm-config.yaml
```

```
cat <<EOF > acm-config.yaml
applySpecVersion: 1
spec:
  configSync:
    enabled: true
EOF
```

```
cat <<EOF> oci-rootsync.yaml
apiVersion: configsync.gke.io/v1beta1
kind: RootSync
metadata:
  name: oci-rootsync
  namespace: config-management-system
spec:
  sourceFormat: unstructured
  sourceType: oci
  oci:
    image: us-docker.pkg.dev/stolos-dev/config-sync-ci-public/kustomize-components:latest
    dir: tenant-a
    auth: none
EOF
```

```
cat <<EOF> test-namespace.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: test2
EOF
```

```
oras push \
    $region-docker.pkg.dev/$project/$containerRegistryName/my-artifact:v1 \
    test-namespace.yaml

oras push \
    us-east4-docker.pkg.dev/mabenoit-oci/oci-artifacts/my-artifact:v2 \
    test-namespace/

oras push \
    us-east4-docker.pkg.dev/mabenoit-oci/oci-artifacts/my-artifact:v3 \
    test-namespace.yaml:text/plain

oras push \
    us-east4-docker.pkg.dev/mabenoit-oci/oci-artifacts/my-artifact:v4 \
    test-namespace.yaml:application/tar

oras push \
    us-east4-docker.pkg.dev/mabenoit-oci/oci-artifacts/my-artifact:v5 \
    test-namespace.yaml:application/vnd.oci.image.layer.v1.tar+gzip
```

```
cat <<EOF> oci-rootsync.yaml
apiVersion: configsync.gke.io/v1beta1
kind: RootSync
metadata:
  name: oci-rootsync
  namespace: config-management-system
spec:
  sourceFormat: unstructured
  sourceType: oci
  oci:
    image: $region-docker.pkg.dev/$project/$containerRegistryName/my-artifact:v1
    dir: .
    auth: gcpserviceaccount
    gcpServiceAccountEmail: ${gsaId}
EOF
```

```
cat <<EOF> oci-rootsync.yaml
apiVersion: configsync.gke.io/v1beta1
kind: RootSync
metadata:
  name: oci-rootsync
  namespace: config-management-system
spec:
  sourceFormat: unstructured
  sourceType: oci
  oci:
    image: $region-docker.pkg.dev/$project/$containerRegistryName/my-artifact:v1
    dir: .
    auth: gcpserviceaccount
    gcpServiceAccountEmail: 401055041786-compute@developer.gserviceaccount.com
EOF
```

```
cat <<EOF> oci-rootsync.yaml
apiVersion: configsync.gke.io/v1beta1
kind: RootSync
metadata:
  name: oci-rootsync
  namespace: config-management-system
spec:
  sourceFormat: unstructured
  sourceType: oci
  oci:
    image: us-east4-docker.pkg.dev/mabenoit-oci/oci-artifacts/my-artifact:v6
    dir: .
    auth: none
EOF



FIXME - add scenario of changing ns test to test2 and see what happens.