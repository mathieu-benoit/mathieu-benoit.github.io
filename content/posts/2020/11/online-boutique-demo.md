---
title: online boutique demo
date: 2020-11-08
tags: [gcp, containers, kubernetes, security]
description: let's see how to deploy the online boutique solution on gke, w/ or w/o workload identity
draft: true
aliases:
    - /online-boutique-demo/
---
[![](https://github.com/GoogleCloudPlatform/microservices-demo/raw/master/docs/img/architecture-diagram.png)](https://github.com/GoogleCloudPlatform/microservices-demo/raw/master/docs/img/architecture-diagram.png)

> [`Online Boutique`](https://github.com/GoogleCloudPlatform/microservices-demo) is a cloud-native microservices demo application. Online Boutique consists of a 10-tier microservices application. The application is a web-based e-commerce app where users can browse items, add them to the cart, and purchase them.

```
git clone https://github.com/GoogleCloudPlatform/microservices-demo
cd microservices-demo

# Assumption here that you already have a GCP project and a GKE cluster in it
projectId=FIXME
clusterName=FIXME
clusterZone=FIXME
gcloud config set project $projectId
gcloud container clusters get-credentials $clusterName \
    --zone $zone

# Create a dedicated namespace
namespace=online-boutique
kubectl create ns $namespace
kubectl config set-context \
    --current \
    --namespace $namespace
```

## Deploy on GKE

https://github.com/GoogleCloudPlatform/microservices-demo#option-2-running-on-google-kubernetes-engine-gke

You could for quick deployments do `kubectl apply -f release/kubernetes-manifests.yaml` or `skaffold run --default-repo=gcr.io/$projectId`. In my case I would like to manually build and push the container images and then deploy the on my GKE with Workload Identity enabled:
```
# Let's build and push the container images in our own private GCR (duration ~40 min)
gcrRepo=gcr.io/$projectId/microservices-demo
tag=v0.2.1
files="`pwd`/src/*"
for f in $files; do docker build -t $gcrRepo/`basename $f`:$tag $f; docker push $gcrRepo/`basename $f`:$tag; done

# Let's create the namespace and service account
namespace=online-boutique
kubectl create namespace $namespace
kubectl config set-context \
    --current \
    --namespace $namespace
ksaName=online-boutique-ksa
kubectl create serviceaccount $ksaName
gsaName=$projectId-online-boutique-gsa
gsaAccountName=$gsaName@$projectId.iam.gserviceaccount.com
gcloud iam service-accounts create $gsaName
gcloud iam service-accounts add-iam-policy-binding \
    --role roles/iam.workloadIdentityUser \
    --member "serviceAccount:$projectId.svc.id.goog[$namespace/$ksaName]" \
    $gsaAccountName
kubectl annotate serviceaccount \
    $ksaName \
    iam.gke.io/gcp-service-account=$gsaAccountName
gcloud projects add-iam-policy-binding $projectId \
    --member "serviceAccount:$gsaAccountName" \
    --role roles/cloudtrace.agent
gcloud projects add-iam-policy-binding $projectId \
    --member "serviceAccount:$gsaAccountName" \
    --role roles/monitoring.metricWriter

# Now let's deploy these containers images on GKE with Workload Identity enabled
files="`pwd`/src/*"
for f in $files; do sed -i "s,serviceAccountName: default,serviceAccountName: $ksaName,g;s,image: `basename $f`,image: $gcrRepo/`basename $f`:$tag,g" ./kubernetes-manifests/`basename $f`.yaml; done
kubectl apply \
    -f ./kubernetes-manifests
kubectl get all,secrets,configmaps,sa
kubectl get service frontend | awk '{print $4}'
```

+ Cloud Memorystore? https://cloud.google.com/memorystore/docs/redis/connect-redis-instance-gke

That's a wrap! We now have handy scripts for the `Online Boutique` solution, ready to be deployed on both GKE w/ or w/o Workload Identity.

Further and complementary resources:
- [Cloud Operations Sandbox based on the OnlineBoutique repo](https://github.com/GoogleCloudPlatform/cloud-ops-sandbox)