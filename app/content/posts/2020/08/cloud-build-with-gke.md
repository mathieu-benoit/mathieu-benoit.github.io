---
title: build and deploy a containerized app on gke with cloud build
date: 2020-08-10
tags: [gcp, security, containers, kubernetes]
description: let's see how to use google cloud build to build and deploy a containerized app on gke
aliases:
    - /cloud-build-with-gke/
---
![Logo of the Google Cloud Build service.](https://cloud.google.com/container-registry/images/builder.png)
Today we will see how to build and deploy a containerized app on GKE by leveraging [Google Cloud Build](https://cloud.google.com/cloud-build/).

We will first setup the [Continuous Integration (CI)]({{< ref "#ci" >}}) part to build and push the containerized app in Google Artifact Registry and then we will setup the [Continuous Delivery (CD)]({{< ref "#cd" >}}) part to eventually deploy this containerized app on GKE.

Here is the setup of the context for the further considerations throughout this blog article. The containerized app here will be my own blog:
```
projectId=FIXME # ID of an existing project
gcloud config set project $projectId
gcloud services enable cloudbuild.googleapis.com
gcloud services enable artifactregistry.googleapis.com
location=us-east4
registryName=containers
gcloud artifacts repositories create $registryName \
    --location $location \
    --repository-format docker
git clone --recurse-submodules https://github.com/mathieu-benoit/myblog
cd myblog
```

_Important remark: when we enable the `cloudbuild.googleapis.com` API on the current project, the associated [Cloud Build Service Account](https://cloud.google.com/cloud-build/docs/securing-builds/configure-access-for-cloud-build-service-account) is created. You could see [here the list of its default roles and permissions](https://cloud.google.com/cloud-build/docs/cloud-build-service-account). For example it has the `artifactregistry.*` roles allowing it to [push container images in Google Artifact Registry](https://cloud.google.com/artifact-registry/docs/access-control#permissions)._

# CI

```
appName=myblog
imageName=$registryHostName/$projectId/$registryName/$appName:7
cat > cloudbuild-ci.yaml <<EOF
steps:
- name: gcr.io/cloud-builders/docker
  args: ['build', '-t', '$imageName', '.']
- name: gcr.io/cloud-builders/docker
  args: ['push', '$imageName']
EOF

gcloud builds submit \
    --config cloudbuild-ci.yaml \
    .

gcloud builds list
gcloud artifacts docker images list $location-docker.pkg.dev/$projectId/$registryName
gcloud artifacts docker tags list $location-docker.pkg.dev/$projectId/$registryName/$appName
```

And that's it, with 2 steps we are able to manually use Google Cloud Build to build and push a containerized app in Google Container Registry. We are using here the built-in `gcr.io/cloud-builders/docker` step wich is a container, you could find [here the list of the other built-in builder images](https://github.com/GoogleCloudPlatform/cloud-builders) or the [community-contributed builders and custom builders](https://cloud.google.com/cloud-build/docs/configuring-builds/use-community-and-custom-builders) or even the [Docker Hub images](https://cloud.google.com/cloud-build/docs/interacting-with-dockerhub-images). In addition to this, you may want to [substitute variable values](https://cloud.google.com/cloud-build/docs/configuring-builds/substitute-variable-values) in your build config.

To be able to properly setup a Continuous Integration setup you will need to define the appropriate trigger with Google Cloud Build, in my case it will be a [GitHub App trigger](https://cloud.google.com/cloud-build/docs/automating-builds/create-github-app-triggers):
```
gcloud beta builds triggers create github \
    --repo-name=$appName \
    --repo-owner=mathieu-benoit \
    --branch-pattern="master" \
    --build-config=cloudbuild-ci.yaml
```

Another feature you may want to leverage with your container registry is [Container Analysis](https://cloud.google.com/artifact-registry/docs/analysis)
```
gcloud services enable containeranalysis.googleapis.com
gcloud services enable containerscanning.googleapis.com
```
From there, the vulnerabilities scans will be in place as soon as you will push an image in the container registry. See the associated pricing page for this feature [here](https://cloud.google.com/artifact-registry/pricing). You could check the result of the scan by re-running this command `gcloud artifacts docker images list $location-docker.pkg.dev/$projectId/$registryName --show-occurrences` and look at the value of the `VULNERABILITIES` column.

I love the fact that the [build config definition is very light and easy to understand](https://cloud.google.com/cloud-build/docs/build-config), for example no extra fields to define a step or to do conditions, dependencies with other build configs, etc. You may have other experiences with other CI/CD tools with Azure DevOps and feel like me that this could be a limitation. But at the end of the day, isn't it better to have few features instead of a ton of them with multiple ways to accomplish what you are trying to do? Here, I haven't felt yet to be lost or that I was looking for what is the best way to do something, it seems pretty straight forward and powerful enough. For example, how to add conditions on a Git branch or other variables or context? Actually, you could either have different build config definitions (YAML or JSON files), different triggers based on the Git branch or you could also have more control with bash scripts at any step to be more flexible.

# CD

Now let's deploy this containerized app on an existing GKE cluster in the same project after granting the `roles/container.developer` role to the Cloud Build Service Account:
```
gkeName=FIXME
gkeZone=FIXME

projectNumber="$(gcloud projects describe $projectId --format='get(projectNumber)')"
gcloud projects add-iam-policy-binding $projectNumber \
    --member=serviceAccount:$projectNumber@cloudbuild.gserviceaccount.com \
    --role=roles/container.developer

sed -i "s,CONTAINER_IMAGE_NAME,$imageName," k8s/deployment.yaml

cat > cloudbuild-cd.yaml <<EOF
steps:
- name: 'gcr.io/cloud-builders/kubectl'
  args: ['apply', '-f', 'k8s/', '-n', '$appName']
  env:
  - 'CLOUDSDK_COMPUTE_ZONE=$gkeZone'
  - 'CLOUDSDK_CONTAINER_CLUSTER=$gkeName'
EOF

gcloud builds submit \
    --config cloudbuild-cd.yaml \
    .

gcloud builds list
gcloud container clusters get-credentials --project=$projectId --zone=$zoneName $gkeName
kubectl get all -n $appName
```

And that's it, just 1 step and our container image is deployed in GKE by leveraging our Kubernetes manifests! Because we provide both `CLOUDSDK_COMPUTE_ZONE` and `CLOUDSDK_CONTAINER_CLUSTER` environment variables, the `gcr.io/cloud-builders/kubectl` step is doing a `gcloud container clusters get-credentials` behind the scene for us before running the actual `kubectl` command. Anyway you could use this step/command for any Kubernetes cluster anywhere, but here there is a seamless and secure way to retrieve the GKE's kubeconfig.

The GKE cluster is able to pull images from Artifact Registry because they are on the same Project, you could get more information [here](https://cloud.google.com/artifact-registry/docs/integrate-gke).

For information, if you have a [Private GKE cluster](https://cloud.google.com/kubernetes-engine/docs/concepts/private-cluster-concept) and an [Artifact Registry with Service Perimeter](https://cloud.google.com/artifact-registry/docs/securing-with-vpc-sc), Cloud Build doesn't support VPC Service Control but [there is an alternative by creating an access level](https://cloud.google.com/vpc-service-controls/docs/supported-products#build).

_Extra goodies here, you could get a Cloud Build's status badge by leveraging this `badger` project: [kelseyhightower/badger](https://github.com/kelseyhightower/badger)._

# Final thoughts

You could find my final [`cloudbuild.yaml` file in GitHub](https://github.com/mathieu-benoit/myblog/blob/master/cloudbuild.yaml) leveraging what we have been discussing throughout this blog article and combining both the CI part as well as the CD part. Yes, I'm having just one build config file for my blog and as soon as the container image is pushed to GCR, it will be then deployed in GKE, without any pause, approval, etc. But again, you could achieve those with different build config files or also having different strategies in place regarding Git branches and pull requests to manage different environments. You could also setup a [GitOps approach](https://www.weave.works/blog/what-is-gitops-really) to manage the CD part within your GKE cluster and not having this second part handled by Cloud Build.

To conclude, that's for sure you could use your tools of choice for CI/CD like Azure DevOps, Jenkins, Spinnaker, etc. to interact with GCP via the `gcloud` SDK/CLI. Based on my experience with Azure DevOps, I feel that Cloud Build is lighter and very easy to use and simplify the experience and the maintenance of the build config files. And to be honest, I really think that the ["Keep It Simple, Stupid" principle](https://en.wikipedia.org/wiki/KISS_principle) is key here. Furthermore, the integration of Cloud Build in GCP is helping for a seamless and secure integration with other GCP services.

Complementary and further resources:
- [CI/CD on Google Cloud](https://cloud.google.com/docs/ci-cd)
- [Cloud Build Pricing](https://cloud.google.com/cloud-build/pricing)
- [Container Registry Pricing](https://cloud.google.com/container-registry/pricing)
- [GKE Pricing](https://cloud.google.com/kubernetes-engine/pricing)
- [CodeLabs - Achieve continuous deployment to Google Kubernetes Engine (GKE) with Cloud Build](https://codelabs.developers.google.com/codelabs/cloud-builder-gke-continuous-deploy/index.html)
- [Using Kaniko cache](https://cloud.google.com/cloud-build/docs/kaniko-cache)
- [Securing Your GKE Deployments with Binary Authorization](https://codelabs.developers.google.com/codelabs/cloud-binauthz-intro/)
- [GitHub Actions self-hosted runners on Google Cloud](https://github.blog/2020-08-04-github-actions-self-hosted-runners-on-google-cloud/)

Hope you enjoyed this blog article, happy CI/CD and sailing with Cloud Build and GKE! ;)
