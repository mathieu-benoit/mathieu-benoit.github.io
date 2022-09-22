---
title: deploying gatekeeper policies as oci artifacts, the gitops way
date: 2022-09-22
tags: [gcp, containers, kubernetes, gitops]
description: let's see how to deploy gatekeeper policies as oci artifacts, thanks to oras, google artifact registry and config sync
aliases:
    - /gatekeeper-policies-as-oci-artifacts/
---
Since [Anthos Config Management 1.13.0](https://cloud.google.com/anthos-config-management/docs/release-notes#September_15_2022), you can now [deploy OCI artifacts and Helm charts the GitOps way with Config Sync](https://cloud.google.com/blog/products/containers-kubernetes/gitops-with-oci-artifacts-and-config-sync).

In this blog, let's see in action how to deploy [Open Policy Agent (OPA) Gatekeeper](https://open-policy-agent.github.io/gatekeeper/website/docs/) policies as OCI artifacts, thanks to [`oras`](https://oras.land/), Google Artifact Registry and Config Sync.

Here is what you will accomplish throughout this blog:
- Set up an Artifact Registry repository
- Package and push a Gatekeeper policy as OCI artifact to Artifact Registry
- Set up a GKE cluster with Config Sync and Policy Controller
- Deploy a Gatekeeper policy as OCI artifact with Config Sync

_To illustrate this during this blog, we will leverage [Policy Controller](https://cloud.google.com/anthos-config-management/docs/concepts/policy-controller), but the same approach could be done if you [install Gatekeeper by yourself](https://open-policy-agent.github.io/gatekeeper/website/docs/install). Policy Controller is based on the open source OPA Gatekeeper._

![Workflow overview.](https://github.com/mathieu-benoit/my-images/raw/main/gatekeeper-policies-as-oci-artifacts.png)

## Set up the environment

Here are the tools you will need:
- [`gcloud`](https://cloud.google.com/sdk/docs/install)
- [`oras`](https://oras.land/cli/)
- [`nomos`](https://cloud.google.com/anthos-config-management/docs/downloads#nomos_command)
- [`kubectl`](https://kubernetes.io/docs/tasks/tools/#kubectl)

Initialize the common variables used throughout this blog:
```
PROJECT_ID=FIXME-WITH-YOUR-PROJECT-ID
REGION=us-east4
ZONE=us-east4-a
```

To avoid repeating the `--project` in the commands throughout this tutorial, let's set the current project:
```
gcloud config set project ${PROJECT_ID}
```

## Set up an Artifact Registry repository

Create an Artifact Registry repository:
```
gcloud services enable artifactregistry.googleapis.com
ARTIFACT_REGISTRY_REPO_NAME=oci-artifacts
gcloud artifacts repositories create ${ARTIFACT_REGISTRY_REPO_NAME} \
    --location ${REGION} \
    --repository-format docker
```

## Package and push a Gatekeeper policy as OCI artifact to Artifact Registry

We will create a simple Gatekeeper policy composed by one `Constraint` and one `ConstraintTemplate`. You can easily replicate this scenario with your own list of policies.

Define a `ConstraintTemplate` which could ensure that container images begin with a string from the specified list:
```
cat <<EOF> my-constrainttemplate.yaml
apiVersion: templates.gatekeeper.sh/v1
kind: ConstraintTemplate
metadata:
  annotations:
    description: Requires container images to begin with a string from the specified list.
  name: k8sallowedrepos
spec:
  crd:
    spec:
      names:
        kind: K8sAllowedRepos
      validation:
        openAPIV3Schema:
          type: object
          properties:
            repos:
              description: The list of prefixes a container image is allowed to have.
              type: array
              items:
                type: string
  targets:
  - target: admission.k8s.gatekeeper.sh
    rego: |
      package k8sallowedrepos
      violation[{"msg": msg}] {
        container := input.review.object.spec.containers[_]
        satisfied := [good | repo = input.parameters.repos[_] ; good = startswith(container.image, repo)]
        not any(satisfied)
        msg := sprintf("container <%v> has an invalid image repo <%v>, allowed repos are %v", [container.name, container.image, input.parameters.repos])
      }
      violation[{"msg": msg}] {
        container := input.review.object.spec.initContainers[_]
        satisfied := [good | repo = input.parameters.repos[_] ; good = startswith(container.image, repo)]
        not any(satisfied)
        msg := sprintf("initContainer <%v> has an invalid image repo <%v>, allowed repos are %v", [container.name, container.image, input.parameters.repos])
      }
      violation[{"msg": msg}] {
        container := input.review.object.spec.ephemeralContainers[_]
        satisfied := [good | repo = input.parameters.repos[_] ; good = startswith(container.image, repo)]
        not any(satisfied)
        msg := sprintf("ephemeralContainer <%v> has an invalid image repo <%v>, allowed repos are %v", [container.name, container.image, input.parameters.repos])
      }
EOF
```

Define an associated `Constraint` for the `Namespaces` which should have a `owner` label:
```
cat <<EOF> my-constraint.yaml
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: K8sAllowedRepos
metadata:
  name: pod-allowed-container-registries
spec:
  enforcementAction: deny
  match:
    kinds:
    - apiGroups:
      - ""
      kinds:
      - Pod
  parameters:
    repos:
    - gcr.io/config-management-release
    - gcr.io/gke-release
    - gke.gcr.io
    - k8s.gcr.io
EOF
```

Do an archive of these files:
```
tar -cf my-policies.tar my-constraint.yaml my-constrainttemplate.yaml
```

Login to Artifact Registry:
```
gcloud auth configure-docker ${REGION}-docker.pkg.dev
```

Push that artifact in Artifact Registry with [`oras`](https://oras.land/):
```
oras push \
    ${REGION}-docker.pkg.dev/$project/${ARTIFACT_REGISTRY_REPO_NAME}/my-policies:1.0.0 \
    my-policies.tar
```

See that your OCI artifact has been uploaded in the Google Artifact Registry repository:
```
gcloud artifacts docker images list ${REGION}-docker.pkg.dev/${PROJECT_ID}/${ARTIFACT_REGISTRY_REPO_NAME}/${REPO_NAME}
```

## Set up a GKE cluster with Config Sync and Policy Controller

Create a GKE cluster registered in a Fleet to enable Config Management:
```
gcloud services enable container.googleapis.com
CLUSTER_NAME=FIXME
gcloud container clusters create ${CLUSTER_NAME} \
    --workload-pool=${PROJECT_ID}.svc.id.goog \
    --zone ${ZONE}

gcloud services enable gkehub.googleapis.com
gcloud container fleet memberships register ${CLUSTER_NAME} \
    --gke-cluster ${ZONE}/${CLUSTER_NAME} \
    --enable-workload-identity

gcloud beta container fleet config-management enable
```

Install Config Sync and Policy Controller in this GKE cluster:
```
cat <<EOF > acm-config.yaml
applySpecVersion: 1
spec:
  configSync:
    enabled: true
  policyController:
    enabled: true
    templateLibraryInstalled: false
EOF
gcloud beta container fleet config-management apply \
    --membership ${CLUSTER_NAME} \
    --config acm-config.yaml
```
_Note: in this scenario, we are not installing the [default library of constraint templates](https://cloud.google.com/anthos-config-management/docs/latest/reference/constraint-template-library) because we want to deploy our own `ConstraintTemplate`._

## Deploy a Gatekeeper policy as OCI artifact with Config Sync

Create a dedicated Google Cloud Service Account with the fine granular access (`roles/artifactregistry.reader`) to that Artifact Registry repository:
```
ARTIFACT_PULLER_GSA_NAME=configsync-oci-sa
ARTIFACT_PULLER_GSA_ID=${ARTIFACT_PULLER_GSA_NAME}@$project.iam.gserviceaccount.com
gcloud iam service-accounts create ${ARTIFACT_PULLER_GSA_NAME} \
  --display-name=${ARTIFACT_PULLER_GSA_NAME}
gcloud artifacts repositories add-iam-policy-binding ${ARTIFACT_REGISTRY_REPO_NAME} \
    --location $REGION \
    --member "serviceAccount:${ARTIFACT_PULLER_GSA_ID}" \
    --role roles/artifactregistry.reader
```

Allow Config Sync to synchronize resources for a specific `RootSync`: 
```
ROOT_SYNC_NAME=root-sync-policies
gcloud iam service-accounts add-iam-policy-binding \
   --role roles/iam.workloadIdentityUser \
   --member "serviceAccount:${PROJECT_ID}.svc.id.goog[config-management-system/root-reconciler-${ROOT_SYNC_NAME}]" \
   ${ARTIFACT_PULLER_GSA_ID}
```

Set up Config Sync to deploy this artifact from Artifact Registry:
```
cat << EOF | kubectl apply -f -
apiVersion: configsync.gke.io/v1beta1
kind: RootSync
metadata:
  name: ${ROOT_SYNC_NAME}
  namespace: config-management-system
spec:
  sourceFormat: unstructured
  sourceType: oci
  oci:
    image: ${REGION}-docker.pkg.dev/${PROJECT_ID}/${ARTIFACT_REGISTRY_REPO_NAME}/my-policies:1.0.0
    dir: .
    auth: gcpserviceaccount
    gcpServiceAccountEmail: ${ARTIFACT_PULLER_GSA_ID}
EOF
```

Check the sync status:
```
nomos status \
    --contexts=$(kubectl config current-context)
```

Verify that the `Constraint` and `ConstraintTemplate` are actually deployed:
```
kubectl get constraints
kubectl get constrainttemplates
```

And voila! That's how easy it is to deploy a Gatekeeper policy as an OCI artifact in a GitOps way with Config Sync.

You could even try to create a `Namespace` without any label and see what will happen :)
```
kubectl create ns test
```
Output:
```
Error from server (Forbidden): admission webhook "validation.gatekeeper.sh" denied the request: [namespace-with-owner-label] you must provide labels: {"owner"}
```

## Conclusion

In this article, you were able to package a Gatekeeper policy (`Constraint` and `ConstraintTemplate`) as an OCI artifact and push it to Google Artifact Registry thanks to [`oras`](https://oras.land/). At the end, you saw how you can sync this private OCI artifact with the `spec.oci.auth: gcpserviceaccount` setup on the Config Sync's `RootSync` setup using Workload Identity to access Google Artifact Registry.

The continuous reconciliation of GitOps will reconcile between the desired state, now stored in an OCI registry, with the actual state, running in Kubernetes. Your Gatekeeper policies as OCI artifacts are now just seen like any container images for your Kubernetes clusters as they are pulled from OCI registries. This continuous reconciliation from OCI registries, not interacting with Git, has a lot of benefits in terms of scalability, performance and security as you will be able to configure very fine grained access to your OCI artifacts, across your fleet of clusters.

## What's next

- [Deploy OCI artifacts and Helm charts the GitOps way with Config Sync](https://cloud.google.com/blog/products/containers-kubernetes/gitops-with-oci-artifacts-and-config-sync)
- [Sync Helm charts from Artifact Registry](https://cloud.google.com/anthos-config-management/docs/how-to/sync-helm-charts-from-artifact-registry)
- [Sync OCI artifacts from Artifact Registry](https://cloud.google.com/anthos-config-management/docs/how-to/sync-oci-artifacts-from-artifact-registry)
- [CI/GitOps with Helm, GitHub Actions, GitHub Container Registry and Config Sync]({{< ref "/posts/2022/09/ci-gitops-helm-github-actions-github-registry.md" >}})
- [CI/GitOps with Helm, GitHub Actions, Google Artifact Registry and Config Sync]({{< ref "/posts/2022/09/ci-gitops-helm-github-actions-google-registry.md" >}})

Hope you enjoyed that one, happy sailing! ;)