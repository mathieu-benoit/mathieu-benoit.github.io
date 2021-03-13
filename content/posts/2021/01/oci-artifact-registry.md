---
title: host helm charts in google artifact registry
date: 2021-01-14
tags: [containers, helm]
description: let's see how we could host our own helm charts (and more generically, any oci artifacts) in google artifact registry
aliases:
    - /oci-artifact-registry/
---
[Google Artifact Registry](https://cloud.google.com/blog/products/devops-sre/artifact-registry-is-ga) is great to securely store and manage container images but we could do more with [its supported formats](https://cloud.google.com/artifact-registry/docs/supported-formats). One of the use case could be to store your own Helm charts that you could reuse and share privately in your company, accross different projects, etc.

Let's see in actions how we could [store our own Helm chart in Google Artifact Registry](https://cloud.google.com/artifact-registry/docs/helm)!
```
region=us-east4
project=FIXME
repository=helm
chart=hello-world

# If you don't have your own Helm chart yet, you could create it like this:
helm create $chart
cd $chart
export HELM_EXPERIMENTAL_OCI=1

# Save it in the local registry cache:
helm chart save . $region-docker.pkg.dev/$project/$repository/$chart:v1
helm chart list

# Login to Google Artifact Registry with your user account:
gcloud auth print-access-token | helm registry login -u oauth2accesstoken --password-stdin https://$region-docker.pkg.dev
# Alternatively if you are using a service account, you could use the access token file like this:
cat key.json | helm registry login -u _json_key -password-stdin $region-docker.pkg.dev
# If using a base64 encoded key, use _json_key_base64 instead of _json_key.

# Push the chart there:
helm chart push $region-docker.pkg.dev/$project/$repository/$chart:v1

# Verify the chart is there:
gcloud artifacts docker images list $region-docker.pkg.dev/$project/$repository/$chart
gcloud artifacts docker images describe $region-docker.pkg.dev/$project/$repository/$chart:v1

# Pull the chart back:
helm chart remove $region-docker.pkg.dev/$project/$repository/$chart:v1
helm chart pull $region-docker.pkg.dev/$project/$repository/$chart:v1
helm chart export mycontainerregistry.azurecr.io/helm/hello-world:v1 \
  --destination ./install

# From there you could deploy this chart via `helm upgrade|install`...
```

Wonderful! Isn't it!? But that's not all...

Now let's push any file as an [Open Container Initiative (OCI)](https://opencontainers.org/) Artifact. For this we need a generic client able to push an OCI format compliant file to the registry, here comes [OCI Registry As Storage (ORAS)](https://github.com/deislabs/oras).

Let's see it in actions by pushing a simple `.txt` file (I'm using `oras` CLI via its public container image but you could find more options to install it [here](https://github.com/deislabs/oras#cli-installation)):
```
repository=files

# Let's have a file
echo "Here is an artifact!" > artifact.txt

# And push it in Google Artifact Registry:
docker run -i --rm -v $(pwd):/workspace orasbot/oras push \
    $region-docker.pkg.dev/$project/$repository/sample-txt:v1 \
    ./artifact.txt \
    -u oauth2accesstoken \
    -p $(gcloud auth print-access-token)

# Verify the chart is there:
gcloud artifacts docker images list $region-docker.pkg.dev/$project/$repository/sample-txt
gcloud artifacts docker images describe $region-docker.pkg.dev/$project/$repository/sample-txt:v1

# Pull the file back:
rm artifact.txt
docker run -i --rm -v $(pwd):/workspace orasbot/oras pull \
    $region-docker.pkg.dev/$project/$repository/sample-txt:v1 \
    -u oauth2accesstoken \
    -p $(gcloud auth print-access-token)
cat artifact.txt 
```

You could ask _why are we doing this?_ Good question, one of the use case in the cloud native ecosystem could be to store and share your [`OPA`]({{< ref "/posts/2021/01/container-linter.md" >}})'s rego files:
```
repository=regos

# Let's have a rego file:
curl https://raw.githubusercontent.com/mathieu-benoit/mygkecluster/master/policy/container-policies.rego -o ./container-policies.rego

# And push it in Google Artifact Registry:
docker run -i --rm -v $(pwd):/workspace orasbot/oras push \
    $region-docker.pkg.dev/$project/$repository/container-policies:v1 \
    ./container-policies.rego \
    -u oauth2accesstoken \
    -p $(gcloud auth print-access-token)

# Verify the chart is there:
gcloud artifacts docker images list $region-docker.pkg.dev/$project/$repository/container-policies
gcloud artifacts docker images describe $region-docker.pkg.dev/$project/$repository/container-policies:v1

# Pull the file back:
rm container-policies.rego
docker run -i --rm -v $(pwd):/workspace orasbot/oras pull \
    $region-docker.pkg.dev/$project/$repository/container-policies:v1 \
    -u oauth2accesstoken \
    -p $(gcloud auth print-access-token)
cat container-policies.rego
```

And that's it! That's how easily you could securely store and share your OPA's rego files accross your company, teams and projects! ;)

Notes:
- There is still an opened question about the future of the `ORAS` project and [how is it really maintained](https://github.com/deislabs/oras/issues/207)
- [OCI support with `Helm` is still in experimental mode](https://helm.sh/docs/topics/registries/#enabling-oci-support)

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