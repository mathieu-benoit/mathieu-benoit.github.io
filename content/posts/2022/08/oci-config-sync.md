---
title: gitops with oci artifacts and config sync
date: 2022-08-17
tags: [gcp, helm, containers, kubernetes, gitops]
description: let's see how to do gitops with oci artifacts, artifact registry and config sync
aliases:
    - /oci-config-sync/
    - /oci-gitops/
---
One principle of [GitOps](https://opengitops.dev/) is to have the desired state declarations as **Versioned and Immutable**. Git repositories are playing a great role with that. But what if you don't need a Git repository anymore to deploy your Kubernetes manifests via GitOps!? What if you can deploy any OCI artifacts stored in any OCI registries via GitOps?

> The [Open Container Initiative (OCI)](https://opencontainers.org/) is an open governance structure for the express purpose of creating open industry standards around container formats and runtimes.

Let's see in action how [Config Sync can deploy OCI artifacts stored in Artifact Registry](https://cloud.google.com/anthos-config-management/docs/how-to/publish-config-registry).

Create a GKE cluster registered in a Fleet to enable Config Management:
```
project=FIXME
region=us-east4
zone=us-east4-a
gcloud config set project $project

gcloud services enable container.googleapis.com
clusterName=FIXME
gcloud container clusters create $clusterName \
    --workload-pool=$project.svc.id.goog \
    --zone $zone

gcloud services enable anthos.googleapis.com
gcloud container fleet memberships register $clusterName \
    --gke-cluster $zone/$clusterName \
    --enable-workload-identity

gcloud beta container fleet config-management enable
```

Create an Artifact Registry repository:
```
gcloud services enable artifactregistry.googleapis.com
containerRegistryName=oci-artifacts
gcloud artifacts repositories create $containerRegistryName \
    --location $region \
    --repository-format docker
```

Create a dedicated Google Cloud Service Account with the fine granular access to that Artifact Registry repository:
```
gsaName=configsync-oci-sa
gsaId=$gsaName@$project.iam.gserviceaccount.com
gcloud iam service-accounts create $gsaName \
  --display-name=$gsaName
gcloud artifacts repositories add-iam-policy-binding $containerRegistryName \
    --location $region \
    --member "serviceAccount:$gsaId" \
    --role roles/artifactregistry.reader
gcloud iam service-accounts add-iam-policy-binding \
   --role roles/iam.workloadIdentityUser \
   --member "serviceAccount:$project.svc.id.goog[config-management-system/root-reconciler]" \
   $gsaId
```

Login to Artifact Registry (later we will push OCI artifacts in there):
```
gcloud auth configure-docker $region-docker.pkg.dev
```

## Deploy a simple Kubernetes resource as OCI image

Create a simple Kubernetes `namespace` resource definition:
```
cat <<EOF> test-namespace.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: test
EOF
```

Create an archive of that file:
```
tar -cf test-namespace.tar test-namespace.yaml
```

Push that artifact in Artifact Registry with [`oras`](https://oras.land/):
```
oras push \
    $region-docker.pkg.dev/$project/$containerRegistryName/my-artifact:v1 \
    test-namespace.tar
```
Alternatively, push that artifact in Artifact Registry with [`crane`](https://github.com/google/go-containerregistry/tree/main/cmd/crane):
```
crane append -f <(tar -f - -c test-namespace.tar) \
    -t $region-docker.pkg.dev/$project/$containerRegistryName/my-artifact:v1 
```

Set up Config Sync to deploy this artifact from Artifact Registry:
```
cat <<EOF > acm-config.yaml
applySpecVersion: 1
spec:
  configSync:
    enabled: true
    sourceFormat: unstructured
    sourceType: oci
    syncRepo: ${region}-docker.pkg.dev/${project}/${containerRegistryName}/my-artifact:v1
    secretType: gcpserviceaccount
    policyDir: .
    gcpServiceAccountEmail: ${gsaId}
EOF
gcloud beta container fleet config-management apply \
    --membership $clusterName \
    --config acm-config.yaml
```

Check the status of the deployment:
```
nomos status --contexts=$(kubectl config current-context)
gcloud alpha anthos config sync repo describe --managed-resources all
kubectl get ns
```

And voila! That's how easy it is to deploy an OCI artifact in a GitOps way with Config Sync.

There are 3 main advantages of doing GitOps with OCI artifacts instead of Git repository:
- You could have fine granular access control on the registry with your Google Cloud IAM (users, service accounts, etc.)
- You could share more easily packages/artifacts of your Kubernetes manifests, even in a dynamic and generic way with Helm as an example
- You could have a better seperation of concerns between your CI and your CD. With your CI pipelines you still need Git repositories, have security and governance checks before pushing the artifacts in the registries.

Complementary and further resources:
- [Host Helm charts and OCI artifacts in Artifact Registry]({{< ref "/posts/2021/01/oci-artifact-registry.md" >}})
- [Add GitOps without throwing out your CI tools](https://www.cncf.io/blog/2022/08/10/add-gitops-without-throwing-out-your-ci-tools/)
- [OCI artifacts support from FluxCD](https://fluxcd.io/docs/cheatsheets/oci-artifacts/)

Hope you enjoyed that one, cheers!