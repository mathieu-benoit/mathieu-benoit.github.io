---
title: keyless gcp authentication from github actions with workload identity federation
date: 2022-01-30
tags: [gcp, security, containers]
description: let's see how to use a keyless gcp authentication from github actions with workload identity federation
aliases:
    - /wif/
    - /workload-identity-federation/
---
Last November 2021, GitHub announced the GA support of [OpenID Connect (OIDC) with GitHub actions](https://github.blog/2021-11-23-secure-deployments-openid-connect-github-actions-generally-available/) for secure deployments to cloud, which uses short-lived tokens that are automatically rotated for each deployment. There is different providers supported lik Azure, AWS, GCP, etc. amazing! More security in CI/CD pipelines with GitHub actions!

> Seamless authentication between Cloud Providers and GitHub without the need for storing any long-lived cloud secrets in GitHub

> Cloud Admins can rely on the security mechanisms of their cloud provider to ensure that GitHub Actions workflows get the minimal access for cloud resources. There is no duplication of secret management in GitHub and the cloud.


With GCP you could use the [`google-github-actions/auth` GitHub action](https://cloud.google.com/blog/products/identity-security/enabling-keyless-authentication-from-github-actions) which leverages [Workload Identity Federation](https://cloud.google.com/blog/products/identity-security/enable-keyless-access-to-gcp-with-workload-identity-federation) as a keyless API authentication.

> Using identity federation, you can grant on-premises or multi-cloud workloads access to Google Cloud resources, without using a service account key.

> The GitHub Action [`google-github-actions/auth`](https://github.com/google-github-actions/auth) exchanges a GitHub Actions OIDC token into a Google Cloud access token using Workload Identity Federation. This obviates the need to export a long-lived Google Cloud service account key and establishes a trust delegation relationship between a particular GitHub Actions workflow invocation and permissions on Google Cloud.

Let's see this in action, first we need to configure the Workload Identity pool:
```
projectId=FIXME
gcloud config set project $projectId

# Create the Service Account
gcloud iam service-accounts create "my-service-account"
saId="my-service-account@${projectId}.iam.gserviceaccount.com"

# Enable the IAM Credentials API
gcloud services enable iamcredentials.googleapis.com

# Create a Workload Identity Pool
poolName=wi-pool
gcloud iam workload-identity-pools create $poolName \
  --location global \
  --display-name $poolName
poolId=$(gcloud iam workload-identity-pools describe $poolName \
  --location global \
  --format='get(name)')

# Create a Workload Identity Provider with GitHub actions in that pool:
attributeMappingScope=repository # could be sub (GitHub repository and branch) or repository_owner (GitHub organization)
gcloud iam workload-identity-pools providers create-oidc $poolName \
  --location global \
  --workload-identity-pool $poolName \
  --display-name $poolName \
  --attribute-mapping "google.subject=assertion.${attributeMappingScope},attribute.actor=assertion.actor,attribute.aud=assertion.aud" \
  --issuer-uri "https://token.actions.githubusercontent.com"
providerId=$(gcloud iam workload-identity-pools providers describe $poolName \
  --location global \
  --workload-identity-pool $poolName \
  --format='get(name)')

# Allow authentications from the Workload Identity Provider to impersonate the Service Account created above
gitHubRepoName="repo-org/repo-name"
gcloud iam service-accounts add-iam-policy-binding $saId \
  --role "roles/iam.workloadIdentityUser" \
  --member "principalSet://iam.googleapis.com/${poolId}/attribute.${attributeMappingScope}/${gitHubRepoName}"
```

Then, we could leverage Workload Identity Federation from GitHub actions:
```
...
jobs:
  job:
    permissions:
      contents: 'read'
      id-token: 'write'
    steps:
      - uses: actions/checkout@v2.4.0
      - id: gcp-auth
        uses: google-github-actions/auth@v0.5.0
        with:
          workload_identity_provider: '${providerId}'
          service_account: '${saId}'
      - uses: google-github-actions/setup-gcloud@v0.4.0
```

That's pretty much it, any next steps could interact with GCP depending on the roles you will assign to the associated Service Account created earlier.

There is other scenario where you will need a [short-lived access token](https://github.com/google-github-actions/auth#generating-an-oauth-20-access-token), below is an example with `Docker` commands:
```
...
jobs:
  job:
    permissions:
      contents: 'read'
      id-token: 'write'
    steps:
      - uses: actions/checkout@v2.4.0
      - id: gcp-auth
        uses: google-github-actions/auth@v0.5.0
        with:
          workload_identity_provider: '${providerId}'
          service_account: '${saId}'
          token_format: 'access_token'
      - name: sign-in to artifact registry
        run: |
          echo "${{ steps.gcp-auth.outputs.access_token }}" | docker login -u oauth2accesstoken --password-stdin ${location}-docker.pkg.dev
      - name: build and push container
        run: |
          docker build ...
          docker push ...
```
In this scenario, you will need to grant the Service Account with 2 roles:
```
gcloud projects add-iam-policy-binding $projectId \
  --member "serviceAccount:$saId" \
  --role "roles/iam.serviceAccountTokenCreator"
gcloud artifacts repositories add-iam-policy-binding $artifactRegistryName \
    --project $projectId \
    --location $location \
    --member "serviceAccount:$saId" \
    --role roles/artifactregistry.writer
```

That's a wrap, no excuses anymore to use the not recommended approach with the Service Account keys!

Complementary and further resources:
- [What is Workload Identity Federation?](https://youtu.be/4vajaXzHN08)
- [Best practices for using workload identity federation](https://cloud.google.com/iam/docs/best-practices-for-using-workload-identity-federation)
- []()

Hope you enjoyed that one, stay safe out there! ;)