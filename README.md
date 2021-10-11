## Build the container

```
git clone --recurse-submodules https://github.com/mathieu-benoit/myblog
docker build -t blog .
```

## Run locally

```
docker run -d -p 8080:8080 blog
```

## Deploy on Kubernetes

```
imageNameInRegistry=myblog
kubectl create ns myblog
kubectl config set-context --current --namespace myblog
kubectl create deployment myblog --image=$imageNameInRegistry --port=8080
kubectl expose deployment myblog --port=8080 --target-port=8080
```

## Setup Cloud Build

```
projectName=myblog
randomSuffix=$(shuf -i 100-999 -n 1)
projectId=$projectName-$randomSuffix
folderId=FIXME

gcloud projects create $projectId \
    --folder $folderId \
    --name $projectName
projectNumber="$(gcloud projects describe $projectId --format='get(projectNumber)')"

gcloud config set project $projectId

gcloud beta billing accounts list
billingAccountId=FIXME
gcloud beta billing projects link $projectId \
    --billing-account $billingAccountId

gcloud services enable cloudbuild.googleapis.com
cloudBuildSa=$projectNumber@cloudbuild.gserviceaccount.com

# Configuration to be able to push images to ArtifactRegistry in another project
gcloud artifacts repositories add-iam-policy-binding $containerRegistryRepository \
    --project=$containerRegistryProjectId \
    --location=$containerRegistryLocation \
    --member=serviceAccount:$cloudBuildSa \
    --role=roles/artifactregistry.writer

# On-demand scanning
gcloud services enable ondemandscanning.googleapis.com
gcloud projects add-iam-policy-binding $projectId \
    --member=serviceAccount:$cloudBuildSa \
    --role=roles/ondemandscanning.admin

# Manually install the Cloud Build app on GitHub:
# https://cloud.google.com/cloud-build/docs/automating-builds/create-github-app-triggers#installing_the_cloud_build_app

gcloud beta builds triggers create github \
    --name=myblog-main \
    --repo-name=myblog \
    --repo-owner=mathieu-benoit \
    --branch-pattern="main" \
    --build-config=cloudbuild.yaml \
    --ignore-files="README.md,.github/**,gcloud/**" \
    --substitutions=_CONTAINER_REGISTRY_NAME=$containerRegistryName

# We need to create a static external IP address to be able to generate a managed certificates later
gcloud config set project $gkeProjectId
staticIpName=myblog
gcloud compute addresses create $staticIpName \
    --global
staticIpAddress=$(gcloud compute addresses describe $staticIpName \
    --global \
    --format "value(address)")

# We also need to define an SSL policy
gcloud compute ssl-policies create myblog \
    --profile COMPATIBLE  \
    --min-tls-version 1.0
```

## Setup Cloud Monitoring

```
gcloud monitoring dashboards create --config-from-file=gcloud/monitoring/dashboard.yaml
```