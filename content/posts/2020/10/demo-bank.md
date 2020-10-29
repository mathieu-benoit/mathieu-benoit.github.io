---
title: demo bank on gke
date: 2020-10-29
tags: [gcp, kubernetes, security]
description: let's see how to deploy the demo bank (aka bank of anthos) solution on gke, w/ or w/o workload identity
aliases:
    - /demo-bank/
---
[![](https://github.com/GoogleCloudPlatform/bank-of-anthos/raw/master/docs/architecture.png)](https://github.com/GoogleCloudPlatform/bank-of-anthos/raw/master/docs/architecture.png)

Today we'll deploy the [`Demo Bank` source code](https://github.com/GoogleCloudPlatform/bank-of-anthos/) on a GKE cluster. This source code was leveraged during one of the keynotes of [Google Next OnAir 2020, App Modernization week](): [Hands-on Keynote: Building trust for speedy innovation](https://youtu.be/7QR1z35h_yc).

> `Demo Bank` (aka `Bank of Anthos`) is a sample HTTP-based web app that simulates a bank's payment processing network, allowing users to create artificial bank accounts and complete transactions.

```
git clone https://github.com/GoogleCloudPlatform/bank-of-anthos.git
cd bank-of-anthos
```

| Service                                          | Language      | Description                                                                                                                                  |
| ------------------------------------------------ | ------------- | -------------------------------------------------------------------------------------------------------------------------------------------- |
| [frontend](./src/frontend)                       | Python        | Exposes an HTTP server to serve the website. Contains login page, signup page, and home page.                                                |
| [ledger-writer](./src/ledgerwriter)              | Java          | Accepts and validates incoming transactions before writing them to the ledger.                                                               |
| [balance-reader](./src/balancereader)            | Java          | Provides efficient readable cache of user balances, as read from `ledger-db`.                                                                |
| [transaction-history](./src/transactionhistory)  | Java          | Provides efficient readable cache of past transactions, as read from `ledger-db`.                                                            |
| [ledger-db](./src/ledger-db)                     | PostgreSQL    | Ledger of all transactions. Option to pre-populate with transactions for demo users.                                                         |
| [user-service](./src/userservice)                | Python        | Manages user accounts and authentication. Signs JWTs used for authentication by other services.                                              |
| [contacts](./src/contacts)                       | Python        | Stores list of other accounts associated with a user. Used for drop down in "Send Payment" and "Deposit" forms.                              |
| [accounts-db](./src/accounts-db)                 | PostgreSQL    | Database for user accounts and associated data. Option to pre-populate with demo users.                                                      |
| [loadgenerator](./src/loadgenerator)             | Python/Locust | Continuously sends requests imitating users to the frontend. Periodically creates new accounts and simulates transactions between them.      |

## Deployment on GKE

```
namespace=bank
kubectl create namespace $namespace
kubectl config set-context \
    --current \
    --namespace $namespace
kubectl apply \
    -f ./extras/jwt/jwt-secret.yaml
kubectl apply \
    -f ./kubernetes-manifests
kubectl get all,secrets,configmaps
kubectl get service frontend | awk '{print $4}'
```

## Deployment on GKE with Workload Identity

_Note: It's highly recommended to have your GKE clusters with Workload Identity enabled, I discussed about the why and how if you are interested in knowing more here: [GKE’s service account]({{< ref "/posts/2020/10/gke-service-account.md" >}})._

```
gkeProjectId=FIXME
namespace=bank
kubectl create namespace $namespace
kubectl config set-context \
    --current \
    --namespace $namespace
ksaName=bank-ksa
kubectl create serviceaccount $ksaName
gsaName=$gkeProjectId-bank-gsa
gcloud iam service-accounts create $gsaName
gcloud iam service-accounts add-iam-policy-binding \
    --role roles/iam.workloadIdentityUser \
    --member "serviceAccount:$gkeProjectId.svc.id.goog[$namespace/$ksaName]" \
    $gsaName@$gkeProjectId.iam.gserviceaccount.com
kubectl annotate serviceaccount \
    $ksaName \
    iam.gke.io/gcp-service-account=$gsaName@$gkeProjectId.iam.gserviceaccount.com
gcloud projects add-iam-policy-binding $gkeProjectId \
    --member "serviceAccount:$gsaName@$gkeProjectId.iam.gserviceaccount.com" \
    --role roles/cloudtrace.agent
gcloud projects add-iam-policy-binding $gkeProjectId \
    --member "serviceAccount:$gsaName@$gkeProjectId.iam.gserviceaccount.com" \
    --role roles/monitoring.metricWriter
mkdir -p wi-kubernetes-manifests
files="`pwd`/kubernetes-manifests/*"
for f in $files; do sed "s/serviceAccountName: default/serviceAccountName: $ksaName/g" $f > wi-kubernetes-manifests/`basename $f`; done
kubectl apply \
    -f ./extras/jwt/jwt-secret.yaml
kubectl apply \
    -f ./wi-kubernetes-manifests
kubectl get all,secrets,configmaps,sa
kubectl get service frontend | awk '{print $4}'
```

That's a wrap! We now have handy scripts for the `Demo Bank` (aka `Bank of Anthos`) solution, ready to be deployed on both GKE w/ or w/o Workload Identity.

Hope you enjoyed that one, happy sailing, cheers!