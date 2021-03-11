---
title: opa gatekeeper with policy controller
date: 2021-03-11
tags: [gcp, kubernetes, security]
description: let's see in actions how we could easily leverage opa gatekeeper on any kubernetes cluster via policy controller
aliases:
    - /policy-controller/
---
![Logo of Open Policy Agent.](https://github.com/open-policy-agent/opa/raw/master/logo/logo-144x144.png)

My [last Kubecon 2020 experience]({{< ref "/posts/2020/12/k8s-ctf.md" >}}) told me that I really needed to give both OPA and Gatekeeper a try. Since then I learned how to use [OPA as a container linter]({{< ref "/posts/2021/01/container-linter.md" >}}). What I now need to do is to leverage OPA Gatekeeper on my Kubernetes cluster.

> The [Open Policy Agent](https://www.openpolicyagent.org/) (OPA, pronounced “oh-pa”) is an open source, general-purpose policy engine that unifies policy enforcement across the stack. OPA provides a high-level declarative language that lets you specify policy as code and simple APIs to offload policy decision-making from your software. 

> [OPA Gatekeeper](https://www.openpolicyagent.org/docs/latest/kubernetes-introduction/) is a new project that provides first-class integration between OPA and Kubernetes.

Instead of installing Gatekeeper itself on my Kubernetes cluster, I will rather leverage [Policy Controller](https://cloud.google.com/anthos-config-management/docs/concepts/policy-controller).

> [Anthos Config Management](https://cloud.google.com/anthos/config-management)'s Policy Controller is a Kubernetes dynamic admission controller that checks, audits, and enforces your clusters' compliance with policies related to security, regulations, or arbitrary business rules. Policy Controller is built from the Gatekeeper open source project.

Let's see in actions how easy it is to setup Gatekeeper via Policy Controller.

## Install Policy Controller

Policy Controller could [be installed](https://cloud.google.com/anthos-config-management/docs/how-to/installing-policy-controller) on any Kubernetes clusters (not just GKE) with the following `kubectl` commands:
```
gsutil cp gs://config-management-release/released/latest/config-management-operator.yaml ~/tmp/config-management-operator.yaml
kubectl apply -f ~/tmp/config-management-operator.yaml
cat > ~/tmp/config-management.yaml << EOF
apiVersion: configmanagement.gke.io/v1
kind: ConfigManagement
metadata:
  name: config-management
spec:
  policyController:
    enabled: true
EOF
kubectl apply -f ~/tmp/config-management.yaml
```

_Notes: here are some considerations if you would like to [install Policy Controller on a private cluster](https://cloud.google.com/anthos-config-management/docs/how-to/installing-policy-controller#installing_on_a_private_cluster)._

Let's check if the installation was successful:
```
# Check if the gatekeeper components are installed
kubectl get pods -n gatekeeper-system

# Check the version of the Policy Controller
kubectl get deployments -n gatekeeper-system gatekeeper-controller-manager -o="jsonpath={.spec.template.spec.containers[0].image}"

# If your Kubernetes cluster is registered with Anthos, you could also check if Policy Controller is properly installed with ACM
gcloud alpha container hub config-management status
```

## Create constraints

You could now list the default [`constraint templates`](https://open-policy-agent.github.io/gatekeeper/website/docs/howto#constraint-templates) installed:
```
kubectl get constrainttemplates
```
You could see this list [here](https://cloud.google.com/anthos-config-management/docs/reference/constraint-template-library) too.

Based on those templates, you could create your own [constraints](https://open-policy-agent.github.io/gatekeeper/website/docs/howto/#constraints) like described [here](https://cloud.google.com/anthos-config-management/docs/how-to/creating-constraints).

Let's see an example, by leveraging the `K8sAllowedRepos` template, with which we would like to allow only specific container registries for the images of the Pods running on our cluster:
```
kubectl describe K8sAllowedRepos
cat > allowed-repos.yaml << EOF
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: K8sAllowedRepos
metadata:
  name: allowed-repos
spec:
  enforcementAction: deny
  match:
    kinds:
      - apiGroups: [""]
        kinds: ["Pod"]
  parameters:
    repos:
      - "gcr.io"
      - "k8s.gcr.io"
      - "gke.gcr.io"
kubectl apply -f allowed-repos.yaml
```

Another example could be to leverage the `K8sExternalIPs` template in order to [mitigate CVE-2020-8554](https://cloud.google.com/blog/products/application-development/protecting-your-kubernetes-deployments-policy-controller):
```
kubectl describe K8sExternalIPs
cat > no-external-ip-services.yaml << EOF
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: K8sExternalIPs
metadata:
  name: no-external-ip-services
spec:
  match:
    kinds:
      - apiGroups: [""]
        kinds: ["Service"]
EOF
kubectl apply -f no-external-ip-services.yaml
```

Leveraging the default templates is great because we don't have to write OPA regos for them. But, you may want to write your own template, [here](https://cloud.google.com/anthos-config-management/docs/how-to/write-a-constraint-template) you are for the guidance to accomplish this.

And that's it, that's how easy it is to leverage OPA Gatekeeper via Policy Controller to have more governance in place and a better security posture on your Kubernetes clusters.

## Further and complementary resources

- [OPA Gatekeeper repository](https://github.com/open-policy-agent/gatekeeper)
- [Intro to OPA](https://youtu.be/Yup1FUc2Qn0)
- [OPA deep dive](https://youtu.be/Uj2N9S58GLU)
- [Gatekeeper integration with Security Command Center](https://github.com/GoogleCloudPlatform/gatekeeper-securitycenter)

That's a wrap! Hope you enjoyed that one, sail safe out there, cheers! ;)