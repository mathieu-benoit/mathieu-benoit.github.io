---
title: workload identity federation, no service account keys necessary anymore
date: 2021-11-07
tags: [gcp, security, containers]
description: let's see how to improve your cloud security posture with workload identity federation, no service account keys necessary anymore - let's see that in actions with GitHub actions.
draft: true
aliases:
    - /wif/
    - /workload-identity-federation/
---
Keyless API authentication, better cloud security through workload identity federation, no service account keys necessary
https://cloud.google.com/blog/products/identity-security/enable-keyless-access-to-gcp-with-workload-identity-federation
https://youtu.be/4vajaXzHN08
https://cloud.google.com/iam/docs/workload-identity-federation

> Using identity federation, you can grant on-premises or multi-cloud workloads access to Google Cloud resources, without using a service account key

GitHub Actions: Secure cloud deployments with OpenID Connect
https://github.blog/changelog/2021-10-27-github-actions-secure-cloud-deployments-with-openid-connect/
https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-google-cloud-platform

> Seamless authentication between Cloud Providers and GitHub without the need for storing any long-lived cloud secrets in GitHub

> Cloud Admins can rely on the security mechanisms of their cloud provider to ensure that GitHub Actions workflows get the minimal access for cloud resources. There is no duplication of secret management in GitHub and the cloud

GitHub Action for authenticating to Google Cloud with GitHub Actions OIDC tokens and Workload Identity Federation
https://github.com/google-github-actions/auth

> This GitHub Action exchanges a GitHub Actions OIDC token into a Google Cloud access token using Workload Identity Federation. This obviates the need to export a long-lived Google Cloud service account key and establishes a trust delegation relationship between a particular GitHub Actions workflow invocation and permissions on Google Cloud

```
projectId=FIXME
gcloud config set project $projectId
gcloud iam service-accounts create "my-service-account"
saId="my-service-account@${projectId}.iam.gserviceaccount.com"

# Enable the IAM Credentials API
gcloud services enable iamcredentials.googleapis.com

# Create a Workload Identity Pool
poolName=mypool
gcloud iam workload-identity-pools create $poolName \
  --location global \
  --display-name $poolName
poolId=$(gcloud iam workload-identity-pools describe $poolName \
  --location global \
  --format='get(name)')

# Create a Workload Identity Provider with GitHub actions in that pool:
gcloud iam workload-identity-pools providers create-oidc $poolName \
  --location global \
  --workload-identity-pool $poolName \
  --display-name $poolName \
  --attribute-mapping "google.subject=assertion.sub,attribute.actor=assertion.actor,attribute.aud=assertion.aud" \
  --issuer-uri "https://token.actions.githubusercontent.com"

# Allow authentications from the Workload Identity Provider to impersonate the Service Account created above
gitHubRepoName="mathieu-benoit/cartservice"
gcloud iam service-accounts add-iam-policy-binding $saId \
  --role "roles/iam.workloadIdentityUser" \
  --member "principalSet://iam.googleapis.com/${poolId}/attribute.repository/${gitHubRepoName}"
```


From there, you can list all your service account keys in your org (``) and contact the owner to update their mecanism to authenticate with that key anymore. Ultimately, this list should be empty, in other words, no one should use a service account key! And you will eventually with confidence enable this org policy: .

Complementary and further resources:
- [Workload Identity with GKE](my-own-blog)
- []()
- []()

Hope you enjoyed that one, stay safe out there! ;)