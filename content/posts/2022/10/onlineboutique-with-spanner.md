---
title: use google cloud spanner with the onlineboutique sample apps
date: 2022-10-18
tags: [gcp, kubernetes]
description: let's see how to use google cloud spanner with the onlineboutique sample apps.
aliases:
    - /onlineboutique-with-spanner/
---
By default the `cartservice` of the Online Boutique sample apps stores its data in an in-cluster Redis database. 
Using a fully managed database service outside your GKE cluster such as [Memorystore (Redis)](https://cloud.google.com/spanner) could bring more resiliency and more security.

Since the recent [v0.4.0 version](https://github.com/GoogleCloudPlatform/microservices-demo/releases/tag/v0.4.0), the Online Boutique sample apps can now store its data in [Google Cloud Spanner](https://cloud.google.com/spanner). 

> Cloud Spanner is a fully managed relational database with unlimited scale, strong consistency, and up to 99.999% availability.

In this article, let's see how you can connect the Online Boutique sample apps to Google Cloud Spanner.

![Architecture overview.](https://github.com/mathieu-benoit/my-images/raw/main/onlineboutique-with-spanner.png)

## Objectives

*   Create a Google Kubernetes Engine (GKE) cluster with Workload Identity
*   Provision a Spanner database with a [free Spanner instance](https://cloud.google.com/blog/products/spanner/try-cloud-spanner-databases)
*   Grant the `cartservice`'s service account access to the Spanner database with a least privilege role assignment
*   Deploy the Online Boutique sample apps connected to the Spanner database with Kustomize

## Costs

This tutorial uses billable components of Google Cloud, including the following:

*   [Kubernetes Engine](https://cloud.google.com/kubernetes-engine/pricing)
*   [Spanner](https://cloud.google.com/spanner/pricing)
    *   In this tutorial we will leverage the [free Spanner instance](https://cloud.google.com/blog/products/spanner/try-cloud-spanner-databases).

Use the [pricing calculator](https://cloud.google.com/products/calculator) to generate a cost estimate based on your projected usage.

## Before you begin

This guide assumes that you have owner IAM permissions for your Google Cloud project. In production, you do not require owner permission.

1.  [Select or create a Google Cloud project](https://console.cloud.google.com/projectselector2).

1.  [Verify that billing is enabled](https://cloud.google.com/billing/docs/how-to/modify-project) for your project.

## Set up your environment

Initialize the common variables used throughout this tutorial:
```bash
PROJECT_ID=FIXME-WITH-YOUR-PROJECT-ID
REGION=us-east5
ZONE=us-east5
```

To avoid repeating the `--project` in the commands throughout this tutorial, let's set the current project:
```bash
gcloud config set project ${PROJECT_ID}
```

## Enable the required APIs in your project

Enable the required APIs in your project:
```bash
gcloud services enable \
    spanner.googleapis.com \
    container.googleapis.com
```

## Create a GKE cluster

Create a GKE cluster with Workload Identity enabled:
```bash
CLUSTER=spanner-with-onlineboutique
gcloud container clusters create ${CLUSTER} \
    --zone ${ZONE} \
    --machine-type=e2-standard-4 \
    --num-nodes 4 \
    --workload-pool ${PROJECT_ID}.svc.id.goog
```

## Provision a Spanner database

Provision the Memorystore (redis) instance allowing only in-transit encryption:
```bash
SPANNER_REGION_CONFIG=regional-${REGION}
SPANNER_INSTANCE_NAME=onlineboutique
SPANNER_DATABASE_NAME=carts

gcloud spanner instances create ${SPANNER_INSTANCE_NAME} \
    --description="online boutique shopping cart" \
    --instance-type free-instance \
    --config ${SPANNER_REGION_CONFIG}

gcloud spanner databases create ${SPANNER_DATABASE_NAME} \
    --instance ${SPANNER_INSTANCE_NAME} \
    --database-dialect GOOGLE_STANDARD_SQL \
    --ddl "CREATE TABLE CartItems (userId STRING(1024), productId STRING(1024), quantity INT64) PRIMARY KEY (userId, productId); CREATE INDEX CartItemsByUserId ON CartItems(userId);"
```
_Notes: with the latest version of gcloud we are able to provision a [free Spanner instance](https://cloud.google.com/blog/products/spanner/try-cloud-spanner-databases)._

## Grant the `cartservice`'s service account access to the Spanner database

Create a dedicated least privilege Google Service Account to allow the `cartservice`'s Kubernetes Service Account to communicate with the Spanner database:
```bash
SPANNER_DB_USER_GSA_NAME=spanner-db-user-sa
SPANNER_DB_USER_GSA_ID=${SPANNER_DB_USER_GSA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com
ONLINEBOUTIQUE_NAMESPACE=onlineboutique
CARTSERVICE_KSA_NAME=cartservice

gcloud iam service-accounts create ${SPANNER_DB_USER_GSA_NAME} \
    --display-name=${SPANNER_DB_USER_GSA_NAME}
gcloud spanner instances add-iam-policy-binding ${SPANNER_INSTANCE_NAME} \
    --member "serviceAccount:${SPANNER_DB_USER_GSA_ID}" \
    --role roles/spanner.databaseUser

gcloud iam service-accounts add-iam-policy-binding ${SPANNER_DB_USER_GSA_ID} \
    --member "serviceAccount:${PROJECT_ID}.svc.id.goog[${ONLINEBOUTIQUE_NAMESPACE}/${CARTSERVICE_KSA_NAME}]" \
    --role roles/iam.workloadIdentityUser
```

## Deploy Online Boutique connected to the Spanner database

To automate the deployment of Online Boutique integrated with Spanner we will leverage the associated Kustomize overlays.

Define the Kustomize manifest:
```bash
cat <<EOF> kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
- github.com/GoogleCloudPlatform/microservices-demo/kustomize/base
components:
- github.com/GoogleCloudPlatform/microservices-demo/kustomize/components/service-accounts
- spanner
EOF
mkdir spanner
curl -L https://raw.githubusercontent.com/GoogleCloudPlatform/microservices-demo/main/kustomize/components/spanner/kustomization.yaml > spanner/kustomization.yaml
```

Update the Kustomize manifest to target this specific Spanner database.
```bash
sed -i "s/SPANNER_PROJECT/${PROJECT_ID}/g" spanner/kustomization.yaml
sed -i "s/SPANNER_INSTANCE/${SPANNER_INSTANCE_NAME}/g" spanner/kustomization.yaml
sed -i "s/SPANNER_DATABASE/${SPANNER_DATABASE_NAME}/g" spanner/kustomization.yaml
sed -i "s/SPANNER_DB_USER_GSA_ID/${SPANNER_DB_USER_GSA_ID}/g" spanner/kustomization.yaml
```

Deploy the Online Boutique sample apps:
```bash
kubectl create namespace ${ONLINEBOUTIQUE_NAMESPACE}
kubectl apply \
    -k . \
    -n ${ONLINEBOUTIQUE_NAMESPACE}
```

After all the apps have successfully been deployed, you could navigate to the Online Boutique website by clicking on the link below:
```bash
echo -n "http://" && kubectl get svc frontend-external -n ${ONLINEBOUTIQUE_NAMESPACE} -o json | jq -r '.status.loadBalancer.ingress[0].ip'
```

From the Online Boutique websiste, you can add some products in your shopping cart and then you can click on the link below to see all the data serialized in the Spanner database by you and the `loadgenerator` app:
```bash
echo -e "https://console.cloud.google.com/spanner/instances/${SPANNER_INSTANCE_NAME}/databases/${SPANNER_DATABASE_NAME}/tables/CartItems/details/data?project=${PROJECT_ID}"
```

And voilà, that's how easy you can connect your Online Boutique sample apps to a Spanner database, congrats!

## Cleaning up

To avoid incurring charges to your Google Cloud account, you can delete the resources used in this tutorial.

Delete the GKE cluster:
```bash
gcloud container clusters delete ${CLUSTER} \
    --zone ${ZONE}
```

Delete the Spanner database:
```bash
gcloud spanner instances delete ${SPANNER_INSTANCE_NAME}
```

## Conclusion

Having the database outside of your GKE cluster with a managed service can bring you more resiliency and security, and with this new Cloud Spanner option the Online Boutique will become more highly available. This setup allows complex scenarios like having your apps spreaded across multiple clusters, etc.

Thanks to the original implementation of [Daniel Quinlan](https://www.linkedin.com/in/%F0%9F%8C%8Ddaniel-quinlan-51126016/), this new Spanner option is now available to everyone in the Online Boutique GitHub repository, feel free to [give it a try](https://github.com/GoogleCloudPlatform/microservices-demo/tree/main/kustomize/components/spanner)!

Happy sailing, cheers!