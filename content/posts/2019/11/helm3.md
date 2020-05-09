---
title: helm 3 is out
date: 2019-11-20
tags: [containers, kubernetes, helm]
description: let's go through the latest and greatest of helm 3
aliases:
    - /helm3/
---
[![](https://github.com/cncf/artwork/raw/master/projects/helm/horizontal/color/helm-horizontal-color.png)](https://github.com/cncf/artwork/raw/master/projects/helm/horizontal/color/helm-horizontal-color.png)

Recent and official announcements here: [Helm 3.0.0 has been released!](https://helm.sh/blog/helm-3-released/), here: [Helm 3: Simpler and more secure](https://cloudblogs.microsoft.com/opensource/2019/11/13/helm-3-available-simpler-more-secure/) or here: [Helm Reaches Version 3](https://www.cncf.io/announcement/2019/11/13/helm-reaches-version-3/).

Yep, Tiller is gone, but that's not just that! Here is an exhaustive [list of all the major changes from Helm 2 to Helm 3](https://v3.helm.sh/docs/faq/#changes-since-helm-2).

Let's go through our first _Hello, World!_ scenario with Helm 3.

First you need to [install Helm 3](https://helm.sh/docs/intro/install/). In my case I will leverage throughout this blog article the [Azure Cloud Shell](https://azure.microsoft.com/features/cloud-shell/). But as we speak, it just has Helm version 2.15.2, so here is my custom script to install my own Helm 3 version:
```
helmFile='helm-v3.0.0-linux-amd64.tar.gz'
curl https://get.helm.sh/$helmFile --output $helmFile
tar -xvf $helmFile
mkdir ~/tools
mv linux-amd64/helm ~/tools/helm3
rm $helmFile
rm -r linux-amd64
echo 'export PATH=$PATH:~/tools' >> ~/.bashrc && source ~/.bashrc
helm3 version
```

From here I have both helm and helm3 commands to keep/use both in parallel for now. So I will use `helm3` command from here.

Then let's create our first Helm chart:
```
chart=hello-world  
helm3 create $chart
ls ./$chart
# Should return: charts  Chart.yaml  templates values.yaml
ls ./$chart/templates
# Should return: deployment.yaml  helpers.tpl  ingress.yaml  NOTES.txt  serviceaccount.yaml  service.yaml
helm3 lint ./$chart
```

Now let's deploy this chart in a Kubernetes cluster (so you need one somewhere locally, on Azure, etc.):
```
ns=hello-world
release=hello-world
kubectl create ns $ns
helm3 upgrade --install -n $ns $release ./$chart
helm3 list -n $ns
helm3 test $release -n $ns
kubectl get all -n $ns
```

Now let's leverage [Azure Container Registry (ACR)](https://azure.microsoft.com/services/container-registry) as an [Helm chart repository](https://docs.microsoft.com/azure/container-registry/container-registry-helm-repos):  
```
acr=<your-acr-name>
acrLogin=<your-acr-login>
acrPassword=<your-acr-password>

# First, let's package and push our Helm chart
helm3 package ./$chart
az acr helm push -n $acr -u $acrLogin -p $acrPassword $(ls $chart-*.tgz)
az acr helm list -n $acr -u $acrLogin -p $acrPassword -o table
az acr helm show $chart -n $acr

# Second, let's pull and deploy our Helm chart
helm3 repo add $acr https://$acr.azurecr.io/helm/v1/repo --username $acrLogin --password $acrPassword
helm3 upgrade --install -n $ns $release $acr/$chart
helm3 list -n $ns
kubectl get all -n $ns
```

Another approach could be to use instead the new [OCI Artifact support by Helm 3](https://helm.sh/docs/topics/registries) by still leveraging ACR:
```
export HELM_EXPERIMENTAL_OCI=1

# First, let's package and push our Helm chart
helm3 chart save ./$chart $acr.azurecr.io/charts/$chart:v1
helm3 chart list

echo $acrPassword | helm registry login $acr.azurecr.io -u $acrLogin --password-stdin

helm chart push $acr.azurecr.io/charts/$chart:v1
az acr repository show-tags -n $acr --repository charts/$chart
az acr repository show-manifests -n $acr --repository charts/$chart --detail

# Second, let's pull and deploy our Helm chart

helm3 chart remove $acr.azurecr.io/charts/$chart:v1
helm3 chart pull $acr.azurecr.io/charts/$chart:v1
rm -rf $chart
helm3 chart export $acr.azurecr.io/charts/$chart:v1
ls $chart

helm3 upgrade --install -n $ns $release ./$chart

helm3 list -n $ns

kubectl get all -n $ns
```

What about if you have existing Helm 2 charts? Actually you could read more about the [Migration tool in place to migrate both configurations and releases from Helm2 to Helm3](https://github.com/helm/helm-2to3). But you could also keep your existing Helm 2 charts as-is and deploy them with the Helm 3 client, let's take an example for the latter option:
```
git clone https://github.com/azure/phippyandfriends
cd parrot/charts/parrot
kubectl create ns parrot
helm3 upgrade \
    --install \
    --set image.repository=mabenoit/parrot \
    --set image.tag=latest \
    --set ingress.enabled=false \
    -n parrot parrot \
    .

helm3 list -n $ns

kubectl get all -n $ns
```

_Note: I took the opportunity to open [PR#35](https://github.com/Azure/phippyandfriends/pull/35) in the associated [azure/phippyandfriends](https://github.com/Azure/phippyandfriends) GitHub repository to leverage the Helm 3 client._

Here we are! We have seen how to install Helm 3 in Azure Cloud Shell, we have created and deployed our first Helm 3 chart, then we pushed it in ACR via 2 different ways and finally we also showed how to continue using Helm 2 charts with the Helm 3 client. Hope you enjoyed this!

Complementary resources I invite you to leverage too:
- [Helm releases](https://github.com/helm/helm/releases)
- [Helm at KubeCon + CloudNativeCon NA 2019](https://helm.sh/blog/2019-11-15-helm-at-cloudnativecon)
    - [An Introduction to Helm - Matt Farina, Samsung SDS & Josh Dolitsky, Blood Orange](https://kccncna19.sched.com/event/UajI) 
    - [Helm 3 Deep Dive - Taylor Thomas, Microsoft Azure & Martin Hickey, IBM](https://kccncna19.sched.com/event/Uagg) 
    - [Managing Helm Deployments with GitOps at CERN - Ricardo Rocha, CERN](https://kccncna19.sched.com/event/UabD) 
- Helm Hub - [https://hub.helm.sh](https://hub.helm.sh)
- [ORAS - OCI Registry As Storage](https://github.com/deislabs/oras)

Happy Helming! Happy Sailing!

Cheers!