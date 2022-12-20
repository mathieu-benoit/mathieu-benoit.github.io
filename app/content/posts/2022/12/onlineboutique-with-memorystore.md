---
title: use google cloud memorystore (redis) with the online boutique sample
date: 2022-12-20
tags: [gcp, kubernetes]
description: let's see how to use google cloud memorystore (redis) with the online boutique sample.
aliases:
    - /onlineboutique-with-memorystore/
---
By default the `cartservice` of the Online Boutique sample stores its data in an in-cluster Redis database. 
Using a fully managed database service outside your GKE cluster such as [Memorystore (Redis)](https://cloud.google.com/memorystore) could bring more resiliency, scalability and more security.

> Reduce latency with scalable, secure, and highly available in-memory service for Redis.

In this article, let's see how you can connect the Online Boutique sample to Google Cloud Memorystore (Redis).

![Architecture overview.](https://github.com/mathieu-benoit/my-images/raw/main/onlineboutique-with-memorystore.png)

## Objectives

*   Create a Google Kubernetes Engine (GKE) cluster
*   Provision a Memorystore (Redis) instance
*   Deploy the Online Boutique sample connected to the Memorystore (Redis) instance

## Costs

This tutorial uses billable components of Google Cloud, including the following:

*   [Kubernetes Engine](https://cloud.google.com/kubernetes-engine/pricing)
*   [Memorystore (Redis)](https://cloud.google.com/memorystore/docs/redis/pricing)

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
ZONE=us-east5-a
```

To avoid repeating the `--project` in the commands throughout this tutorial, let's set the current project:
```bash
gcloud config set project ${PROJECT_ID}
```

## Enable the required APIs in your project

Enable the required APIs in your project:
```bash
gcloud services enable \
    redis.googleapis.com \
    container.googleapis.com
```

## Create a GKE cluster

```bash
CLUSTER=memorystore-with-onlineboutique
gcloud container clusters create ${CLUSTER} \
    --zone ${ZONE} \
    --machine-type=e2-standard-4 \
    --num-nodes 4 \
    --network default
```

## Provision the Memorystore (Redis) instance

```bash
REDIS_NAME=memorystore-with-onlineboutique
gcloud redis instances create ${REDIS_NAME} \
    --size 1 \
    --region ${REGION} \
    --zone ${ZONE} \
    --redis-version redis_6_x \
    --network default
```

Notes:
- You can connect to a Memorystore (Redis) instance from GKE clusters that are in the same region and use the same network as your instance.
- You cannot connect to a Memorystore (Redis) instance from a GKE cluster without VPC-native/IP aliasing enabled.

Wait for the Memorystore (Redis) instance to be succesfully provisioned and then get the connection information (private IP address and port):
```bash
REDIS_IP=$(gcloud redis instances describe ${REDIS_NAME} \
    --region ${REGION} \
    --format 'get(host)')
REDIS_PORT=$(gcloud redis instances describe ${REDIS_NAME} \
    --region ${REGION} \
    --format 'get(port)')
```

## Deploy Online Boutique connected to the Spanner database

Deploy the Online Boutique sample apps without the default in-cluster Redis database, and now pointing to the Memorystore (Redis) instance:
```bash
NAMESPACE=onlineboutique
helm upgrade onlineboutique oci://us-docker.pkg.dev/online-boutique-ci/charts/onlineboutique \
    --install \
    --create-namespace \
    -n ${NAMESPACE} \
    --set cartDatabase.inClusterRedis.create=false \
    --set cartDatabase.connectionString=${REDIS_IP}:${REDIS_PORT}
```

After all the apps have successfully been deployed, you could navigate to the Online Boutique website by clicking on the link below:
```bash
echo -n "http://" && kubectl get svc frontend-external -n ${NAMESPACE} -o json | jq -r '.status.loadBalancer.ingress[0].ip'
```

And voilà, that's how easy you can connect your Online Boutique sample apps to a Memorystore (Redis) database, congrats!

## Cleaning up

To avoid incurring charges to your Google Cloud account, you can delete the resources used in this tutorial.

Delete the GKE cluster:
```bash
gcloud container clusters delete ${CLUSTER} \
    --zone ${ZONE}
```

Delete the Memorystore (redis) instance:
```bash
gcloud redis instances delete ${REDIS_NAME}
```

## Conclusion

Having the database outside of your GKE cluster with a managed service can bring you more resiliency, scalability and security. This setup allows complex scenarios like having your apps spreaded across multiple clusters, etc.

## Further resources

- [Google Cloud Memorystore for Redis Best Practices - Tips for a highly performant and worry-free deployment](https://cloud.google.com/blog/products/databases/best-pactices-for-cloud-memorystore-for-redis/)
- [Seamlessly encrypt traffic from any apps in your Mesh to Memorystore (Redis)]({{< ref "/posts/2022/08/encrypt-traffic-from-mesh-to-memorystore.md" >}})

Happy sailing, cheers!