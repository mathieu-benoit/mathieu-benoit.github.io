---
title: demo bank on gke
date: 2020-10-29
tags: [gcp, containers, kubernetes, security]
description: let's see how to deploy the demo bank (aka bank of anthos) solution on gke, w/ or w/o workload identity
draft: true
aliases:
    - /demo-bank/
---


FIXME, take this instead + do the SRE/CLoudOps stuff in another article then?
- https://github.com/GoogleCloudPlatform/cloud-ops-sandbox
- https://github.com/GoogleCloudPlatform/cloud-ops-sandbox/blob/master/docs/README.md



```
git clone https://github.com/GoogleCloudPlatform/microservices-demo
cd microservices-demo

projectId=FIXME
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
git checkout workload-identity # temporary, we will reuse this in-progress branch/pr
files="`pwd`/src/*"
for f in $files; do sed -i "s,serviceAccountName: default,serviceAccountName: $ksaName,g;s,image: `basename $f`,image: $gcrRepo/`basename $f`:$tag,g" ./kubernetes-manifests/`basename $f`.yaml; done
kubectl apply \
    -f ./kubernetes-manifests
kubectl get all,secrets,configmaps,sa
kubectl get service frontend | awk '{print $4}'
```

Stackdriver Sandbox

```
# Let's build and push the container images in our own private GCR (duration ~40 min)
gcrRepo=gcr.io/$projectId/stackdriver-sandbox
tag=v0.4.1
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
git checkout workload-identity # temporary, we will reuse this in-progress branch/pr
files="`pwd`/src/*"
for f in $files; do sed -i "s,serviceAccountName: default,serviceAccountName: $ksaName,g;s,image: `basename $f`,image: $gcrRepo/`basename $f`:$tag,g" ./kubernetes-manifests/`basename $f`.yaml; done
kubectl apply \
    -f ./kubernetes-manifests
kubectl get all,secrets,configmaps,sa
kubectl get service frontend | awk '{print $4}'
```

+ Cloud Memorystore? https://cloud.google.com/memorystore/docs/redis/connect-redis-instance-gke








```
projectId=FIXME
cd microservices-demo/src
serviceName=FIXME
rm -r $serviceName -f
cp -r ../../cloud-ops-sandbox/src/$serviceName/ ./
docker build -t gcr.io/$projectId/microservices-demo/$serviceName:update .
docker push gcr.io/$projectId/microservices-demo/$serviceName:update
kubectl set image deployment/$serviceName $serviceName=gcr.io/$projectId/microservices-demo/$serviceName:update
kubectl logs 
```
