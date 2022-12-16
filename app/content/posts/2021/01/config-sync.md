---
title: gitops on gke with config sync
date: 2021-01-20
tags: [containers, security, gcp, kubernetes, gitops]
description: let's see gitops in actions with gke's config sync
aliases:
    - /config-sync/
---
Today, let's see a GitOps setup in actions on GKE with [Config Sync](https://cloud.google.com/anthos-config-management/docs/config-sync-overview). I won't go with the definition of what is GitOps, but if you are new with the concept, [Weavework is doing a great job on explaining and illustrating what GitOps is](https://www.weave.works/technologies/gitops/). Another way to understand what is GitOps is to watch and listen to Kelsey Hightower during the last GitHub Universe conference: 

{{< youtube id="yIAa5wHsfw4" title="Kelsey, Kubernetes, and GitOps - GitHub Universe 2020" >}}

What I love about GitOps:
- Everything-as-Code in a Git repository: infrastructure, platform, config, policies, etc. as code
- Git flow as the continuous deployments workflow via Pull Requests and branches
- Continuous deployments by pulling Kubernetes manifests instead of having agent/tool pushing stuffs in Kubernetes: more secure, more centralized and way more simplified setup and control.

Now we have the concepts, what we would like to do here is creating a Git repository ready to host the Kubernetes manifests associated to the applications I would like to deploy on my Kubernetes cluster(s).

## Prepare the Git repository

Install `nomos`:
```
gsutil cp gs://config-management-release/released/latest/linux_amd64/nomos nomos
chmod +x nomos
sudo mv nomos /usr/local/bin/nomos
nomos version
```

Initialize your Git repo:
```
nomos init
nomos status
# git add, git push...
```

You now have this structure in your Git repository:
```
cluster/
clusterregistry/
namespaces/ # configs that are scoped to namespaces
system/
└── README.md
└── repo.yaml
```

Let's create our first Kubernetes manifest:
```
mkdir namespaces/hello
cat > namespaces/hello/policy.yaml << EOF
kind: Namespace
apiVersion: v1
metadata:
  name: hello
EOF
# git add, git push...
```

You could check the syntax and validity of the configs in your repository:
```
nomos vet
```

## Prepare your GKE cluster

Register your GKE cluster with an Anthos entitlement:
```
projectId=FIXME
gcloud config set project $projectId

# ACM comes with Anthos
gcloud services enable anthos.googleapis.com
gcloud beta container hub config-management enable

# Add our cluster as a Hub membership
clusterName=FIXME
zone=FIXME
gcloud container hub memberships register $clusterName \
  --gke-cluster $zone/$clusterName \
  --enable-workload-identity
```

## Setup the continuous deployments

Setup Config Sync to actually synchronised that repo in your GKE cluster:
```
syncRepo=FIXME
branch=FIXME
cat > configsync-config.yaml << EOF
applySpecVersion: 1
spec:
  configSync:
    enabled: true
    sourceFormat: hierarchy
    syncRepo: $syncRepo
    syncBranch: $branch
    secretType: none
    policyDir: .
EOF

gcloud beta container hub config-management apply \
  --membership=$clusterName \
  --config=configsync-config.yaml
```

Wait for few seconds, and check everything is deployed and synchronized properly:
```
# You should see your cluster's status as SYNCED:
nomos status
gcloud alpha container hub config-management status

# You should now see the hello namespace we defined earlier:
kubectl get ns

# This hello namespace should be tagged as managed by Config Sync too:
kubectl get ns -l app.kubernetes.io/managed-by=configmanagement.gke.io
```

And that's it! Now, any update on this repository with any Kubernetes manifests will be synchronized and applied by Config Sync for you. From here, you may want to have different branches pointing to different clusters and having in place a solid and easy continuous deployments workflow via Pull Requests and branches.

Notes:
- I used a public GitHub repository, in the real life you will need to [grant the Config Sync Operator access to your private Git repository](https://cloud.google.com/anthos-config-management/docs/how-to/installing-config-sync#git-creds-secret).
- If you delete the Kubernetes objects managed and synchronized by Config Sync in your cluster, they will be recreated by Config Sync.
- You could manage the deployments on multi-clusters from within the same Git repository by using the concept of [Cluster selectors](https://cloud.google.com/anthos-config-management/docs/how-to/cluster-scoped-objects).
- For the upgrade of `nomos` and Config Sync, it's respectively documented [here](https://cloud.google.com/anthos-config-management/docs/how-to/nomos-command#installing) and [here](https://cloud.google.com/anthos-config-management/docs/how-to/upgrading-config-sync).
- `Helm` and `Kustomize` are not yet supported by Config Sync.

Complementary and further resources:
- [Top GitOps Tactics to Build Secure Cloud-Native Infrastructure](https://www.cncf.io/blog/2022/01/07/top-gitops-tactics-to-build-secure-cloud-native-infrastructure/)
- [Managing Kubernetes with Config Sync](https://youtu.be/_MrHbQKbPDY)
- [Config Management downloads](https://cloud.google.com/anthos-config-management/docs/downloads)
- [Config Sync errors reference](https://cloud.google.com/anthos-config-management/docs/reference/errors)
- [Guide to GitOps by Weavework](https://www.weave.works/technologies/gitops/)
- [More Anthos Config Management samples](https://github.com/GoogleCloudPlatform/csp-config-management)
- [How GitOps and the KRM make multi-cloud less scary](https://seroter.com/2021/01/12/how-gitops-and-the-krm-make-multi-cloud-less-scary/)
- [GitLab CI and ArgoCD with Anthos Config Management](https://www.arctiq.ca/our-blog/2021/1/18/cicd-pipelines-using-gitlab-ci-argo-cd-with-anthos-config-management/)

Hope you enjoyed that one, happy sailing! ;)