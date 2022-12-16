---
title: binary authorization on gke
date: 2020-11-13
tags: [gcp, containers, kubernetes, security]
description: let's see how you can only run what you trust (tl;dr whitelisted registries and signed containers) on gke with binauthz
aliases:
    - /binauthz/
---
![6 steps of a CI/CD worklow showing 2 of the related to Binary Authorization: signing in container registry and validating at runtime on Kubernetes.](https://storage.googleapis.com/gweb-cloudblog-publish/images/How_Voucher_simplifies_a_secure_supply_cha.max-1400x1400.jpg)

> Binary Authorization is a deploy-time security control that ensures only trusted container images are deployed on Google Kubernetes Engine (GKE). With Binary Authorization, you can require images to be signed by trusted authorities during the development process and then enforce signature validation when deploying. By enforcing validation, you can gain tighter control over your container environment by ensuring only verified images are integrated into the build-and-release process.

The [Binary Authorization](https://cloud.google.com/binary-authorization) and [Container Analysis](https://cloud.google.com/artifact-registry/docs/analysis) are based upon the open source projects:
- [Grafeas](https://grafeas.io/) defines an API spec for managing metadata about software resources, such as container images, Virtual Machine (VM) images, JAR files, and scripts. You can use Grafeas to define and aggregate information about your project’s components.
- [Kritis](https://github.com/grafeas/kritis) defines an API for ensuring a deployment is prevented unless the artifact (container image) is conformant to central policy and optionally has the necessary attestations present.

5 simple steps to accomplish this:
- [Setup your GKE cluster]({{< ref "#setup-your-gke-cluster" >}})
- [Apply cluster policies]({{< ref "#apply-cluster-policies" >}})
- [Create an attestor]({{< ref "#create-an-attestor" >}})
- [Create an attestation]({{< ref "#create-an-attestation" >}})
- [Deploy a signed container]({{< ref "#deploy-a-signed-container" >}})

## Setup your GKE cluster

```
projectId=FIXME
registryName=$location-docker.pkg.dev/$projectId/containers
gcloud config set project $projectId

gcloud services enable container.googleapis.com
gcloud services enable binaryauthorization.googleapis.com

gcloud container clusters create \
    --enable-binauthz

# You could also enable this feature on an existing cluster
gcloud container clusters update $clusterName \
    --enable-binauthz

# Deploy the hello-world container from DockerHub
kubectl create deployment hello-world \
    --image=hello-world:latest
kubectl get pods

# Deploy the hello-world container from your private container registry
docker pull hello-world:latest
docker tag hello-world:latest $registryName/hello-world:latest
gcloud auth configure-docker --quiet
docker push $registryName/hello-world:latest
kubectl create deployment hello-world \
    --image=$registryName/hello-world:latest
kubectl get pods
```

## Apply cluster policies

Securing the cluster with a policy, as a policy creator:
```
# Get the default policy in place
gcloud container binauthz policy export > policy.yaml
cat policy.yaml

# Find all the default additional global policies in place
gcloud container binauthz policy export --project=binauthz-global-policy

# Change the default evaluationMode by ALWAYS-DENY
sed -i "s/evaluationMode: ALWAYS_ALLOW/evaluationMode: ALWAYS_DENY/g" policy.yaml
gcloud container binauthz policy import policy.yaml

# Check that any new deployment will fail with "Denied by default admission rule" error message in events
kubectl create deployment hello-world \
    --image=hello-world:latest
kubectl get event
kubectl create deployment hello-world \
    --image=$registryName/hello-world:latest
kubectl get event

# Change the admissionWhitelistPatterns list by removing the redundant global policies and adding our own container registry
cat > policy.yaml << EOF
admissionWhitelistPatterns:
- namePattern: $registryName/*
defaultAdmissionRule:
  enforcementMode: ENFORCED_BLOCK_AND_AUDIT_LOG
  evaluationMode: ALWAYS_DENY
globalPolicyEvaluationMode: ENABLE
name: projects/$projectId/policy
EOF
gcloud container binauthz policy import policy.yaml

# Check that the DockerHub deployment will fail with "Denied by default admission rule" error message in events but in the other end, the $registryName/hello-world will work now
kubectl create deployment hello-world \
    --image=hello-world:latest
kubectl get event
kubectl create deployment hello-world \
    --image=$registryName/hello-world:latest
kubectl get pod
```

That's how easy it is to authorize or not container images from specific container registries on your GKE clusters. You could find [more policies examples here](https://cloud.google.com/binary-authorization/docs/example-policies). An interesting feature to be aware of is the [dry run mode](https://cloud.google.com/binary-authorization/docs/enabling-dry-run) which checks policy compliance at Pod creation time but without actually blocking the Pod from being created. Less radical and more gradual way to integrate Binary authorization on your existing GKE clusters.

## Create an attestor

We need to [create an attestor](https://cloud.google.com/binary-authorization/docs/creating-attestors-cli):

```
deployerProjectId=FIXME
deployerProjectNumber=$(gcloud projects describe "$deployerProjectId" --format="value(projectNumber)")
attestorProjectId=FIXME
attestorProjectNumber=$(gcloud projects describe "$attestorProjectId" --format="value(projectNumber)")
deployerSa="service-$deployerProjectNumber@gcp-sa-binaryauthorization.iam.gserviceaccount.com"
attestorSa="service-$attestorProjectNumber@gcp-sa-binaryauthorization.iam.gserviceaccount.com"
# Create a Container Analysis note
noteId=NOTE_ID
noteUri="projects/$attestorProjectId/notes/$noteId"
description=FIXME
cat > /tmp/note_payload.json << EOM
{
  "name": "$noteUri",
  "attestation": {
    "hint": {
      "human_readable_name": "$description"
    }
  }
}
EOM
curl \
    -X POST \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $(gcloud auth print-access-token)"  \
    -H "x-goog-user-project: $attestorProjectId" \
    --data-binary @/tmp/note_payload.json  \
    "https://containeranalysis.googleapis.com/v1/projects/$attestorProjectId/notes/?noteId=$noteId"
curl \
    -H "Authorization: Bearer $(gcloud auth print-access-token)"  \
    -H "x-goog-user-project: $attestorProjectId" \
    "https://containeranalysis.googleapis.com/v1/projects/$attestorProjectId/notes/"
# Set permissions on the note
cat > /tmp/iam_request.json << EOM
{
  "resource": "$noteUri",
  "policy": {
    "bindings": [
      {
        "role": "roles/containeranalysis.notes.occurrences.viewer",
        "members": [
          "serviceAccount:$attestorSa"
        ]
      }
    ]
  }
}
EOM
curl -X POST  \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $(gcloud auth print-access-token)" \
    -H "x-goog-user-project: $attestorProjectId" \
    --data-binary @/tmp/iam_request.json \
    "https://containeranalysis.googleapis.com/v1/projects/$attestorProjectId/notes/noteId:setIamPolicy"
# Generate a key pair
pricateKeyFile="/tmp/ec_private.pem"
openssl ecparam -genkey -name prime256v1 -noout -out $pricateKeyFile
publicKeyFile="/tmp/ec_public.pem"
openssl ec -in $pricateKeyFile -pubout -out $publicKeyFile
# Create the attestor
attestorName=FIXME
gcloud container binauthz attestors create $attestorName \
    --project $attestorProjectId \
    --attestation-authority-note $noteId \
    --attestation-authority-note-project $attestorProjectId
gcloud beta container binauthz attestors add-iam-policy-binding "projects/$attestorProjectId/attestors/$attestorName" \
    --member="serviceAccount:$deployerSa" \
    --role=roles/binaryauthorization.attestorsVerifier
# Add the public key to the attestor via Cloud KMS
kmsKeyProjectId=FIXME
kmsKeyringName=my-binauthz-keyring
kmsKeyName=my-binauthz-kms-key-name
kmsKeyLocation=global
kmsKeyVersion=1
gcloud kms keyrings create $kmsKeyringName \
    --location $kmsKeyLocation
gcloud kms keys create $kmsKeyName \
    --location $kmsKeyLocation \
    --keyring $kmsKeyringName  \
    --purpose asymmetric-signing \
    --default-algorithm ec-sign-p256-sha256 \
    --protection-level software
gcloud container binauthz attestors public-keys add \
    --project $attestorProjectId \
    --attestor $attestorName \
    --keyversion-project $kmsKeyProjectId \
    --keyversion-location $kmsKeyLocation \
    --keyversion-keyring $kmsKeyringName \
    --keyversion-key $kmsKeyName \
    --keyversion $kmsKeyVersion
# Verify that the attestor was created
gcloud container binauthz attestors list \
    --project $attestorProjectId
```

## Create an attestation

Let's now [create an attestation with a Cloud Key Management Service-based PKIX signature](https://cloud.google.com/binary-authorization/docs/making-attestations#create_an_attestation_with_a-based_pkix_signature):

```
imageName=$registryName/hello-world:latest
imageToAttest=$(gcloud artifacts docker images describe $imageName --format='get(image_summary.fully_qualified_digest)')
gcloud beta container binauthz attestations sign-and-create \
    --project=$projectId \
    --artifact-url=$imageToAttest \
    --attestor=$attestorName \
    --attestor-project=$attestorProjectId \
    --keyversion-project=$kmsKeyProjectId \
    --keyversion-location=$kmsKeyLocation \
    --keyversion-keyring=$kmsKeyringName \
    --keyversion-key=$kmsKeyName \
    --keyversion=$kmsKeyVersion
```

If you would like to run this exact same command above from within Cloud Build, so you will need to update the IAM roles of its service account:
```
projectId=FIXME
projectNumber="$(gcloud projects describe $projectId --format='get(projectNumber)')"
cloudBuildSa=$projectNumber@cloudbuild.gserviceaccount.com
roles="roles/binaryauthorization.attestorsViewer roles/cloudkms.signerVerifier roles/containeranalysis.notes.attacher"
for r in $roles; do gcloud projects add-iam-policy-binding $projectId --member "serviceAccount:$cloudBuildSa" --role $r; done
```

_Note: Shopify in collaboration with Google, just released the [`voucher` project](https://cloud.google.com/blog/products/devops-sre/introducing-voucher-service-help-secure-container-supply-chain) to add more security with your BinAuthz Attestation creation during your CI/CD pipeline._

## Deploy a signed container

Last step is to actually [deploy the container on GKE](https://cloud.google.com/binary-authorization/docs/deploying-containers), you will need to get the `digest` instead of the `tag` like we did earlier with the `imageToAttest` variable.

That's a wrap! Binary Authorization allows to add more security in your CI/CD pipeline with more control on you GKE clusters with container registries whitelisting as well as allowing only container images with a valid attestation. And all of this with any container registries (even outside GCP) because at the end of the day, that's just Attestor/Attestation on GCP on any container images digest (whereever this container image is) ;)

Further and complementary resources:
- [Binary Authorization for Borg: how Google verifies code provenance and implements code identity](https://cloud.google.com/security/binary-authorization-for-borg/)
- [End-To-End Security and Compliance for Your Kubernetes Software Supply Chain (Cloud Next '19)](https://youtu.be/UkzfQvLpI0M)
- [Codelab: Securing Your GKE Deployments with Binary Authorization](https://codelabs.developers.google.com/codelabs/cloud-binauthz-intro/index.html#0)
- [Binary Authorization pricing](https://cloud.google.com/binary-authorization/pricing)
- [Securing with VPC Service Controls](https://cloud.google.com/binary-authorization/docs/securing-with-vpcsc)

Hope you enjoyed that one, happy sailing, stay safe!