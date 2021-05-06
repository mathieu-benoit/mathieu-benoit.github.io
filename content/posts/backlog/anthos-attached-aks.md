---
title: fixme
date: 2020-08-10
tags: [fixme]
description: fixme
draft: true
aliases:
    - /fixme/
---

https://cloud.google.com/blog/topics/anthos/how-anthos-makes-multicloud-possible-today

FIXME:
- Integrate this? https://cloud.google.com/blog/products/identity-security/enable-keyless-access-to-gcp-with-workload-identity-federation

https://cloud.google.com/anthos/docs/version-and-upgrade-support

```
group=mabenoit
location=eastus
cluster=aks-cluster
az group create --name $group --location $location
az aks create --resource-group $group --name $cluster --location $location --node-count 4  --node-vm-size Standard_DS3_v2 --no-ssh-key
az aks get-credentials --resource-group $group --name $cluster
```

https://cloud.google.com/anthos/multicluster-management/connect/prerequisites#create_sa
```
aksSa=aks-sa
hubGcpProjectId=FIXME
gcloud iam service-accounts create $aksSa --project $hubGcpProjectId
gcloud projects add-iam-policy-binding ${hubGcpProjectId} \
    --member="serviceAccount:${aksSa}@${hubGcpProjectId}.iam.gserviceaccount.com" \
    --role="roles/gkehub.connect" \
    --condition="expression=resource.name == 'projects/${hubGcpProjectId}/locations/global/memberships/${cluster}',title=bind-${aksSa}-to-${cluster}"
gcloud iam service-accounts keys create ~/tmp/aks-sa-${hubGcpProjectId}.json \
    --iam-account ${aksSa}@${hubGcpProjectId}.iam.gserviceaccount.com \
    --project ${hubGcpProjectId}
```


https://cloud.google.com/anthos/docs/setup/attached-clusters#gcloud
```
gcloud container hub memberships register $cluster \
    --context $cluster \
    --service-account-key-file ~/tmp/aks-sa-${hubGcpProjectId}.json
gcloud container hub memberships list
gcloud container hub memberships describe $cluster
```

https://cloud.google.com/anthos/multicluster-management/console/logging-in
```
cat <<EOF > cloud-console-reader.yaml
kind: ClusterRole
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: cloud-console-reader
rules:
- apiGroups: [""]
  resources: ["nodes", "persistentvolumes"]
  verbs: ["get", "list", "watch"]
- apiGroups: ["storage.k8s.io"]
  resources: ["storageclasses"]
  verbs: ["get", "list", "watch"]
EOF
kubectl apply -f cloud-console-reader.yaml
gcpAccessSa=gcp-access-sa
kubectl create serviceaccount ${gcpAccessSa}
kubectl create clusterrolebinding view-${gcpAccessSa} \
    --clusterrole view --serviceaccount default:${gcpAccessSa}
kubectl create clusterrolebinding console-reader-${gcpAccessSa} \
    --clusterrole cloud-console-reader --serviceaccount default:${gcpAccessSa}
secretName=$(kubectl get serviceaccount $gcpAccessSa -o jsonpath='{$.secrets[0].name}')
kubectl get secret ${secretName} -o jsonpath='{$.data.token}' | base64 --decode
```

https://thenewstack.io/tutorial-connect-amazon-eks-and-azure-aks-clusters-with-google-anthos/