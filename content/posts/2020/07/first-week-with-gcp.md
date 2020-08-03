---
title: my first week with gcp
date: 2020-07-24
tags: [gcp, containers, devops, kubernetes]
description: let's share what I learned during my first week leveraging gcp, tools and services like linux on my pixelbook, gcloud cli, docker, git, service account, gcr, cloud run, app engine and kubernetes engine
aliases:
    - /first-week-with-gcp/
---
[![](https://media-exp1.licdn.com/dms/image/C4E16AQHxLntx_KDIlA/profile-displaybackgroundimage-shrink_350_1400/0?e=1600905600&v=beta&t=n9sWYjd0vqL108qKfABjKX_5WDERMlE43wYS-tGbFr0)](https://media-exp1.licdn.com/dms/image/C4E16AQHxLntx_KDIlA/profile-displaybackgroundimage-shrink_350_1400/0?e=1600905600&v=beta&t=n9sWYjd0vqL108qKfABjKX_5WDERMlE43wYS-tGbFr0)

This blog article is my first one related to GCP (Google Cloud Platform). [I just started as Cloud Customer Engineer at Google](https://www.linkedin.com/posts/mathieubenoitqc_cloud-innovation-continuouslearning-activity-6685996290330947584-bKkB) this week. So here are some learnings I would like to write down and share.

The onboarding process is really inspiring and well structured, driven by the collaboration and a learning experience led by practicing. Among different trainings and tools received, I got a great experience with G Suite and my Pixelbook, that's concretely my very first time with them. Really impressive productivity! 

> Simplicity, Security.

One setup on my Pixelbook I have done, is enabling the Linux feature on it. And from there, I was able to install tools I need locally: Docker, Kubernetes, Terraform, Slack, VS Code with the Cloud Code extension, etc.
You could find more details about this setup with this blog article: [Build a dev workflow with Cloud Code on a Pixelbook](https://cloud.google.com/blog/products/application-development/build-a-dev-workflow-with-cloud-code-on-a-pixelbook).

Among different internal trainings I'm having related to my role, I also took the opportunity to learn more about GCP (for the very first time too), by practicing. I indeed needed to run few CLI commands! ;)

To accomplish this I took the [Google Cloud Essentials course on Qwiklabs](https://google.qwiklabs.com/quests/23):
- [Compute Engine](https://cloud.google.com/compute/docs): Linux and Windows
    - Impressive to see how fast it is to provision a VM!
- [Cloud Shell](https://cloud.google.com/shell/docs)
    - Love the very productive `gcloud beta interactive` command!
- [Kubernetes Engine](https://cloud.google.com/kubernetes-engine/docs)
    - Interestingly, one GKE cluster comes with [Node auto-repair](https://cloud.google.com/kubernetes-engine/docs/how-to/node-auto-repair) and [Node auto-upgrade](https://cloud.google.com/kubernetes-engine/docs/how-to/node-auto-upgrades) by default.
- [Load Balancers](https://cloud.google.com/load-balancing/docs)
    - [This doc](https://cloud.google.com/load-balancing/docs/load-balancing-overview#a_closer_look_at_cloud_load_balancers) is a great resource to see your different options about Load Balancer on GCP.

The experience with [Qwiklabs](https://google.qwiklabs.com) is awesome! I got step-by-step labs allowing me to do hands-on via the Google Cloud Console and via the Google Cloud Shell. Furthermore, the last exercise is a challenge, not step-by-step guided, making sure I'm able to do it by myself!

Here are few general resources I have captured to keep as references:
- [Google Cloud Next OnAir 2020](https://cloud.withgoogle.com/next)
    - Here is very detailed description of this event: [The Google Cloud Next OnAir Cheat Sheet](https://gregsramblings.com/blog/google-cloud-next-onair-cheat-sheet/)
- [GCP Blog](https://cloud.google.com/blog/)
- [GCP Docs](https://cloud.google.com/docs)
- [GCP Pricing](https://cloud.google.com/pricing)
- [GCP Certifications](https://cloud.google.com/certification)
- [GCP Locations](https://cloud.google.com/about/locations)
- [Regions and Zones](https://cloud.google.com/compute/docs/regions-zones)
- [GCP CLI](https://cloud.google.com/sdk/gcloud)
    - [Here is the `gcloud` CLI cheat-sheet](https://cloud.google.com/sdk/docs/cheatsheet)

Well, that's really cool, but now let's take one of [my containerized app: `myblog`]({{< ref "/posts/2020/05/myblog.md" >}}) and delpoy it on GCP! For that we will leverage 4 services in GCP:
- [Google Container Registry](https://cloud.google.com/container-registry)
- [Google Cloud Run](https://cloud.google.com/run), yep [Cloud Run could run website too](https://medium.com/google-cloud/can-cloud-run-handle-these-9-workloads-serverless-toolbox-afddeab87819)! ;)
- [Google Cloud App Engine](https://cloud.google.com/appengine)
- [Google Kubernetes Engine](https://cloud.google.com/kubernetes-engine)

I'm running all the commands below since I have installed locally, like explained above, the `gcloud`, `Docker` and `kubectl` CLIs. But you could also do this from within the Google Cloud Shell which has already the three of them installed too (yep, with a Docker daemon too to succesfully run all your `docker` commands ;)).

```
# Clone the Git repo locally
git clone https://github.com/mathieu-benoit/myblog
git submodule init
git submodule update
cd myblog

# Setup the Project
gcloud init
gcloud config list
gcloud auth list
projectId=FIXME
projectName=FIXME
folderId=FIXME
gcloud projects create $projectId \
    --folder $folderId \
    --name $projectName
gcloud config set project $projectId
gcloud beta billing accounts list
billingAccountId=FIXME
gcloud beta billing projects link $projectId \
    --billing-account $billingAccountId

# Build and Push the Container in GCR
gcloud services enable containerregistry.googleapis.com
saName=docker-push
gcloud iam service-accounts create $saName \
    --display-name $saName
saFullName=$saName@$projectId.iam.gserviceaccount.com
gcloud projects add-iam-policy-binding $projectId \
    --member serviceAccount:$saFullName \
    --role roles/storage.admin
gcloud iam service-accounts keys create ~/key.json \
    --iam-account $saFullName
gcloud auth activate-service-account $saFullName \
    --key-file ~/key.json
gcloud auth configure-docker
docker build -t gcr.io/$projectId/myblog:1 .
docker push gcr.io/$projectId/myblog:1
```

From here, we could now deploy this container from GCR to any services capable of hosting a container and which has access to pull the image. By default, any GCP service in the GCR's Project, has the proper access to do this. Now let's deploy this container image in three different services: Cloud Run, App Engine and Kubernetes Engine.

```
# Deploy this container on Cloud Run (< 1min)
gcloud services enable run.googleapis.com
gcloud run deploy myblog \
    --image gcr.io/$projectId/myblog \
    --region us-east1 \
    --platform managed \
    --allow-unauthenticated

# Deploy this container on Google App Engine (~ 5min)
gcloud services enable appengineflex.googleapis.com
echo "runtime: custom" >> app.yaml
echo "env: flex" >> app.yaml
gcloud app deploy \
    --image-url gcr.io/$projectId/myblog:1

# Deploy this container on GKE (~ 5min)
gcloud services enable container.googleapis.com
clusterName=mygkecluster
gcloud container clusters create $clusterName \
    --zone us-east1-b
gcloud container clusters get-credentials $clusterName
kubectl run myblog \
    --image=gcr.io/$projectId/myblog:1 \
    --generator=run-pod/v1
kubectl expose pod myblog \
    --type=LoadBalancer \
    --port=8080 \
    --target-port=8080
```

What a first week, really exciting! More learnings and blog articles related to GCP to come for sure! Stay tuned, cheers! ;)