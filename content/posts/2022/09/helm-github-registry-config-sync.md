---
title: ci/gitops with helm, github actions, github container registry and config sync
date: 2022-09-16
tags: [gcp, helm, containers, kubernetes, gitops]
description: let's see how to do the ci/gitops workflow with helm charts, github actions, github container registry and config sync
aliases:
    - /helm-github-registry-config-sync/
---
Since [Anthos Config Management 1.13.0](https://cloud.google.com/anthos-config-management/docs/release-notes#September_15_2022), Config Sync supports syncing Helm charts from private OCI registries. To learn more, see [Sync Helm charts from Artifact Registry](https://cloud.google.com/anthos-config-management/docs/how-to/sync-helm-charts-from-artifact-registry).

In this article, we will show how you can package and push an Helm chart to GitHub Container Registry with GitHub actions, and then how you can deploy both a public and a private Helm chart with Config Sync.

![Workflow overview.](https://github.com/mathieu-benoit/my-images/raw/main/helm-github-registry-config-sync.png)

## Objectives

*   Package and push your Helm chart in GitHub Container Registry with GitHub actions
*   Create your GKE cluster and enable Config Sync
*   Sync a public Helm chart from GitHub Container Registry with Config Sync
*   Sync a private Helm chart from GitHub Container Registry with Config Sync

## Costs

This tutorial uses billable components of Google Cloud, including the following:

*   [Kubernetes Engine](https://cloud.google.com/kubernetes-engine/pricing)

_Note: In this case, Config Sync is free, see more details [here](https://cloud.google.com/anthos-config-management/docs/pricing)._

Use the [pricing calculator](https://cloud.google.com/products/calculator) to generate a cost estimate based on your projected usage.

## Before you begin

This guide assumes that you have owner IAM permissions for your Google Cloud project. In production, you do not require owner permission.

1.  [Select or create a Google Cloud project](https://console.cloud.google.com/projectselector2).

1.  [Verify that billing is enabled](https://cloud.google.com/billing/docs/how-to/modify-project) for your project.

This guide also assumes that you have a [GitHub account](https://github.com/).

## Set up your environment

Initialize the common variables used throughout this tutorial:
```
PROJECT_ID=FIXME-WITH-YOUR-PROJECT-ID
ZONE=us-east4-a
```

To avoid repeating the `--project` in the commands throughout this tutorial, let's set the current project:
```
gcloud config set project ${PROJECT_ID}
```

Use the [`gh`](https://cli.github.com/) tool to create this GitHub repository:
```
REPO_NAME=helm-chart-packager-repo
gh auth login
gh repo create ${REPO_NAME} --clone
```
_Note: we are creating a public GitHub repository, for the purpose of this demo. In most cases you will have a private repository, simply use the `--private` parameter with the command above._

Let's capture the GitHub owner value that you will reuse later in this tutorial:
```
GITHUB_REPO_OWNER=$(gh repo view --json owner --jq .owner)
```

## Package and push an Helm chart in GitHub Container Registry

Create the Helm chart:
```
helm create $REPO_NAME
```

Commit this Helm chart template in the GitHub repository:
```
git add . && git commit -m "Create Helm chart template" && git push origin main
```

Define a GitHub actions pipepline to package and push the Helm chart in GitHub Container Registry:
```
mkdir .github/workflows
echo '
name: ci
permissions:
  packages: write
  contents: read
on:
  push:
    branches:
      - main
  pull_request:
env:
  CHART_NAME: my-chart
  IMAGE_TAG: 0.1.0
jobs:
  job:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: helm lint
        run: |
          helm lint .
      - name: helm login
        run: |
          echo ${{ secrets.GITHUB_TOKEN }} | helm registry login ghcr.io -u $ --password-stdin
      - name: helm package
        run: |
          helm package . --version $IMAGE_TAG
      - name: helm push
        if: ${{ github.event_name == 'push' }}
        run: |
          helm push $CHART_NAME-$IMAGE_TAG.tgz oci://ghcr.io/${{ github.repository_owner }}
' > .github/workflows/ci-helm.yaml
```
This GitHub Actions pipeline allows to execute a series of commands: `helm lint`, `helm registry login`, `helm package` and eventually, if it's a `push` in `main` branch, `helm push` will be executed. Also, this pipeline is triggered as soon as there is a `push` in `main` branch as well as for any pull requests. You can adapt this flow and these conditions for your own needs.

You can see that we use the [automatic token authentication](https://docs.github.com/en/actions/security-guides/automatic-token-authentication) by using the `secrets.GITHUB_TOKEN` environment variable with the `helm registry login` command. In addition to that, in order to be able to push the Helm chart in GitHub Container Registry we need to have the `permissions.packages: write`.

Commit this GitHub actions pipeline in the GitHub repository:
```
git add . && git commit -m "Create GitHub actions pipeline" && git push origin main
```

Wait until the associated run is successfully completed:
```
gh run list
```

See that your Helm chart has been uploaded in the packages of your GitHub repository:
```
echo -e "https://github.com/${GITHUB_REPO_OWNER}?tab=packages&repo_name=${REPO_NAME}"
```
_Note: you can see that this artifact is public, that's because we created a public GitHub repository earlier for the purpose of this tutorial._

Now that we have built and store our Helm chart, let's provision the GKE cluster with Config Sync ready to eventually deploy this Helm chart.

## Create your GKE cluster and enable Config Sync

Create a GKE cluster registered in a [Fleet](https://cloud.google.com/anthos/fleet-management/docs/fleet-concepts) to enable Config Management:
```
gcloud services enable container.googleapis.com
CLUSTER_NAME=cluster-helm-test
gcloud container clusters create $CLUSTER_NAME \
    --workload-pool=$PROJECT.svc.id.goog \
    --zone $ZONE

gcloud services enable gkehub.googleapis.com
gcloud container fleet memberships register $CLUSTER_NAME \
    --gke-cluster $ZONE/$CLUSTER_NAME \
    --enable-workload-identity

gcloud beta container fleet config-management enable
```

Install Config Sync in this GKE cluster:
```
cat <<EOF > acm-config.yaml
applySpecVersion: 1
spec:
  configSync:
    enabled: true
EOF
gcloud beta container fleet config-management apply \
    --membership $CLUSTER_NAME \
    --config acm-config.yaml
```

Now that we have our setup ready, let's sync the Helm chart previously packaged and pushed to GitHub Container Registry.

## Sync a public Helm chart from GitHub Container Registry

Deploy the `RootSync` in order to sync the public Helm chart:
```
ROOT_SYNC_NAME=root-sync-helm
ROOT_SYNC_NAMESPACE=config-management-system
cat << EOF | kubectl apply -f -
apiVersion: configsync.gke.io/v1beta1
kind: RootSync
metadata:
  name: ${ROOT_SYNC_NAME}
  namespace: ${ROOT_SYNC_NAMESPACE}
spec:
  sourceFormat: unstructured
  sourceType: helm
  helm:
    repo: oci://ghcr.io/${GITHUB_REPO_OWNER}
    chart: my-chart
    version: 0.1.0
    releaseName: my-chart
    namespace: default
    auth: none
EOF
```

Check the status of the sync with the [nomos](https://cloud.google.com/anthos-config-management/docs/downloads#nomos_command) tool:
```
nomos status \
    --contexts=$(kubectl config current-context)
```

Verify that the Helm chart is synced:
```
kubectl get all \
    -n default
```

And voilà! You just deployed a **public Helm chart** hosted in GitHub Registry with Config Sync.

## Sync a private Helm chart from GitHub Container Registry

Because we created a public GitHub repository, the Helm chart we pushed in GitHub Container Registry is public. You can change this default visibility from public to private by following the instructions [here](https://docs.github.com/en/packages/learn-github-packages/configuring-a-packages-access-control-and-visibility#configuring-visibility-of-container-images-for-your-personal-account).

[Create a new Personal Access Token (PAT) in GitHub](https://github.com/settings/tokens/new) with the `read:packages` OAuth scope to follow the "just enough and least-privilege" principles.

Create the associated `Secret` with the GitHub's PAT in the `RootSync`'s `Namespace`:
```
GITHUB_PAT=FIXME
kubectl create secret generic ghcr \
    --namespace=${ROOT_SYNC_NAMESPACE} \
    --from-literal=username=config-sync \
    --from-literal=password=${GITHUB_PAT}
```

Deploy the `RootSync` in order to sync the private Helm chart:
```
cat << EOF | kubectl apply -f -
apiVersion: configsync.gke.io/v1beta1
kind: RootSync
metadata:
  name: ${ROOT_SYNC_NAME}
  namespace: ${ROOT_SYNC_NAMESPACE}
spec:
  sourceFormat: unstructured
  sourceType: helm
  helm:
    repo: oci://ghcr.io/${GITHUB_REPO_OWNER}
    chart: my-chart
    version: 0.1.0
    releaseName: my-chart
    namespace: default
    auth: token
    secretRef:
      name: ghcr
EOF
```
_Note that we added the `spec.helm.auth: token` and `spec.helm.secretRef.name: ghcr` values to be able to access and sync the private Helm chart._

Check the status of the sync with the [nomos](https://cloud.google.com/anthos-config-management/docs/downloads#nomos_command) tool:
```
nomos status \
    --contexts=$(kubectl config current-context)
```

Verify that the Helm chart is synced:
```
kubectl get all \
    -n default
```

And voilà! You just deployed a **private Helm chart** hosted in GitHub Registry with Config Sync.

## Conclusion

In this article, you were able to package and push an Helm chart in GitHub Container Registry with GitHub Actions. At the end, you have seen how you can sync a private Helm chart with the `spec.helm.auth: token` setup on the `RootSync`. This demonstrates that Config Sync supports any private OCI registries where you have your Helm chart: JFrog Artifactory, etc.

## Cleaning up

To avoid incurring charges to your Google Cloud account, you can delete the resources used in this tutorial.

Unregister the GKE cluster from the [Fleet](https://cloud.google.com/anthos/fleet-management/docs/fleet-concepts):
```
gcloud container fleet memberships unregister ${CLUSTER} \
    --project=${PROJECT_ID} \
    --gke-cluster=${ZONE}/${CLUSTER}
```

Delete the GKE cluster:
```
gcloud container clusters delete ${CLUSTER} \
    --zone ${ZONE}
```

## What's next

- [Sync Helm charts from Artifact Registry](https://cloud.google.com/anthos-config-management/docs/how-to/sync-helm-charts-from-artifact-registry)
- [Sync OCI artifacts from Artifact Registry](https://cloud.google.com/anthos-config-management/docs/how-to/sync-oci-artifacts-from-artifact-registry)