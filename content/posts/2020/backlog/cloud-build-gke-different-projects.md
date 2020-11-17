---
title: setup of cloud build and gke in different projects
date: 2020-10-18
tags: [gcp, kubernetes, security]
description: fixme
draft: true
aliases:
    - /cloud-build-gke-different-projects/
---
+ diagram

Since my first setup of [`myblog`](https://github.com/mathieu-benoit/myblog) and [`mygkecluster`](https://github.com/mathieu-benoit/mygkecluster) I now need to split the resources from each other. The typical scenario is I would like to have one project per application I'm deploying in my GKE cluster. With that in place I have more control over the cost, the security and the governance at the project level for each app. The GKE cluster and its project are seen here as shared resources. The above diagram illustrates this scenario.

Here is the minimal setup for the GKE's project:
```
gkeProjectId=FIXME
gcloud config set project $gkeProjectId

## GKE setup
gcloud services enable container.googleapis.com
zone=us-east1-b
gcloud container clusters create $clusterName \
    --zone $zone

## Container registry setup
region=us-east1
gcloud services enable artifactregistry.googleapis.com
containerRegistryName=containers
gcloud artifacts repositories create $containerRegistryName \
    --location $region \
    --repository-format docker
gcloud artifacts repositories add-iam-policy-binding $containerRegistryName \
    --location $region \
    --member "serviceAccount:$gkeSaId" \
    --role roles/artifactregistry.reader
```

So here we are, we have a shared GKE and GCR services for the different projects to push their containers into. Now we need to create the Cloud Build setup for a sepcific apps, myblog in this case, here are the associated command lines to accomplish that:
FIXME - take a previous article as a reference and first setup
```
# Configuration to be able to push images to GCR in another project
gcrProjectId=FIXME
gcloud projects add-iam-policy-binding $gcrProjectId \
    --member serviceAccount:$cloudBuildSa \
    --role roles/storage.admin
gsutil iam ch serviceAccount:$cloudBuildSa:objectAdmin gs://artifacts.$gcrProjectId.appspot.com

# Configuration to be able to deploy a container to GKE in another project
gcloud services enable container.googleapis.com
gcloud iam service-accounts delete $projectNumber-compute@developer.gserviceaccount.com --quiet
gkeProjectId=FIXME
gcloud projects add-iam-policy-binding $gkeProjectId \
    --member=serviceAccount:$cloudBuildSa \
    --role=roles/container.developer

# In the case of my app myblog, I need to provision a static external IP address to be able to leverage ManagedCertificate. In this case, I need to provision this IP address in the GKE's project
gcloud config set project $gkeProjectId
staticIpName=myblog
gcloud compute addresses create $staticIpName \
    --global
staticIpAddress=$(gcloud compute addresses describe $staticIpName \
    --global \
    --format "value(address)")
```

Complementary to this, we would like improve our security posture here, more specifically by respecting the least privilege principle with the different service account involved here:

For the GKE's project, we just need to follow what I have already documented here (FIXME)

For the apps' project, FIXME
```
cloudBuildSa=$projectNumber@cloudbuild.gserviceaccount.com
gcloud projects remove-iam-policy-binding $projectId \
    --member serviceAccount:$cloudBuildSa \
    --role roles/cloudbuild.builds.builder
roles="roles/cloudbuild.builds.editor roles/storage.objectAdmin roles/logging.logWriter roles/source.reader roles/pubsub.editor"
for r in $roles; do gcloud projects add-iam-policy-binding $projectId --member "serviceAccount:$cloudBuildSa" --role $r; done
```
So typically, by doing this, we just get rid off these permissions: `storage.buckets.create|get|list`, `artifactregistry.*`, and `containeranalysis.occurrences.*` which are not necessary in my context.

That's a wrap! So we just saw how to properly setup Cloud Build able to push containers in Artifact Registry as well as deploying them in GKE by being in a different GCP project than the one actually hosting GAR and GKE. You could now repeat this scenario for any apps deployed in a shared GKE cluster. Furthermore, you could leverage this to manage different environments (DEV, QA, PROD) by having their respective GCP projects for example.

Hope you enjoyed that one, cheers!

https://cloud.google.com/cloud-build/docs/cloud-build-service-account
https://cloud.google.com/iam/docs/understanding-roles