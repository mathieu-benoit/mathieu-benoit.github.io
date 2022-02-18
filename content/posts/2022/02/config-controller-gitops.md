---
title: gitops with config controller
date: 2022-02-15
tags: [gcp, kubernetes, security]
description: let's see with config controller how we could set up a gitops approach to actually deploy kubernetes manifests
aliases:
    - /config-controller-gitops/
---
So, with the previous article about [Config Controller in action]({{< ref "/posts/2022/02/config-controller-intro.md" >}}), you could ask these questions:
- _Ok, but that's a lot of `kubectl apply` commands... how to simplify this if I don't have access to the Config Controller endpoint for security and networking reasons?_
- _I thought Config Controller includes Config Sync too in order to deploy Kubernetes manifests in a GitOps way?_

Exactly, spot on! The previous article was already full of content and concepts to show the power and goodies of Config Controller. But glad you asked! Let's demonstrate this GitOps/Config Sync story now in this part 2! ;)

Here is what we are going to illustrate throughout this blog article:

![Config Controller flow with Config Sync in addition to Config Connector and Policy Controller.](https://raw.githubusercontent.com/mathieu-benoit/my-images/main/config-controller-gitops-flow.png)

For this, we will cover two main parts in this article:
- [Set up the Platform Git repo]({{< ref "#set-up-the-platform-git-repo" >}})
- [Set up the Tenant project Git repo]({{< ref "#set-up-the-tenant-project-git-repo" >}})

_Note: we are using GitHub throughout this article, but you could use different Git platform, see more information [here](https://cloud.google.com/anthos-config-management/docs/how-to/installing-config-sync#git-creds-secret)._

## Set up the Platform Git repo

> As a Platform Admin, I want to set up a repository where I store any configurations I want to apply to my Config Controller cluster: like policies, common configs, etc. accross my company.

First, because Config Controller is a private GKE cluster, it doesn't have Internet access in egress. In order to have access from Config Sync to a GitHub repository, we need to set up Cloud NAT for the Config Controller cluster:
```
CONFIG_CONTROLLER_NETWORK=$(gcloud anthos config controller describe $CONFIG_CONTROLLER_NAME \
    --location=$CONFIG_CONTROLLER_LOCATION \
    --format='get(network)')
gcloud compute routers create nat-router \
    --network $CONFIG_CONTROLLER_NETWORK \
    --region $CONFIG_CONTROLLER_LOCATION
gcloud compute routers nats create nat-config \
    --router-region $CONFIG_CONTROLLER_LOCATION \
    --router nat-router \
    --nat-all-subnet-ip-ranges \
    --auto-allocate-nat-external-ips
```

Then, we could configure Config Management to support multi-repositories for Config Sync:
```
cat << EOF | kubectl apply -f -
apiVersion: configmanagement.gke.io/v1
kind: ConfigManagement
metadata:
  name: config-management
spec:
  enableMultiRepo: true
  policyController:
    enabled: true
    exemptableNamespaces: ["cnrm-system","config-control"]
EOF
kubectl wait --for condition=established crd rootsyncs.configsync.gke.io
```

Finally, we create a `RootSync` configuration to link a dedicated Git repo cluster-wide:
```
PLATFORM_REPO_URL=https://github.com/mathieu-benoit/configcontroller-platform-repo #FIXME wity your own
cat << EOF | kubectl apply -f -
apiVersion: configsync.gke.io/v1beta1
kind: RootSync
metadata:
  name: root-sync
  namespace: config-management-system
spec:
  sourceFormat: unstructured
  git:
    repo: ${PLATFORM_REPO_URL}
    revision: HEAD
    branch: main
    dir: "config-sync"
    auth: none
EOF
```
_Note: We are using `auth: none` because we are using a public Git repository, but [you could follow these instructions to properly set up Config Sync for private Git repositories](https://cloud.google.com/anthos-config-management/docs/how-to/installing-config-sync#git-creds-secret)._

From here we could double-check that our Git repository is successfully synchronized:
```
nomos status --contexts $(kubectl config current-context)
gcloud alpha anthos config sync repo list --targets config-controller
```

And that's it, we just set up the GitHub repository where the Platform Admin will drop any Kubernetes manifests they want deployed in their Config Controller cluster. All the [files created in the part 1]({{< ref "/posts/2022/02/config-controller-intro.md" >}}) are in this sample platform repo: https://github.com/mathieu-benoit/configcontroller-platform-repo/tree/main/config-sync, you could have a look to see the policies and other resources needed to properly setup the tenant project/namespace.

## Set up the Tenant project Git repo

> As a Platform Admin, I want to set up a dedicated Git repository for a Tenant project.

Let's actually see GitOps in action here, we will create the required files for this section, and then we will commit them into the Platform Git repository to eventually trigger Config Controller's Config Sync.

Clone the platform repository locally:
```
cd ~
git clone $PLATFORM_REPO_URL
cd configcontroller-platform-repo/config-sync/projects/${TENANT_PROJECT_ID}/
```

_Note: we are leveraging the ["Control namespace repositories in the root repository"](https://cloud.google.com/anthos-config-management/docs/how-to/namespace-repositories) method here._

Create the `RepoSync` resource in the Tenant project namespace, to link the Tenant project Git repository to its dedicated Tenant project/namespace:
```
TENANT_REPO_URL=https://github.com/mathieu-benoit/configcontroller-tenant-repo
cat <<EOF > repo-sync-${TENANT_PROJECT_ID}.yaml
apiVersion: configsync.gke.io/v1beta1
kind: RepoSync
metadata:
  name: repo-sync
  namespace: ${TENANT_PROJECT_ID}
spec:
  sourceFormat: unstructured
  git:
   repo: ${TENANT_REPO_URL}
   revision: HEAD
   branch: main
   dir: "config-sync"
   auth: none
EOF
```

We also need to declare the associated `RoleBinding` in the Tenant project namespace:
```
cat <<EOF > repo-sync-role-binding-${TENANT_PROJECT_ID}.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: syncs-repo
  namespace: ${TENANT_PROJECT_ID}
subjects:
- kind: ServiceAccount
  name: ns-reconciler-${TENANT_PROJECT_ID}
  namespace: config-management-system
roleRef:
  kind: ClusterRole
  name: edit
  apiGroup: rbac.authorization.k8s.io
EOF
```
_Note: For the `ClusterRole`'s name field, the options could be seen [here](https://kubernetes.io/docs/reference/access-authn-authz/rbac/#user-facing-roles)._

Finally, let's commit these two files:
```
git add .
git commit -m 'Setting up reposync resource for ${TENANT_PROJECT_ID}.'
git push
```

From here we could double-check that both Git repositories are successfully synchronized:
```
nomos status --contexts $(kubectl config current-context)
gcloud alpha anthos config sync repo list --targets config-controller
```

And that's it, that's a wrap! The Tenant project Ops hasn't done anything here (and that's the goal), it was all about the Platform admin to properly set up the environment for them. Tenant project Ops can now start do commits in their own Git repository to provision GCP resources. As an example, you could have a look at this sample Tenant project repository I set up: https://github.com/mathieu-benoit/configcontroller-tenant-repo/tree/main/config-sync. So now the Tenant project team has the right setup to actually provision any GCP resources via Kubernetes manifests by placing them into this Git repository. With that, they will follow security and governance in place provided by the Platform admin. Sweet!

## Complementary and further resources

- [Add policies guardrails during Continuous Integration (CI) pipelines]({{< ref "/posts/2021/11/policy-controller-ci.md" >}}) - you could find a [specific example of this in the Platform repository](https://github.com/mathieu-benoit/configcontroller-platform-repo/blob/main/.github/workflows/ci.yml).
- [`RootSync` and `RepoSync` fields](https://cloud.google.com/anthos-config-management/docs/reference/rootsync-reposync-fields)
- [Monitor `RootSync` and `RepoSync` objects](https://cloud.google.com/anthos-config-management/docs/how-to/monitor-rootsync-reposync)
- [Config Sync and Kustomize & Helm](https://cloud.google.com/anthos-config-management/docs/how-to/use-repo-kustomize-helm)

Hope you enjoyed that one, cheers!