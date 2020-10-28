---
title: bank of anthos on gke
date: 2020-10-18
tags: [gcp, kubernetes, security]
description: fixme
draft: true
aliases:
    - /demo-bank/
---
[![](https://github.com/GoogleCloudPlatform/bank-of-anthos/raw/master/docs/architecture.png)](https://github.com/GoogleCloudPlatform/bank-of-anthos/raw/master/docs/architecture.png)

Today we'll deploy the [Demo Bank source code](https://github.com/GoogleCloudPlatform/bank-of-anthos/) on a GKE cluster. This source code was leveraged during one of the [App Modernization keynotes during Google Next OnAir 2020](): [Hands-on Keynote: Building trust for speedy innovation](https://youtu.be/7QR1z35h_yc).

> Demo Bank (aka Bank of Anthos) is a sample HTTP-based web app that simulates a bank's payment processing network, allowing users to create artificial bank accounts and complete transactions.

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

```
git clone https://github.com/GoogleCloudPlatform/bank-of-anthos.git
cd bank-of-anthos

kubectl apply -f ./extras/jwt/jwt-secret.yaml

kubectl apply -f ./kubernetes-manifests

kubectl get pods

kubectl get service frontend | awk '{print $4}'
```

There is more goodies for sure:
- Istio
- ASM
- Anthos
- [Machine Learning demo](https://github.com/GoogleCloudPlatform/bank-of-anthos/tree/sara-ml/machine-learning)
- [Spring Cloud GCP demo](https://github.com/GoogleCloudPlatform/bank-of-anthos/tree/next-demo-part-2)

Hope you enjoyed that one, cheers!