---
title: sigstore's cosign and kyverno with gke and kms
date: 2023-03-27
tags: [gcp, kubernetes, policies, security, containers]
description: let's see how we could only allow our own private container images signed by cosign to be deployed in our gke cluster thanks to kyverno
draft: true
aliases:
    - /cosign-with-gke-and-kyverno/
---

Define a least privilege Google Service Account (GSA) for policy-controller by granting the cloudkms.viewer, cloudkms.verifier and artifactregistry.reader roles and by enabling Workload Identity between the Kubernetes Service Account and the Google Service Account:
```bash
KYVERNO_GSA_NAME=kyverno-sa
KYVERNO_GSA_ID=${KYVERNO_GSA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com

gcloud iam service-accounts create ${KYVERNO_GSA_NAME}

gcloud iam service-accounts add-iam-policy-binding ${KYVERNO_GSA_ID} \
    --role roles/iam.workloadIdentityUser \
    --member "serviceAccount:${PROJECT_ID}.svc.id.goog[kyverno/kyverno]"

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
    --role roles/cloudkms.verifier \
    --member serviceAccount:${KYVERNO_GSA_ID}
gcloud projects add-iam-policy-binding ${PROJECT_ID} \
    --role roles/cloudkms.viewer \
    --member serviceAccount:${KYVERNO_GSA_ID}

gcloud artifacts repositories add-iam-policy-binding ${REGISTRY_NAME} \
    --location ${REGION} \
    --member "serviceAccount:${KYVERNO_GSA_ID}" \
    --role roles/artifactregistry.reader
```

Install Kyverno in this GKE cluster by annotating its `ServiceAccount` to use Workload Identity:
```bash
helm repo add kyverno https://kyverno.github.io/kyverno/
helm repo update
helm upgrade kyverno \
    kyverno/kyverno \
    -n kyverno \
    --install \
    --create-namespace
```

Annotate Kyverno `ServiceAccount` to use Workload Identity:
```bash
kubectl annotate serviceaccount \
    --namespace kyverno \
    kyverno \
    iam.gke.io/gcp-service-account=${KYVERNO_GSA_ID}
```

Deploy a policy only allowing signed container images with our Cloud KMS key:
```bash
cat << EOF  | kubectl apply -f -
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: container-images-need-to-be-signed
spec:
  validationFailureAction: Enforce
  background: true
  rules:
  - name: container-images-need-to-be-signed
    match:
      any:
      - resources:
          kinds:
          - Pod
    exclude:
      any:
      - resources:
          namespaces:
          - kube-system
          - kube-node-lease
          - kube-public
          - kyverno
    verifyImages:
      - imageReferences:
        - "*"
        attestors:
        - count: 1
          entries:
          - keys:
              kms: gcpkms://projects/${PROJECT_ID}/locations/${REGION}/keyRings/${KEY_RING}/cryptoKeys/${KEY_NAME}/cryptoKeyVersions/1
EOF
```

Enfore this policy for the test namespace:
FIXME

Hope you enjoyed that one! Happy signing, happy sailing!
