---
title: deploy a containerize app on gke with cloud build
date: 2020-08-10
tags: [gcp, containers, kubernetes]
description: let's see how to use google cloud build to deploy a containerized app on gke
draft: true
aliases:
    - /cloud-build-with-gke/
---
Today we will see how to deploy a containerized app on GKE by leveraging [Google Cloud Build](https://cloud.google.com/cloud-build/).

We will first setup the [Continuous Integration (CI)]({{< ref "#ci" >}}) part to build and push the containerized app in Google Container Registry and then we will setup the [Continuous Delivery (CD)]({{< ref "#cd" >}}) part to eventually deploy this containerized app on GKE.


https://github.com/GoogleCloudPlatform/cloud-builders
https://cloud.google.com/cloud-build/docs/interacting-with-dockerhub-images
https://cloud.google.com/cloud-build/docs/configuring-builds/use-community-and-custom-builders
https://cloud.google.com/kubernetes-engine/docs/tutorials/gitops-cloud-build
https://cloud.google.com/vpc-service-controls/docs/supported-products#build

# CI

```
projectId=FIXME
gcloud services enable cloudbuild.googleapis.com

gcloud beta builds triggers create github \
    --repo-name=[REPO_NAME] \
    --repo-owner=[REPO_OWNER] \
    --branch-pattern=".*" \
    --build-config=[BUILD_CONFIG_FILE]

gcloud services enable containeranalysis.googleapis.com
gcloud services enable containerscanning.googleapis.com
```

# CD

```
PROJECT_NUMBER="$(gcloud projects describe ${PROJECT_ID} --format='get(projectNumber)')"
gcloud projects add-iam-policy-binding ${PROJECT_NUMBER} \
    --member=serviceAccount:${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com \
    --role=roles/container.developer
```

You could find my final [`cloudbuild.yaml` file in GitHub](https://github.com/mathieu-benoit/myblog/blob/master/cloudbuild.yaml).

Complementary resources:
- [CI/CD on Google Cloud](https://cloud.google.com/docs/ci-cd)
- [CodeLabs - Achieve continuous deployment to Google Kubernetes Engine (GKE) with Cloud Build](https://codelabs.developers.google.com/codelabs/cloud-builder-gke-continuous-deploy/index.html)
- [Using Kaniko cache](https://cloud.google.com/cloud-build/docs/kaniko-cache)
- [GitHub Actions self-hosted runners on Google Cloud](https://github.blog/2020-08-04-github-actions-self-hosted-runners-on-google-cloud/)

Hope you enjoyed this blog article, happy sailing! ;)

https://github.com/marekaf/gke-php-test