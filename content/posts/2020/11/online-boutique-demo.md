---
title: online boutique demo
date: 2020-11-15
tags: [gcp, containers, kubernetes, security, dotnet]
description: let's see how to deploy the online boutique solution on gke, w/ or w/o workload identity
aliases:
    - /online-boutique-demo/
---
![Architecture diagram of the Microservices demo repository showing the 10 apps and their dependencies.](https://github.com/GoogleCloudPlatform/microservices-demo/raw/master/docs/img/architecture-diagram.png)

Today we'll deploy the [`Online Boutique` source code](https://github.com/GoogleCloudPlatform/microservices-demo) on a GKE cluster.

> [`Online Boutique`](https://github.com/GoogleCloudPlatform/microservices-demo) (aka `Microservices Demo`) is a cloud-native microservices demo application. Online Boutique consists of a 10-tier microservices application. The application is a web-based e-commerce app where users can browse items, add them to the cart, and purchase them.

| Service | Language | Description |
| ------- | -------- | ----------- |
| [frontend](https://github.com/GoogleCloudPlatform/microservices-demo/src/frontend) | Go | Exposes an HTTP server to serve the website. Does not require signup/login and generates session IDs for all users automatically |
| [cartservice](https://github.com/GoogleCloudPlatform/microservices-demo/src/cartservice) | C# | Stores the items in the user's shopping cart in Redis and retrieves it |
| [productcatalogservice](https://github.com/GoogleCloudPlatform/microservices-demo/src/productcatalogservice) | Go | Provides the list of products from a JSON file and ability to search products and get individual products |
| [currencyservice](https://github.com/GoogleCloudPlatform/microservices-demo/src/currencyservice) | Node.js | Converts one money amount to another currency. Uses real values fetched from European Central Bank. It's the highest QPS service |
| [paymentservice](https://github.com/GoogleCloudPlatform/microservices-demo/src/paymentservice) | Node.js | Charges the given credit card info (mock) with the given amount and returns a transaction ID |
| [shippingservice](https://github.com/GoogleCloudPlatform/microservices-demo/src/shippingservice) | Go | Gives shipping cost estimates based on the shopping cart. Ships items to the given address (mock) |
| [emailservice](https://github.com/GoogleCloudPlatform/microservices-demo/src/emailservice) | Python | Sends users an order confirmation email (mock) |
| [checkoutservice](https://github.com/GoogleCloudPlatform/microservices-demo/src/checkoutservice) | Go | Retrieves user cart, prepares order and orchestrates the payment, shipping and the email notification |
| [recommendationservice](https://github.com/GoogleCloudPlatform/microservices-demo/src/recommendationservice) | Python | Recommends other products based on what's given in the cart |
| [adservice](https://github.com/GoogleCloudPlatform/microservices-demo/src/adservice) | Java | Provides text ads based on given context words |
| [loadgenerator](https://github.com/GoogleCloudPlatform/microservices-demo/src/loadgenerator) | Python/Locust | Continuously sends requests imitating realistic user shopping flows to the frontend |

```
git clone https://github.com/GoogleCloudPlatform/microservices-demo
cd microservices-demo

gcloud services enable cloudprofiler.googleapis.com

# Assumption here that you already have a GCP project and a GKE cluster in it
projectId=FIXME
clusterName=FIXME
clusterZone=FIXME
gcloud config set project $projectId
gcloud container clusters get-credentials $clusterName \
    --zone $clusterZone

# Create a dedicated namespace
namespace=boutique
kubectl create ns $namespace
kubectl config set-context \
    --current \
    --namespace $namespace
```

Now, here is 3 options with associated scripts to deploy this solution on GKE:
- [With pre-built images]({{< ref "#deployment-on-gke-with-pre-built-images" >}})
- [With custom and private images]({{< ref "#deployment-on-gke-with-custom-and-private-images" >}})
- [With Workload Identity]({{< ref "#deployment-on-gke-with-workload-identity" >}})

## Deployment on GKE with pre-built images

```
kubectl apply \
    -f ./release/kubernetes-manifests.yaml
kubectl get all,secrets,configmaps
kubectl get service frontend-external | awk '{print $4}'
```

## Deployment on GKE with custom and private images

In some cases you may need to only deploy container images coming from your own private container registry, for example if you have your GKE cluster leveraging [Binary Authorization]({{< ref "/posts/2020/11/binauthz.md" >}}).

```
publicContainerRegistry=gcr.io/google-samples/microservices-demo
privateContainerRegistry=us-east4-docker.pkg.dev/$projectId/containers/boutique
services="adservice cartservice checkoutservice currencyservice emailservice frontend loadgenerator paymentservice productcatalogservice recommendationservice shippingservice"
imageTag=$(curl -s https://api.github.com/repos/GoogleCloudPlatform/microservices-demo/releases | jq -r '[.[]] | .[0].tag_name')

# Copy the pre-built images into your own private GCR:
for s in $services; do docker pull $publicContainerRegistry/$s:$imageTag; docker tag $publicContainerRegistry/$s:$imageTag $privateContainerRegistry/$s:$imageTag; docker push $privateContainerRegistry/$s:$imageTag; done
docker pull redis:alpine
docker tag redis:alpine us-east4-docker.pkg.dev/$projectId/containers/boutique/redis:alpine
docker push us-east4-docker.pkg.dev/$projectId/containers/boutique/redis:alpine

# Update the Kubernetes manifests with these new container images
for s in $services; do sed -i "s,image: $s,image: $privateContainerRegistry/$s:$imageTag,g" ./kubernetes-manifests/$s.yaml; done
sed -i "s,image: redis:alpine,image: $privateContainerRegistry/redis:alpine,g" ./kubernetes-manifests/redis.yaml

# Deploy the solution
kubectl apply \
    -f ./kubernetes-manifests
kubectl get all,secrets,configmaps,sa
kubectl get service frontend-external | awk '{print $4}'
```

## Deployment on GKE with Workload Identity

_Note: It's highly recommended to have your GKE clusters with Workload Identity enabled, I discussed about the why and how if you are interested in knowing more, here: [GKE’s service account]({{< ref "/posts/2020/10/gke-service-account.md" >}})._

```
# Create a dedicated service account
ksaName=boutique-ksa
kubectl create serviceaccount $ksaName
gsaName=$projectId-boutique-gsa
gsaAccountName=$gsaName@$projectId.iam.gserviceaccount.com
gcloud iam service-accounts create $gsaName
gcloud iam service-accounts add-iam-policy-binding \
    --role roles/iam.workloadIdentityUser \
    --member "serviceAccount:$projectId.svc.id.goog[$namespace/$ksaName]" \
    $gsaAccountName
kubectl annotate serviceaccount \
    $ksaName \
    iam.gke.io/gcp-service-account=$gsaAccountName
roles="roles/cloudtrace.agent roles/monitoring.metricWriter roles/cloudprofiler.agent roles/clouddebugger.agent"
for r in $roles; do gcloud projects add-iam-policy-binding $projectId --member "serviceAccount:$gsaAccountName" --role $r; done

# Update the Kubernetes manifests with this service account
files="`pwd`/kubernetes-manifests/*"
for f in $files; do sed -i "s/serviceAccountName: default/serviceAccountName: $ksaName/g" $f; done

# Deploy the solution
kubectl apply \
    -f ./kubernetes-manifests
kubectl get all,secrets,configmaps,sa
kubectl get service frontend-external | awk '{print $4}'
```

That's a wrap! We now have handy scripts for the `Online Boutique` solution, ready to be deployed on both GKE w/ or w/o Workload Identity.

Further and complementary resources:
- [Cloud Operations Sandbox based on the OnlineBoutique repo](https://github.com/GoogleCloudPlatform/cloud-ops-sandbox)