![CloudBuild](https://badger-dydtquwp2q-ue.a.run.app/build/status?project=mabenoit-myblog&id=2d99471b-c068-4452-a670-9763a89c6e8e)

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
kubectl create ns myblog
kubectl config set-context --current --namespace myblog

# Simple way with just a deployment and service:
imageName=FIXME
sed -i "s,CONTAINER_IMAGE_NAME,$imageName," k8s/deployment.yaml
kubectl apply -f k8s/deployment.yaml
sed -i "s,NodePort,LoadBalancer," k8s/service.yaml
kubectl apply -f k8s/service.yaml

# Complete way:
kubectl apply -f k8s/
```

## Prepare your own base images in your own GCR

```
gcrProjectId=FIXME

alpineVersion=FIXME
docker pull alpine:$alpineVersion
docker tag alpine:$alpineVersion gcr.io/$gcrProjectId/alpine:$alpineVersion
docker push gcr.io/$gcrProjectId/alpine:$alpineVersion

nginxVersion=FIXME
docker pull nginxinc/nginx-unprivileged:$nginxVersion
docker tag nginxinc/nginx-unprivileged:$nginxVersion gcr.io/$gcrProjectId/nginx-unprivileged:$nginxVersion
docker push gcr.io/$gcrProjectId/nginx-unprivileged:$nginxVersion

docker build -t blog \
    --build-arg ALPINE_BASE_IMAGE=gcr.io/$gcrProjectId/alpine \
    --build-arg ALPINE_VERSION=$alpineVersion \
    --build-arg NGINX_BASE_IMAGE=gcr.io/$gcrProjectId/nginx-unprivileged \
    --build-arg NGINX_VERSION=$nginxVersion \
    .
```

## Setup the Cloud Build trigger

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

# Least privilege for the cloud build's sa
cloudBuildSa=$projectNumber@cloudbuild.gserviceaccount.com
gcloud projects remove-iam-policy-binding $projectId \
    --member serviceAccount:$cloudBuildSa \
    --role roles/cloudbuild.builds.builder
roles="roles/cloudbuild.builds.editor roles/storage.objectAdmin roles/logging.logWriter roles/source.reader roles/pubsub.editor"
for r in $roles; do gcloud projects add-iam-policy-binding $projectId --member "serviceAccount:$cloudBuildSa" --role $r; done

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

# Manually install the Cloud Build app on GitHub:
# https://cloud.google.com/cloud-build/docs/automating-builds/create-github-app-triggers#installing_the_cloud_build_app

gkeClusterName=FIXME
gcloud beta builds triggers create github \
    --name=myblog-master \
    --repo-name=myblog \
    --repo-owner=mathieu-benoit \
    --branch-pattern="master" \
    --build-config=cloudbuild.yaml \
    --substitutions=_CLOUDSDK_CONTAINER_CLUSTER=$gkeClusterName,_CLOUDSDK_CORE_PROJECT=$gkeProjectId

# Finally, we need to create a static external IP address to be able to generate a managed certificates later
gcloud config set project $gkeProjectId
staticIpName=myblog
gcloud compute addresses create $staticIpName \
    --global
staticIpAddress=$(gcloud compute addresses describe $staticIpName \
    --global \
    --format "value(address)")
```
