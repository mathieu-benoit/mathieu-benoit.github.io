---
title: config connector, manage gcp resources via kubernetes
date: 2021-03-24
tags: [kubernetes, gcp]
description: let's see how to manage gcp resources via kubernetes
draft: true
aliases:
    - /config-connector/
---
https://cloud.google.com/sdk/gcloud/reference/alpha/resource-config/bulk-export --> krm

Sign here! Creating a policy contract with Configuration as Data
https://cloud.google.com/blog/products/containers-kubernetes/how-configuration-as-data-impacts-policy


FIXME:
- https://github.com/GoogleCloudPlatform/anthos-security-blueprints
- https://cloud.google.com/architecture/blueprints/anthos-security-blueprints-faq
- https://www.linkedin.com/pulse/config-data-connector-kcc-gitops-karthik-ramamoorthy


> Many cloud-native development teams work with a mix of configuration systems, APIs, and tools to manage their infrastructure. This mix is often difficult to understand, leading to reduced velocity and expensive mistakes. [Config Connector](https://cloud.google.com/config-connector/docs/overview) provides a method to configure many Google Cloud services and resources using Kubernetes tooling and APIs.

> Config Connector is a Kubernetes addon that allows you to manage Google Cloud resources through Kubernetes.

## Let's install Config Connector

Let's [install Config Connector](https://cloud.google.com/config-connector/docs/concepts/installation-types) on any Kubernetes cluster:
```
gsutil cp gs://configconnector-operator/latest/release-bundle.tar.gz release-bundle.tar.gz
tar zxvf release-bundle.tar.gz
kubectl apply -f operator-system/configconnector-operator.yaml
```
_Note: The installation of Config Connector by its Operator is the recommended way, even on GKE. It will give you more flexibility and control with Config Connector versions, etc. rather than installing it via its [GKE add-on](https://cloud.google.com/config-connector/docs/how-to/install-upgrade-uninstall) or its [ACM component](https://cloud.google.com/anthos-config-management/docs/how-to/installing-config-connector)._


```
apiVersion: core.cnrm.cloud.google.com/v1beta1
kind: ConfigConnector
metadata:
  # the name is restricted to ensure that there is only ConfigConnector
  # instance installed in your cluster
  name: configconnector.core.cnrm.cloud.google.com
spec:
 mode: cluster
 credentialSecretName: SECRET_NAME
```

Let's now check the installation:
```
# Check if the installation went well:
kubectl get all -n cnrm-system
kubectl get ConfigConnector

kubectl describe ns configconnector-operator-system | grep "operator-version"

# List all the GCP resources available with Config Connector:
kubectl get crds --selector cnrm.cloud.google.com/managed-by-kcc=true
```

FIXME:
- How to upgrade --> https://cloud.google.com/config-connector/docs/how-to/install-other-kubernetes#upgrading
- Config Connector's Release notes page: https://cloud.google.com/config-connector/docs/release-notes
- Config Connector's GitHub repo: https://github.com/GoogleCloudPlatform/k8s-config-connector

## Let's now deploy our first GCP resources via Kubernetes

Get started as example?
https://cloud.google.com/config-connector/docs/how-to/getting-started

Import resources
gcloud alpha resource-config bulk-export --help

## Further considerations

Anthos security blueprint: Enforcing policies
https://cloud.google.com/architecture/blueprints/anthos-enforcing-policies-blueprint

Validating apps against company policies in a CI pipeline
https://cloud.google.com/anthos-config-management/docs/how-to/app-policy-validation-ci-pipeline

Creating policy-compliant Google Cloud resources
https://cloud.google.com/solutions/policy-compliant-resources

## Complementary resources

- [Cloud Native Resource Management (Cloud Next '19)](https://youtu.be/s_hiFuRDJSE)
- [I do declare! Infrastructure automation with Configuration as Data](https://cloud.google.com/blog/products/containers-kubernetes/understanding-configuration-as-data-in-kubernetes)
- [How GitOps and the KRM make multi-cloud less scary](https://seroter.com/2021/01/12/how-gitops-and-the-krm-make-multi-cloud-less-scary/)
- [Tutorial: Use Google Config Connector to Manage a GCP Cloud SQL Database](https://thenewstack.io/tutorial-use-google-config-connector-to-manage-a-gcp-cloud-sql-database/)
- [Cloud Foundation Toolkit Config Connector Solutions](https://github.com/GoogleCloudPlatform/cloud-foundation-toolkit/tree/master/config-connector/solutions)

Hope you enjoyed that one, happy sailing, cheers!