---
title: fixme
date: 2021-01-06
tags: [containers, security]
description: fixme
draft: true
aliases:
    - /fixme/
---
https://github.com/GoogleCloudPlatform/k8s-config-connector
https://cloud.google.com/config-connector/docs/reference/overview

I do declare! Infrastructure automation with Configuration as Data
https://cloud.google.com/blog/products/containers-kubernetes/understanding-configuration-as-data-in-kubernetes

How GitOps and the KRM make multi-cloud less scary
https://seroter.com/2021/01/12/how-gitops-and-the-krm-make-multi-cloud-less-scary/
--> attached clusters, ACM, Config Connector

Cloud Foundation Toolkit Config Connector Solutions
https://github.com/GoogleCloudPlatform/cloud-foundation-toolkit/tree/master/config-connector/solutions

```
# Your cluster need to be on Regular or Rapid channel 
gcloud container clusters create CLUSTER_NAME \
    --addons ConfigConnector


gcloud container clusters update CLUSTER_NAME \
    --update-addons ConfigConnector=ENABLED
``

```

```

```
# Check if the installation went well:
kubectl get all -n cnrm-system
kubectl get ConfigConnector

# List all the GCP resources available with Config Connector:
kubectl get crds --selector cnrm.cloud.google.com/managed-by-kcc=true
```

Get started as example?
https://cloud.google.com/config-connector/docs/how-to/getting-started

Notes:
- The Config Connector add-on is upgraded to a new minor release along with your GKE cluster. The resources in your cluster are preserved whenever an upgrade occurs.
- Config Connector's Release notes page: https://cloud.google.com/config-connector/docs/release-notes

Cloud Native Resource Management (Cloud Next '19)
https://youtu.be/s_hiFuRDJSE


Tutorial: Use Google Config Connector to Manage a GCP Cloud SQL Database
https://thenewstack.io/tutorial-use-google-config-connector-to-manage-a-gcp-cloud-sql-database/

Anthos security blueprint: Enforcing policies
https://cloud.google.com/architecture/blueprints/anthos-enforcing-policies-blueprint

Validating apps against company policies in a CI pipeline
https://cloud.google.com/anthos-config-management/docs/how-to/app-policy-validation-ci-pipeline

Creating policy-compliant Google Cloud resources
https://cloud.google.com/solutions/policy-compliant-resources