---
title: host helm charts and oci artifacts in google artifact registry
date: 2021-01-14
tags: [containers, helm]
description: let's see how we could host our own helm charts (and more generically, any oci artifacts) in google artifact registry
aliases:
    - /oci-artifact-registry/
    - /oci-artifacts/
---
_Updated on August 2nd, 2022 with the official support of OCI format for Helm since 3.8.0, not experimental anymore._

[Google Artifact Registry](https://cloud.google.com/blog/products/devops-sre/artifact-registry-is-ga) is great to securely store and manage container images but we could do more with [its supported formats](https://cloud.google.com/artifact-registry/docs/supported-formats). One of the use case could be to store your own Helm charts, or more generically any OCI artifacts, that you could reuse and share privately in your company, accross different projects, etc.

In this blog article we'll see 2 options to store and interact with your OCI artifacts and Artifact Registry:
- [Helm CLI]({{< ref "#helm-cli" >}})
- [Oras CLI]({{< ref "#oras-cli" >}})

## Helm CLI

Let's see in actions how we could [store our own Helm chart in Google Artifact Registry](https://cloud.google.com/artifact-registry/docs/helm)!
```
# Info of your existing Artifact Registry
region=us-east4
project=FIXME

# Create a repository dedicated to your helm charts in Artifact Registry
repository=charts
gcloud artifacts repositories create $repository \
    --project $project \
    --location $region \
    --repository-format docker

# If you don't have your own Helm chart yet, you could create it like this:
chart=hello-world
helm create $chart

# Package the Helm chart:
helm package $chart --version 0.1.0

# For authentication, we'll use Artifact Registry credentials configured for Docker
gcloud auth configure-docker $region-docker.pkg.dev
# Other options are documented here: https://cloud.google.com/artifact-registry/docs/helm/authentication

# Push the chart in Artifact Registry:
helm push $chart-0.1.0.tgz oci://$region-docker.pkg.dev/$project/$repository

# Verify the chart is there:
gcloud artifacts docker images list $region-docker.pkg.dev/$project/$repository/$chart
gcloud artifacts files list \
    --project $project \
    --location $region \
    --repository $repository

# Pull the chart back:
mkdir tmp
helm pull oci://$region-docker.pkg.dev/$project/$repository/$chart \
    -d tmp
# You could add the --untar parameter too    
ls tmp

# Not part of this article, but from here you could also deploy this chart in your Kubernetes clusters via `helm upgrade|install`...
```

Wonderful! Isn't it!? But that's not all...

## Oras CLI

Now let's push any file as an [Open Container Initiative (OCI)](https://opencontainers.org/) Artifact. For this we need a generic client able to push an OCI format compliant file to the registry, here comes [OCI Registry As Storage (ORAS)](https://oras.land/).

Let's see it in actions by pushing a simple `.txt` file (you need to install the `oras` CLI, you could find the options to install it [here](https://oras.land/cli/)):
```
# Create a dedicated repository
repository=files
gcloud artifacts repositories create $repository \
    --project $project \
    --location $region \
    --repository-format docker

# Let's have a file
echo "Here is a file!" > first-file.txt

# For authentication, we'll use Artifact Registry credentials configured for Docker
gcloud auth configure-docker $region-docker.pkg.dev

# Push the file in Artifact Registry:
oras push \
    $region-docker.pkg.dev/$project/$repository/my-artifact:v1 \
    first-file.txt

# Verify the chart is there:
gcloud artifacts docker images list $region-docker.pkg.dev/$project/$repository/my-artifact
gcloud artifacts files list \
    --project $project \
    --location $region \
    --repository $repository

# Pull the file back:
rm first-file.txt
oras pull \
    $region-docker.pkg.dev/$project/$repository/my-artifact:v1
cat first-file.txt

# Let's add more files in this artifact
echo "Here is a second file!" > second-file.txt
mkdir subfolder
echo "Here is a third file!" > subfolder/third-file.txt
oras push \
    $region-docker.pkg.dev/$project/$repository/my-artifact:v2 \
    first-file.txt second-file.txt subfolder/
```

And that's it! That's how easily you could securely store and share any files in an OCI format across your company, teams and projects! ;)

Complementary and further resources:
- [Managing your containers with Google Artifact Registry](https://cloud.google.com/artifact-registry/docs/docker)
- [Use Google Artifact Registry with Cloud Build and GKE]({{< ref "/posts/2020/08/cloud-build-with-gke.md" >}})
- [OCI Artifacts, Push it all to the registry!](https://jzelinskie.com/posts/oci-artifacts/)
- [Sharing Is Caring! Push Your Cloud Application to an OCI Registry](https://youtu.be/MIAJaAr3gCk?list=PLj6h78yzYM2O1wlsM-Ma-RYhfT5LKq0XC)
- [Managing Cloud Native Artifacts for Large Scale Kubernetes Cluster](https://youtu.be/BNQHowtj2dY?list=PLj6h78yzYM2Pn8RxfLh2qrXBDftr6Qjut)
- [Push and pull Helm charts to ACR](https://docs.microsoft.com/azure/container-registry/container-registry-helm-repos)
- [Push and pull an OCI artifact using ACR](https://docs.microsoft.com/azure/container-registry/container-registry-oci-artifacts)
- [Pushing an Helm chart to ECR](https://docs.aws.amazon.com/AmazonECR/latest/userguide/push-oci-artifact.html)

Hope you enjoyed that one, cheers!