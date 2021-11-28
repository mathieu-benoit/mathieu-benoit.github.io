---
title: opa gatekeeper and policy controller during continuous integration (ci) pipelines
date: 2021-11-27
tags: [gcp, security, kubernetes]
description: let's see how to shift left on security by catching opa gatekeeper policy violations during continuous integration (ci) pipelines.
aliases:
    - /policy-controller-ci/
    - /opa-gatekeeper-ci/
    - /gatekeeper-ci/
---
Policies are an important part of the security and compliance of an organization. [Policy Controller]({{< ref "/posts/2021/03/policy-controller.md" >}}), which is part of Anthos Config Management, allows your organization to manage those policies centrally and declaratively for all your clusters. 

Catching policy violations as early as possible in your development workflow and in your CI pipeline instead of during the deployment has two main advantages: it lets you shift left on security, and it tightens the feedback loop, reducing the time and cost necessary to fix those violations.

_Note: OPA [Gatekeeper version 3.7](https://github.com/open-policy-agent/gatekeeper/releases/tag/v3.7.0) just brought the [`gator` CLI](https://medium.com/@LachlanEvenson/testing-gatekeeper-constraints-with-gator-cli-da31050a6564) to setup tests suite against Gatekeeper `Constraint` resources. Interesting, something to keep in mind, but I won't cover this in this blog article today. We will use `kpt` in our case._

## Context

Let's take a simple example that we will use throughout this blog article.

Let's have a dedicated folder to store the files needed:
```
mkdir workdir
```

Let's create a `Deployment` file:
```
cat <<EOF > workdir/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deploy
spec:
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
        - name: backend
          image: nginx
      securityContext:
        runAsNonRoot: false
EOF
```

Let's then define a `ConstraintTemplate` file which will catch any deployment running as `root`:
```
cat <<EOF > workdir/template.yaml
apiVersion: templates.gatekeeper.sh/v1
kind: ConstraintTemplate
metadata:
  name: disallowroot
spec:
  crd:
    spec:
      names:
        kind: DisallowRoot
  targets:
    - target: admission.k8s.gatekeeper.sh
      rego: |-
        package disallowroot
        violation[{"msg": msg}] {
          not input.review.object.spec.template.spec.securityContext.runAsNonRoot
          msg := "Containers must not run as root"
        }
EOF
```

Finally we need a `Constraint` file which will instanciate this `ConstraintTemplate`:
```
cat <<EOF > workdir/constraint.yaml
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: DisallowRoot
metadata:
  name: disallowroot
spec:
  match:
    kinds:
      - apiGroups:
          - 'apps'
        kinds:
          - Deployment
EOF
```

## Test with kpt

> `kpt` is a Git-native, schema-aware, extensible client-side tool for packaging, customizing, validating, and applying Kubernetes resources.

Let's install `kpt`:
```
curl -L https://github.com/GoogleContainerTools/kpt/releases/download/v1.0.0-beta.9/kpt_linux_amd64 --output kpt
chmod +x kpt
sudo mv kpt /usr/local/bin/kpt
```

We could now test locally our `Constraint` against our `Deployment` defined previously with the [`gatekeeper` function](https://catalog.kpt.dev/gatekeeper/v0.2/):
```
kpt fn eval --image gcr.io/kpt-fn/gatekeeper:v0.2 workdir/
```

The output will be:
```
[RUNNING] "gcr.io/kpt-fn/gatekeeper:v0.2"
[FAIL] "gcr.io/kpt-fn/gatekeeper:v0.2" in 21.2s
  Results:
    [ERROR] Containers must not run as root violatedConstraint: disallowroot in object "apps/v1/Deployment/nginx-deploy" in file "deployment.yaml"
  Stderr:
    "[error] apps/v1/Deployment/nginx-deploy : Containers must not run as root"
    "violatedConstraint: disallowroot"
    ""
  Exit code: 1
```

And voila, that's it! That's how easy it is. The idea is to have all the files needed in one place/folder: the Kubernetes manifests of your apps and both your `Constraint` and `ConstraintTemplate` files, as mutilple files or combined in one file.

## Integration with Config Sync

Now let's say you are using [Config Sync]({{< ref "/posts/2021/01/config-sync.md" >}}) to deploy your Kubernetes manifests on a GitOps way. In this case, we need to run a command to hydrate the Git repo with all the Kubernetes manifests.
```
nomos hydrate --flat --no-api-server-check --output workdir/hydrated-manifests.yaml
```

And then we could run the following command on this file:
```
kpt fn eval --image gcr.io/kpt-fn/gatekeeper:v0.2 workdir/
```

_Note: If you are enabling `templateLibraryInstalled` or `referentialRulesEnabled` when installing Policy Controller on your cluster, the `ConstraintTemplate` resources are in your cluster. If you have access to your cluster you may want to run this command `kubectl get constrainttemplates -o yaml` in order to grab the `ConstraintTemplate` manifest files. But if you don't have access to your cluster (which is the recommended approach if you are doing GitOps), you have to have those manifest files in your repository. That's what I'm doing with [my own setup in there](https://github.com/mathieu-benoit/my-kubernetes-deployments/tree/main/cluster/policies/templates)._

## Integration in CI pipelines

In your CI pipeline with GitHub actions, here is how it could look like:
```
- uses: google-github-actions/setup-gcloud
- name: install kpt and nomos	
  run: gcloud components install kpt nomos --quiet
- name: hydration	
  run: mkdir tmp && nomos hydrate --flat --no-api-server-check --output tmp/hydrated-manifests.yaml
- name: gatekeeper
  run: kpt fn eval --image gcr.io/kpt-fn/gatekeeper:v0.2 tmp/
```

In your CI pipeline with Cloud Build, here is how it could look like:
```
- id: hydration
  name: gcr.io/cloud-builders/gcloud
  entrypoint: 'bash'
  args:
  - '-eEuo'
  - 'pipefail'
  - '-c'
  - |
    mkdir tmp && nomos hydrate --flat --no-api-server-check --output tmp/hydrated-manifests.yaml
- id: gatekeeper
  name: gcr.io/cloud-builders/gcloud
  entrypoint: 'bash'
  args:
  - '-eEuo'
  - 'pipefail'
  - '-c'
  - |
    kpt fn eval --image gcr.io/kpt-fn/gatekeeper:v0.2 tmp/
```

The two resources below give other illustrations with Cloud Build:
- [Use Policy Controller in a CI pipeline](https://cloud.google.com/anthos-config-management/docs/tutorials/policy-agent-ci-pipeline)
- [Validate apps against company policies in a CI pipeline](https://cloud.google.com/anthos-config-management/docs/tutorials/app-policy-validation-ci-pipeline)

And voila, that's a wrap!

## Complementary and further resources

- [OPA Gatekeeper policies library](https://github.com/open-policy-agent/gatekeeper-library)
- [Constraint template library provided by Google](https://cloud.google.com/anthos-config-management/docs/reference/constraint-template-libraryhttps://cloud.google.com/anthos-config-management/docs/reference/constraint-template-library)
- [The kpt Book](https://kpt.dev/book/)
- [Creating policy-compliant Google Cloud resources](https://cloud.google.com/architecture/policy-compliant-resources)

Hope you enjoyed that one, stay safe out there! ;)