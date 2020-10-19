---
title: gke's service account
date: 2020-10-18
tags: [gcp, kubernetes, security]
description: let's discuss about how to deal with gke's service account and few tips to improve your security posture, especially with fine-grained identity and authorization for applications with workload identity
aliases:
    - /gke-service-account/
---
[![](https://storage.googleapis.com/gweb-cloudblog-publish/images/GCP_Security_kLUG9v5.max-2200x2200.jpg)](https://storage.googleapis.com/gweb-cloudblog-publish/images/GCP_Security_kLUG9v5.max-2200x2200.jpg)

I just went through the description of this [CVE-2020-15157 "ContainerDrip" Write-up](https://darkbit.io/blog/cve-2020-15157-containerdrip). I found these information very insightful especially since there is some illustrations and great story with GKE.

> [CVE-2020-15157](https://nvd.nist.gov/vuln/detail/CVE-2020-15157): If an attacker publishes a public image with a crafted manifest that directs one of the image layers to be fetched from a web server they control and they trick a user or system into pulling the image, they can obtain the credentials used by `ctr/containerd` to access that registry. In some cases, this may be the user’s username and password for the registry. In other cases, this may be the credentials attached to the cloud virtual instance which can grant access to other cloud resources in the account.

Interesting! By going through the description of this CVE you could find that it's an old version of `containerd` (i.e. `1.2.x`) which is impacted. With GKE, if you are using the [`cos_containerd` or `ubuntu_containerd` node images](https://cloud.google.com/kubernetes-engine/docs/concepts/using-containerd), it's an old `1.16` version which might be impacted too.

How to check if you are impacted if you are using a `containerd` node image, you could simply check the `containerd`'s version of your GKE cluster by running this command: `kubectl get nodes -o wide`. As an example, for my own cluster I got:
- `OS-IMAGE`: `Container-Optimized OS from Google`
- `CONTAINER-RUNTIME`: `containerd://1.4.1`

So all good here, but the goal of this article today is to see what are the features you could leverage to make a robust security posture.

There is already 2 important aspects to improve your security posture here:
- [Auto-upgrading nodes](https://cloud.google.com/kubernetes-engine/docs/how-to/node-auto-upgrades)
    - _Keeping the version of Kubernetes up to date is one of the simplest things you can do to improve your security. Kubernetes frequently introduces new security features and provides security patches._
- [`cos_containerd`](https://cloud.google.com/container-optimized-os/docs/concepts/security)
    - _`cos_containerd` is the preferred image for GKE as it has been custom built, optimized, and hardened specifically for running containers._

I also watched the video below which is referenced in the [first article I mentioned](https://darkbit.io/blog/cve-2020-15157-containerdrip). As I'm improving my knowledge and skills with cloud security principles, such approach and point of view from an hacker perspective is really insightful. Here below, they are talking about [lateral movement and privilege escalation in GCP](https://youtu.be/Z-JFVJZ-HDA):

{{< youtube Z-JFVJZ-HDA >}}

There is 3 important aspects to improve your security posture here:
- [Default node service account and Workload Identity](https://cloud.google.com/kubernetes-engine/docs/how-to/hardening-your-cluster#use_least_privilege_sa)
    - _This `Compute Engine default service account` is overprivileged by default as the [Editor role](https://cloud.google.com/iam/docs/understanding-roles#primitive_role_definitions) allows you to access and edit essentially everything in the project._
    - You could [disable automatic grants to default service accounts](https://cloud.google.com/resource-manager/docs/organization-policy/restricting-service-accounts#disable_service_account_default_grants) at your Organization Policies level.
    - Here, I would like to call out [this very well written article](https://code.kiwi.com/towards-secure-by-default-google-cloud-platform-service-accounts-244ad9fc772) to see the impacts of this and some real life examples of compagnies hacked because they didn't pay attention of this least privilege principle for the identity of their applications.
- [Workload Identity](https://cloud.google.com/kubernetes-engine/docs/how-to/workload-identity)
    - _Workload Identity is the recommended way to access Google Cloud services from applications running within GKE due to its improved security properties and manageability._
- [IAM Recommender](https://cloud.google.com/iam/docs/recommender-overview)
    - _IAM recommender helps you enforce the principle of least privilege by ensuring that members have only the permissions that they actually need._
    - Great story here where the 2 authors provided improvement to the product group team managing the new IAM Recommender service. Love it!

Let's translate this least privilege setup for the identity of your nodes and workloads with few `gcloud` commands:
```
projectId=FIXME
clusterName=FIXME

gcloud services enable cloudresourcemanager.googleapis.com
saId=$clusterName@$projectId.iam.gserviceaccount.com
gcloud iam service-accounts create $clusterName \
  --display-name=$clusterName
gcloud projects add-iam-policy-binding $projectId \
  --member serviceAccount:$saId \
  --role roles/logging.logWriter
gcloud projects add-iam-policy-binding $projectId \
  --member serviceAccount:$saId \
  --role roles/monitoring.metricWriter
gcloud projects add-iam-policy-binding $projectId \
  --member serviceAccount:$saId \
  --role roles/monitoring.viewer
# If your cluster pulls private images from GCR:
gcloud projects add-iam-policy-binding $projectId \
  --member serviceAccount:$saId \
  --role roles/storage.objectViewer

# Now you could create your cluster with this service account:
gcloud container clusters create $clusterName \
  --service-account=$saId

# Interestingly, you could have a different service account by nodepool (important if you would like to have different workloads on different node pools):
gcloud container node-pools create \
  --service-account=$saId

# And ultimately, you could enable Workload Identity on your cluster (which is even more important for fine-grained identity and authorization for applications):
gcloud container clusters create $clusterName \
    --service-account $saId \
    --workload-pool=$projectId.svc.id.goog
```

Then you could easily [follow these instructions](https://cloud.google.com/kubernetes-engine/docs/how-to/workload-identity#authenticating_to) to allow your applications authenticate to Google Cloud using Workload Identity, typically by assigning a Kubernetes service account to the application and configure it to act as a Google service account.

> With [Workload Identity](https://cloud.google.com/kubernetes-engine/docs/how-to/workload-identity), you can configure a Kubernetes service account to act as a Google service account. Any application running as the Kubernetes service account automatically authenticates as the Google service account when accessing Google Cloud APIs. This enables you to assign fine-grained identity and authorization for applications in your cluster.

_Note: there is [few limitations currently with Workload Identity](https://cloud.google.com/kubernetes-engine/docs/how-to/workload-identity#limitations) that you should be aware of._

You could learn more about [Workload Identity with this session when it was launched on 2019](https://cloud.google.com/blog/products/containers-kubernetes/introducing-workload-identity-better-authentication-for-your-gke-applications):
{{< youtube s4NYEJDFc0M >}}

In addition to this, here are 3 other aspects to still improve and complete your security posture that you may want to leverage:
- [Shielded GKE Nodes](https://cloud.google.com/kubernetes-engine/docs/how-to/shielded-gke-nodes)
    - _Without Shielded GKE Nodes an attacker can exploit a vulnerability in a Pod to exfiltrate bootstrap credentials and impersonate nodes in your cluster, giving the attackers access to cluster secrets._
- [Private clusters](https://cloud.google.com/kubernetes-engine/docs/concepts/private-cluster-concept)
    - _Private clusters give you the ability to isolate nodes from having inbound and outbound connectivity to the public internet. This isolation is achieved as the nodes have internal IP addresses only._
- [Binary Authorization](https://cloud.google.com/binary-authorization)
    - _Binary Authorization is a deploy-time security control that ensures only trusted container images are deployed on GKE._

Complementary resources:
- [Preparing a Google Kubernetes Engine environment for production](https://cloud.google.com/solutions/prep-kubernetes-engine-for-prod)
- [Hardening your cluster's security](https://cloud.google.com/kubernetes-engine/docs/how-to/hardening-your-cluster)
- [Preventing lateral movement in Google Compute Engine](https://cloud.google.com/blog/products/identity-security/preventing-lateral-movement-in-google-compute-engine)
- [Don't get pwned: practicing the principle of least privilege](https://cloud.google.com/blog/products/identity-security/dont-get-pwned-practicing-the-principle-of-least-privilege)
- [gVisor: Protecting GKE and serverless users in the real world](https://cloud.google.com/blog/products/containers-kubernetes/how-gvisor-protects-google-cloud-services-from-cve-2020-14386)
- [GKE Security bulletins](https://cloud.google.com/kubernetes-engine/docs/security-bulletins)
- [Stop Downloading Google Cloud Service Account Keys!](https://medium.com/@jryancanty/stop-downloading-google-cloud-service-account-keys-1811d44a97d9)

That's a wrap! We discussed about features you could enable on your GKE cluster (especially with Workload Identity) and more importantly the concept of least privilege service account instead of the default one for your GKE clusters. Yeah for sure, you could say to yourself "how an hacker could get my cluster credentials to be able to operate such attack?". Yeah that's for sure something which won't happen every day, but it's only a matter of worst case scenario + making sure you have different layers in place to improve your security posture. How do you think data leaks happen? How do you make sure you could prevent data leaks in your organization?

_Important note: this article got illustrations with GKE, but they apply for any Kubernetes, on any Cloud provider since they got very similar implementation, principles and features._

Hope you enjoyed that one. Sharing is caring, stay safe! ;)