---
title: fixme
date: 2021-03-06
tags: [containers, security]
description: fixme
draft: true
aliases:
    - /fixme/
---

gcloud alpha resource-config bulk-export --help

https://cloud.google.com/config-connector/docs/reference/overview

I do declare! Infrastructure automation with Configuration as Data
https://cloud.google.com/blog/products/containers-kubernetes/understanding-configuration-as-data-in-kubernetes

How GitOps and the KRM make multi-cloud less scary
https://seroter.com/2021/01/12/how-gitops-and-the-krm-make-multi-cloud-less-scary/
--> attached clusters, ACM, Config Connector

Cloud Foundation Toolkit Config Connector Solutions
https://github.com/GoogleCloudPlatform/cloud-foundation-toolkit/tree/master/config-connector/solutions


Installation via Config Management:
```
cat > ~/tmp/config-management.yaml << EOF
apiVersion: configmanagement.gke.io/v1
kind: ConfigManagement
metadata:
  name: config-management
spec:
  configConnector:
    enabled: true
EOF
kubectl apply -f ~/tmp/config-management.yaml
```
Note: advanced installation via Operator: https://cloud.google.com/config-connector/docs/how-to/advanced-install

```
# Check if the installation went well:
kubectl get all -n cnrm-system
kubectl get ConfigConnector

# List all the GCP resources available with Config Connector:
kubectl get crds --selector cnrm.cloud.google.com/managed-by-kcc=true
```

FIXME:
- How to get kcc version?
- How to upgrade --> https://cloud.google.com/config-connector/docs/how-to/install-other-kubernetes#upgrading

Get started as example?
https://cloud.google.com/config-connector/docs/how-to/getting-started

- Config Connector's Release notes page: https://cloud.google.com/config-connector/docs/release-notes
- Config Connector's GitHub repo: https://github.com/GoogleCloudPlatform/k8s-config-connector

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