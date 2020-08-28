---
title: fixme
date: 2020-08-10
tags: [fixme]
description: fixme
draft: true
aliases:
    - /fixme/
---

Keyless Entry: Securely Access GCP Services From Kubernetes (Cloud Next '19)
https://www.youtube.com/watch?v=s4NYEJDFc0M
By Shopify, Service Account, Workload Identity, etc.

# Use least-privilege service account

> You should [create and use a minimally privileged service account](https://cloud.google.com/kubernetes-engine/docs/how-to/hardening-your-cluster#use_least_privilege_sa) to run your GKE cluster instead of using the [Compute Engine default service account](https://cloud.google.com/compute/docs/access/service-accounts#default_service_account).

So we need to create a dedicated service account with the proper and minimal privileges and then use it to create the GKE cluster or any GKE Node pool:
```
projectId=FIXME

gcloud services enable cloudresourcemanager.googleapis.com

saName=FIXME
saId=$saName@$projectId.iam.gserviceaccount.com
gcloud iam service-accounts create $saName \
  --display-name=$saName

gcloud projects add-iam-policy-binding $projectId \
  --member "serviceAccount:$saId" \
  --role roles/logging.logWriter

gcloud projects add-iam-policy-binding $projectId \
  --member "serviceAccount:$saId" \
  --role roles/monitoring.metricWriter

gcloud projects add-iam-policy-binding $projectId \
  --member "serviceAccount:$saId" \
  --role roles/monitoring.viewer

# Example to use it at cluster creation:
gcloud container clusters create \
  --service-account=$saId

# Example to use it at nodepool creation:
gcloud container node-pools create \
  --service-account=$saId
```

# Workload Identity

https://cloud.google.com/solutions/prep-kubernetes-engine-for-prod#using_workload_identity_to_interact_with_google_cloud_service_apis
https://cloud.google.com/kubernetes-engine/docs/how-to/workload-identity



Architecting with Google Kubernetes Engine: Workloads
https://www.coursera.org/learn/deploying-workloads-google-kubernetes-engine-gke

Architecting with Google Kubernetes Engine: Production
https://www.coursera.org/learn/deploying-secure-kubernetes-containers-in-production

- [Harden workload isolation with GKE Sandbox](https://cloud.google.com/kubernetes-engine/docs/how-to/sandbox-pods)

Binary authorization
https://github.com/GoogleCloudPlatform/gke-binary-auth-demo

- RBAC?
    - https://cloud.google.com/solutions/prep-kubernetes-engine-for-prod#role-based_access_control_rbac
    - https://www.cncf.io/blog/2020/08/28/kubernetes-rbac-101-authorization/



