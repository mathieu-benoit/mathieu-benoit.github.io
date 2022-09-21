---
title: ci/gitops with helm, github actions, google artifact registry and config sync
date: 2022-09-20
tags: [gcp, helm, containers, kubernetes, gitops]
description: let's see how to do the ci/gitops workflow with helm charts, github actions (using workload identity federation), google artifact registry and config sync
aliases:
    - /ci-gitops-helm-github-actions-google-registry/
---
Since [Anthos Config Management 1.13.0](https://cloud.google.com/anthos-config-management/docs/release-notes#September_15_2022), Config Sync supports syncing Helm charts from private OCI registries. To learn more, see [Sync Helm charts from Artifact Registry](https://cloud.google.com/anthos-config-management/docs/how-to/sync-helm-charts-from-artifact-registry).

[In the previous article]({{< ref "/posts/2022/09/ci-gitops-helm-github-actions-github-registry.md" >}}), we saw how you can package and push an Helm chart to **GitHub Container Registry with GitHub actions (using PAT token)**, and then how you can deploy an Helm chart with Config Sync.

In this article, we will show how you can package and push an Helm chart to **Google Artifact Registry with GitHub actions (using Workload Identity Federation)**, and then how you can deploy an Helm chart with Config Sync.

![Workflow overview.](https://github.com/mathieu-benoit/my-images/raw/main/ci-gitops-helm-github-actions-google-registry.png)

## Objectives

*   Set up Workload Identity Federation with a dedicated Google Service Account
*   Create a Google Artifact Registry repository
*   Package and push an Helm chart in Google Artifact Registry with GitHub actions (using Workload Identity Federation)
*   Create a GKE cluster and enable Config Sync
*   Sync an Helm chart from Google Artifact Registry with Config Sync

## Costs

This tutorial uses billable components of Google Cloud, including the following:

*   [Kubernetes Engine](https://cloud.google.com/kubernetes-engine/pricing)
*   [Artifact Registry](https://cloud.google.com/artifact-registry/pricing)

_Note: In this case, Config Sync is free, see more details [here](https://cloud.google.com/anthos-config-management/docs/pricing)._

Use the [pricing calculator](https://cloud.google.com/products/calculator) to generate a cost estimate based on your projected usage.

## Before you begin

This guide assumes that you have owner IAM permissions for your Google Cloud project. In production, you do not require owner permission.

1.  [Select or create a Google Cloud project](https://console.cloud.google.com/projectselector2).

1.  [Verify that billing is enabled](https://cloud.google.com/billing/docs/how-to/modify-project) for your project.

This guide also assumes that you have a [GitHub account](https://github.com/) and a GitHub repository ready to use (you can [create a new dedicated GitHub repository](https://github.com/new) for this tutorial).

## Set up your environment

Here are the tools you will need:
- [`gcloud`](https://cloud.google.com/sdk/docs/install)
- [`git`](https://git-scm.com/downloads)
- [`gh`](https://cli.github.com/)
- [`nomos`](https://cloud.google.com/anthos-config-management/docs/downloads#nomos_command)
- [`kubectl`](https://kubernetes.io/docs/tasks/tools/#kubectl)

_Note: You can use the Google Cloud Shell which has all these tools already installed._

Initialize the common variables used throughout this tutorial:
```
PROJECT_ID=FIXME-WITH-YOUR-PROJECT-ID
REGION=us-east4
ZONE=us-east4-a
```

To avoid repeating the `--project` in the commands throughout this tutorial, let's set the current project:
```
gcloud config set project ${PROJECT_ID}
```

Use the [`gh`](https://cli.github.com/) tool to create this GitHub repository:
```
REPO_NAME=my-chart
cd ~/
gh auth login
git config --global init.defaultBranch main
gh repo create ${REPO_NAME} --private --clone
```

Let's capture the GitHub owner value that you will reuse later in this tutorial:
```
GITHUB_REPO_OWNER=$(gh repo view ${REPO_NAME} --json owner --jq .owner.login)
```

## Set up Workload Identity Federation

[Workload Identity Federation](https://cloud.google.com/iam/docs/workload-identity-federation) lets you access resources directly, using a short-lived access token, and eliminates the maintenance and security burden associated with service account keys.

Create a dedicated Google Service Account which will push the Helm chart in Artifact Registry later:
```
HELM_PACKAGER_GSA_NAME=helm-charts-packager
gcloud iam service-accounts create ${HELM_PACKAGER_GSA_NAME}
```

Create a Workload Identity Pool:
```
WI_POOL_NAME=helm-charts-packager-wi-pool
gcloud iam workload-identity-pools create ${WI_POOL_NAME} \
    --location global \
    --display-name ${WI_POOL_NAME}
WI_POOL_ID=$(gcloud iam workload-identity-pools describe ${WI_POOL_NAME} \
    --location global \
    --format='get(name)')
```

Create a Workload Identity Provider with GitHub actions in that pool:
```
gcloud iam workload-identity-pools providers create-oidc ${WI_POOL_NAME} \
    --location global \
    --workload-identity-pool ${WI_POOL_NAME} \
    --display-name ${WI_POOL_NAME} \
    --attribute-mapping "google.subject=assertion.repository,attribute.actor=assertion.actor,attribute.aud=assertion.aud,attribute.repository=assertion.repository" \
    --issuer-uri "https://token.actions.githubusercontent.com"
WI_POOL_PROVIDER_ID=$(gcloud iam workload-identity-pools providers describe ${WI_POOL_NAME} \
    --location global \
    --workload-identity-pool ${WI_POOL_NAME} \
    --format='get(name)')
```

Allow authentications from the Workload Identity Provider to impersonate the Service Account created above:
```
gcloud iam service-accounts add-iam-policy-binding ${HELM_PACKAGER_GSA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com \
    --role "roles/iam.workloadIdentityUser" \
    --member "principalSet://iam.googleapis.com/${WI_POOL_ID}/attribute.repository/${GITHUB_REPO_OWNER}/${REPO_NAME}"
```

## Set up the Artifact Registry repository

Create a Google Artifact Registry repository:
```
gcloud services enable artifactregistry.googleapis.com
ARTIFACT_REGISTRY_REPOSITORY=helm-charts
gcloud artifacts repositories create ${ARTIFACT_REGISTRY_REPOSITORY} \
    --location ${REGION} \
    --repository-format docker
```

Allow the Google Service Account to push in Artifact Registry:
```
gcloud artifacts repositories add-iam-policy-binding ${ARTIFACT_REGISTRY_REPOSITORY} \
    --location ${REGION} \
    --member "serviceAccount:${HELM_PACKAGER_GSA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com" \
    --role roles/artifactregistry.writer
```

## Package and push an Helm chart in Google Artifact Registry

Create the Helm chart:
```
helm create ~/${REPO_NAME}
```

Commit this Helm chart template in the GitHub repository:
```
cd ~/${REPO_NAME}
git add . && git commit -m "Create Helm chart template" && git push origin main
```

Set the environment variables as secrets for the GitHub actions pipeline:
```
gh secret set PROJECT_ID -b"${PROJECT_ID}"
gh secret set ARTIFACT_REGISTRY_REPOSITORY -b"${ARTIFACT_REGISTRY_REPOSITORY}"
gh secret set ARTIFACT_REGISTRY_HOST_NAME -b"${REGION}-docker.pkg.dev"
gh secret set HELM_CHARTS_PACKAGER_GSA_ID -b"${HELM_PACKAGER_GSA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"
gh secret set WI_POOL_PROVIDER_ID -b"${WI_POOL_PROVIDER_ID}"
```

Define a GitHub actions pipeline to package and push the Helm chart in Google Artifact Registry:
```
mkdir .github && mkdir .github/workflows
cat <<'EOF' > .github/workflows/ci-helm-gar.yaml
name: ci-helm-gar
permissions:
  contents: read
  id-token: write
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
      - uses: google-github-actions/auth@v0
        with:
          workload_identity_provider: '${{ secrets.WI_POOL_PROVIDER_ID }}'
          service_account: '${{ secrets.HELM_CHARTS_PACKAGER_GSA_ID }}'
          token_format: 'access_token'
      - uses: google-github-actions/setup-gcloud@v0
        with:
          version: latest
      - name: login to artifact registry
        run: |
          gcloud auth configure-docker ${{ secrets.ARTIFACT_REGISTRY_HOST_NAME }} --quiet
      - name: helm package
        run: |
          helm package . --version $IMAGE_TAG
      - name: helm push
        if: ${{ github.event_name == 'push' }}
        run: |
          helm push $CHART_NAME-$IMAGE_TAG.tgz oci://${{ secrets.ARTIFACT_REGISTRY_HOST_NAME }}/${{ secrets.PROJECT_ID }}/${{ secrets.ARTIFACT_REGISTRY_REPOSITORY }}
EOF
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

See that your Helm chart has been uploaded in the Google Artifact Registry repository:
```
gcloud artifacts docker images list ${REGION}-docker.pkg.dev/${PROJECT_ID}/$ARTIFACT_REGISTRY_REPOSITORY/${REPO_NAME}
```

Now that we have built and store our Helm chart, let's provision the GKE cluster with Config Sync ready to eventually deploy this Helm chart.

## Create your GKE cluster and enable Config Sync

Create a GKE cluster registered in a [Fleet](https://cloud.google.com/anthos/fleet-management/docs/fleet-concepts) to enable Config Management:
```
gcloud services enable container.googleapis.com
CLUSTER_NAME=cluster-helm-test
gcloud container clusters create ${CLUSTER_NAME} \
    --workload-pool=${PROJECT_ID}.svc.id.goog \
    --zone ${ZONE}

gcloud services enable gkehub.googleapis.com
gcloud container fleet memberships register ${CLUSTER_NAME} \
    --gke-cluster ${ZONE}/${CLUSTER_NAME} \
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
    --membership ${CLUSTER_NAME} \
    --config acm-config.yaml
```

## Sync an Helm chart from Google Artifact Registry

Create a dedicated Google Cloud Service Account with the fine granular access to that Artifact Registry repository with the `roles/artifactregistry.reader` role:
```
HELM_CHARTS_READER_GSA_NAME=helm-charts-reader
gcloud iam service-accounts create ${HELM_CHARTS_READER_GSA_NAME} \
    --display-name ${HELM_CHARTS_READER_GSA_NAME}
gcloud artifacts repositories add-iam-policy-binding ${ARTIFACT_REGISTRY_REPOSITORY} \
    --location ${REGION} \
    --member "serviceAccount:${HELM_CHARTS_READER_GSA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com" \
    --role roles/artifactregistry.reader
```

Allow Config Sync to synchronize resources for a specific `RootSync` via Workload Identity:
```
ROOT_SYNC_NAME=root-sync-helm
gcloud iam service-accounts add-iam-policy-binding \
    --role roles/iam.workloadIdentityUser \
    --member "serviceAccount:${PROJECT_ID}.svc.id.goog[config-management-system/root-reconciler-${ROOT_SYNC_NAME}]" \
    ${HELM_CHARTS_READER_GSA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com
```

Deploy the `RootSync` in order to sync the private Helm chart:
```
cat << EOF | kubectl apply -f -
apiVersion: configsync.gke.io/v1beta1
kind: RootSync
metadata:
  name: ${ROOT_SYNC_NAME}
  namespace: config-management-system
spec:
  sourceFormat: unstructured
  sourceType: helm
  helm:
    repo: oci://${REGION}-docker.pkg.dev/${PROJECT_ID}/${ARTIFACT_REGISTRY_REPOSITORY}
    chart: my-chart
    version: 0.1.0
    releaseName: my-chart
    namespace: default
    auth: gcpserviceaccount
    gcpServiceAccountEmail: ${HELM_CHARTS_READER_GSA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com
EOF
```
_Note that we added the `spec.helm.auth: gcpserviceaccount` and `spec.helm.gcpServiceAccountEmail: ${HELM_CHARTS_READER_GSA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com` values to be able to access and sync the private Helm chart._

Check the status of the sync:
```
nomos status \
    --contexts=$(kubectl config current-context)
```

Verify that the Helm chart is synced:
```
kubectl get all \
    -n default
```

And voilà! You just deployed a **private Helm chart** hosted in Google Artifact Registry with Config Sync.

## Conclusion

In this article, you were able to package and push an Helm chart in Google Artifact Registry with GitHub Actions using Workload Identity Federation. At the end, you saw how you can sync a private Helm chart with the `spec.helm.auth: gcpserviceaccount` setup on the `RootSync`. This demonstrates that Config Sync supports a key-less approach to connect to Google Artifact Registry.

## Cleaning up

To avoid incurring charges to your Google Cloud account, you can delete the resources used in this tutorial.

Unregister the GKE cluster from the [Fleet](https://cloud.google.com/anthos/fleet-management/docs/fleet-concepts):
```
gcloud container fleet memberships unregister ${CLUSTER_NAME} \
    --project=${PROJECT_ID} \
    --gke-cluster=${ZONE}/${CLUSTER_NAME}
```

Delete the GKE cluster:
```
gcloud container clusters delete ${CLUSTER_NAME} \
    --zone ${ZONE}
```

Delete the Artifact Registry repository:
```
gcloud artifacts repositories delete ${ARTIFACT_REGISTRY_REPOSITORY} \
    --location ${REGION}
```

## What's next

- [Deploy OCI artifacts and Helm charts the GitOps way with Config Sync](https://cloud.google.com/blog/products/containers-kubernetes/gitops-with-oci-artifacts-and-config-sync)
- [Sync Helm charts from Artifact Registry](https://cloud.google.com/anthos-config-management/docs/how-to/sync-helm-charts-from-artifact-registry)
- [Sync OCI artifacts from Artifact Registry](https://cloud.google.com/anthos-config-management/docs/how-to/sync-oci-artifacts-from-artifact-registry)
- [CI/GitOps with Helm, GitHub Actions, GitHub Container Registry and Config Sync]({{< ref "/posts/2022/09/ci-gitops-helm-github-actions-github-registry.md" >}})