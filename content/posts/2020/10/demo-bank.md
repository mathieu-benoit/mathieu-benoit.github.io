---
title: demo bank on gke
date: 2020-10-29
tags: [gcp, containers, kubernetes, security]
description: let's see how to deploy the demo bank (aka bank of anthos) solution on gke, w/ or w/o workload identity
aliases:
    - /demo-bank/
---
[![](https://github.com/GoogleCloudPlatform/bank-of-anthos/raw/master/docs/architecture.png)](https://github.com/GoogleCloudPlatform/bank-of-anthos/raw/master/docs/architecture.png)

Today we'll deploy the [`Demo Bank` source code](https://github.com/GoogleCloudPlatform/bank-of-anthos/) on a GKE cluster. This source code was leveraged during one of the keynotes of [Google Next OnAir 2020, App Modernization week]({{< ref "/posts/2020/08/app-modernization-google-next-2020.md" >}}): [Hands-on Keynote: Building trust for speedy innovation](https://youtu.be/7QR1z35h_yc).

> `Demo Bank` (aka `Bank of Anthos`) is a sample HTTP-based web app that simulates a bank's payment processing network, allowing users to create artificial bank accounts and complete transactions.

| Service | Language | Description |
| ------- | -------- | ----------- |
| [frontend](https://github.com/GoogleCloudPlatform/bank-of-anthos/tree/master/src/frontend) | Python | Exposes an HTTP server to serve the website. Contains login page, signup page, and home page |
| [ledger-writer](https://github.com/GoogleCloudPlatform/bank-of-anthos/tree/master/src/ledgerwriter) | Java | Accepts and validates incoming transactions before writing them to the ledger |
| [balance-reader](https://github.com/GoogleCloudPlatform/bank-of-anthos/tree/master/src/balancereader) | Java | Provides efficient readable cache of user balances, as read from `ledger-db` |
| [transaction-history](https://github.com/GoogleCloudPlatform/bank-of-anthos/tree/master/src/transactionhistory) | Java | Provides efficient readable cache of past transactions, as read from `ledger-db` |
| [ledger-db](https://github.com/GoogleCloudPlatform/bank-of-anthos/tree/master/src/ledger-db) | PostgreSQL | Ledger of all transactions. Option to pre-populate with transactions for demo users |
| [user-service](https://github.com/GoogleCloudPlatform/bank-of-anthos/tree/master/src/userservice) | Python | Manages user accounts and authentication. Signs JWTs used for authentication by other services |
| [contacts](https://github.com/GoogleCloudPlatform/bank-of-anthos/tree/master/src/contacts) | Python | Stores list of other accounts associated with a user. Used for drop down in "Send Payment" and "Deposit" forms |
| [accounts-db](https://github.com/GoogleCloudPlatform/bank-of-anthos/tree/master/src/accounts-db) | PostgreSQL | Database for user accounts and associated data. Option to pre-populate with demo users |
| [loadgenerator](https://github.com/GoogleCloudPlatform/bank-of-anthos/tree/master/src/loadgenerator) | Python/Locust | Continuously sends requests imitating users to the frontend. Periodically creates new accounts and simulates transactions between them |

```
git clone https://github.com/GoogleCloudPlatform/bank-of-anthos.git
cd bank-of-anthos

# Assumption here that you already have a GCP project and a GKE cluster in it
projectId=FIXME
clusterName=FIXME
clusterZone=FIXME
gcloud config set project $projectId
gcloud container clusters get-credentials $clusterName \
    --zone $zone

# Create a dedicated namespace
namespace=bank
kubectl create ns $namespace
kubectl config set-context \
    --current \
    --namespace $namespace
```

Now, I provide 3 options with associated script to deploy this solution on GKE:
- [With pre-built images]({{< ref "#deployment-on-gke-with-pre-built-images" >}})
- [With custom and private images]({{< ref "#deployment-on-gke-with-custom-and-private-images" >}})
- [With Workload Identity]({{< ref "#deployment-on-gke-with-workload-identity" >}})

## Deployment on GKE with pre-built images

```
kubectl apply \
    -f ./extras/jwt/jwt-secret.yaml
kubectl apply \
    -f ./kubernetes-manifests
kubectl get all,secrets,configmaps
kubectl get service frontend | awk '{print $4}'
```

## Deployment on GKE with custom and private images

In some cases you may need to only deploy container images coming from your own private GCR, for example if you have your GKE cluster leveraging [Binary Authorization]({{< ref "/posts/2020/11/binauthz.md" >}}).

```
publicGcrRepo=gcr.io/bank-of-anthos
privateGcrRepo=gcr.io/$projectId/bank-of-anthos
services="accounts-db balancereader contacts frontend ledger-db ledgerwriter loadgenerator transactionhistory userservice"
imageTag=$(curl -s https://api.github.com/repos/GoogleCloudPlatform/bank-of-anthos/releases | jq -r '[.[]] | .[0].tag_name')

# Copy the pre-built images into your own private GCR:
for s in $services; do docker pull $publicGcrRepo/$s:$imageTag; docker tag $publicGcrRepo/$s:$imageTag $privateGcrRepo/$s:$imageTag; docker push $privateGcrRepo/$s:$imageTag; done

# Update the Kubernetes manifests with these new container images
cd kubernetes-manifests
mv transaction-history.yaml transactionhistory.yaml; mv ledger-writer.yaml ledgerwriter.yaml; mv balance-reader.yaml balancereader.yaml # tmp to have consistent namings to properly execute the next command.
for s in $services; do sed -i "s,image: $publicGcrRepo/$s:$imageTag,image: $privateGcrRepo/$s:$imageTag,g" $s.yaml; done

# Deploy the solution
kubectl apply \
    -f ./extras/jwt/jwt-secret.yaml
kubectl apply \
    -f ./kubernetes-manifests
kubectl get all,secrets,configmaps,sa
kubectl get service frontend | awk '{print $4}'
```

_Note: Instead of moving the container images from the public registry to your own private registry, you may want to leverage both `Docker` and [`Jib`](https://github.com/GoogleContainerTools/jib#jib) to build your own container images from the source code._

## Deployment on GKE with Workload Identity

_Note: It's highly recommended to have your GKE clusters with Workload Identity enabled, I discussed about the why and how if you are interested in knowing more, here: [GKE’s service account]({{< ref "/posts/2020/10/gke-service-account.md" >}})._

```
# Create a dedicated service account
ksaName=bank-ksa
kubectl create serviceaccount $ksaName
gsaName=$projectId-bank-gsa
gsaAccountName=$gsaName@$projectId.iam.gserviceaccount.com
gcloud iam service-accounts create $gsaName
gcloud iam service-accounts add-iam-policy-binding \
    --role roles/iam.workloadIdentityUser \
    --member "serviceAccount:$projectId.svc.id.goog[$namespace/$ksaName]" \
    $gsaAccountName
kubectl annotate serviceaccount \
    $ksaName \
    iam.gke.io/gcp-service-account=$gsaAccountName
roles="roles/cloudtrace.agent roles/monitoring.metricWriter"
for r in $roles; do gcloud projects add-iam-policy-binding $projectId --member "serviceAccount:$gsaAccountName" --role $r; done

# Update the Kubernetes manifests with this service account
files="`pwd`/kubernetes-manifests/*"
for f in $files; do sed -i "s/serviceAccountName: default/serviceAccountName: $ksaName/g" $f; done

# Deploy the solution
kubectl apply \
    -f ./extras/jwt/jwt-secret.yaml
kubectl apply \
    -f ./kubernetes-manifests
kubectl get all,secrets,configmaps,sa
kubectl get service frontend | awk '{print $4}'
```

That's a wrap! We now have handy scripts for the `Demo Bank` (aka `Bank of Anthos`) solution, ready to be deployed on both GKE w/ or w/o Workload Identity.

Hope you enjoyed that one, happy sailing, cheers!