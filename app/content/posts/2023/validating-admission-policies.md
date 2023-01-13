---
title: validating admission policies, the future of kubernetes policies
date: 2023-01-12
tags: [gcp, kubernetes, security]
description: let's see how to use the new validating admission policies feature in kubernetes 1.26+ and what it brings for the future of kubernetes policies
aliases:
    - /validating-admission-policies/
---
Kubernetes 1.26 just introduced an alpha feature: [Validating Admission Policies](https://kubernetes.io/blog/2022/12/20/validating-admission-policies-alpha/).

> Validating admission policies use the [Common Expression Language (CEL)](https://github.com/google/cel-spec) to offer a declarative, in-process alternative to validating admission webhooks.

> CEL was first introduced to Kubernetes for the Validation rules for CustomResourceDefinitions. This [enhancement](https://github.com/kubernetes/enhancements/blob/master/keps/sig-api-machinery/3488-cel-admission-control/README.md) expands the use of CEL in Kubernetes to support a far wider range of admission use cases.

> Admission webhooks can be burdensome to develop and operate. Webhook developers must implement and maintain a webhook binary to handle admission requests. Also, admission webhooks are complex to operate. Each webhook must be deployed, monitored and have a well defined upgrade and rollback plan. To make matters worse, if a webhook times out or becomes unavailable, the Kubernetes control plane can become unavailable.

> This enhancement avoids much of this complexity of admission webhooks by embedding CEL expressions into Kubernetes resources instead of calling out to a remote webhook binary.

If you want to learn more about this feature and where it's coming from, I encourage you to watch [Joe Betz's session at KubeCon NA 2022](https://sched.co/182Q6), I found it very insightful:

{{< youtube id="gJWMvsC7Mzo" title="Webhook Fatigue? You're Not Alone: Introducing the CEL Expression Language Features Solving This Problem">}}

In this blog article, let's see in actions how we could leverage this new Validating Admission Policies feature. Based on my knowledge with Gatekeeper policies, I will also try to add some comments about what could be the missing features based on my own experience.

Here is what will be accomplished throughout this blog article:
- [Create a GKE cluster with the Validating Admission Policies alpha feature](#create-a-gke-cluster-with-the-validating-admission-policies-alpha-feature)
- [Create a simple policy with max of 3 replicas for any `Deployments`](##create-a-simple-policy-with-max-of-3-replicas-for-any-deployments)
- [Pass parameters to a policy](#pass-parameters-to-a-policy)
- [Exclude namespaces from a policy](#exclude-namespaces-from-a-policy)
- [Limitations, gaps and thoughts](#limitations-gaps-and-thoughts)
- [Conclusion](#conclusion)

_Note: while testing this feature by leveraging its associated [blog](https://kubernetes.io/blog/2022/12/20/validating-admission-policies-alpha/) and [doc](https://kubernetes.io/docs/reference/access-authn-authz/validating-admission-policy/), it was also the opportunity for me to open my first PRs in the `kubernetes/website` repo to fix some frictions I faced: https://github.com/kubernetes/website/pull/38893 and https://github.com/kubernetes/website/pull/38908._

## Create a GKE cluster with the Validating Admission Policies alpha feature

GKE just got the [version 1.26 available](https://cloud.google.com/kubernetes-engine/docs/release-notes-rapid#January_05_2023), we could check the versions available by running this command `gcloud container get-server-config --zone us-central1-c`.

Let's provision a [cluster in `alpha` mode (not for production)](https://cloud.google.com/kubernetes-engine/docs/how-to/creating-an-alpha-cluster) with the version 1.26:
```bash
gcloud container clusters create cel-admission-control-cluster \
    --enable-kubernetes-alpha \
    --no-enable-autorepair \
    --no-enable-autoupgrade \
    --release-channel rapid \
    --cluster-version 1.26.0-gke.1500 \
    --zone us-central1-c
```

Once the cluster provisioned, we can check that the Validating Admission Policies alpha feature is availabe with the two associated resources [`ValidatingAdmissionPolicy`](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.26/#validatingadmissionpolicy-v1alpha1-admissionregistration-k8s-io) and [`ValidatingAdmissionPolicyBinding`](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.26/#validatingadmissionpolicybinding-v1alpha1-admissionregistration-k8s-io), `kubectl api-resources | grep ValidatingAdmissionPolicy`:
```plaintext
validatingadmissionpolicies                      admissionregistration.k8s.io/v1alpha1   false        ValidatingAdmissionPolicy
validatingadmissionpolicybindings                admissionregistration.k8s.io/v1alpha1   false        ValidatingAdmissionPolicyBinding
```

Before jumping in creating and testing the policies, let's deploy a sample app in our cluster that we could leverage later in this blog:
```bash
kubectl create ns sample-app
kubectl create deployment sample-app --image=nginx --replicas 5 -n sample-app
```

## Create a simple policy with max of 3 replicas for any `Deployments`

Let's do it, let's deploy our first policy!

This policy is composed by one `ValidatingAdmissionPolicy` defining the validation with the CEL expression and one `ValidatingAdmissionPolicyBinding` binding the policy to the appropriate resources in the cluster:
```bash
cat << EOF | kubectl apply -f -
apiVersion: admissionregistration.k8s.io/v1alpha1
kind: ValidatingAdmissionPolicy
metadata:
  name: max-replicas-deployments
spec:
  failurePolicy: Fail
  matchConstraints:
    resourceRules:
    - apiGroups:   ["apps"]
      apiVersions: ["v1"]
      operations:  ["CREATE", "UPDATE"]
      resources:   ["deployments"]
  validations:
    - expression: "object.spec.replicas <= 3"
EOF
cat << EOF | kubectl apply -f -
apiVersion: admissionregistration.k8s.io/v1alpha1
kind: ValidatingAdmissionPolicyBinding
metadata:
  name: max-replicas-deployments
spec:
  policyName: max-replicas-deployments
EOF
```

Now, let's try to deploy an app with 5 replicas:
```bash
kubectl create deployment nginx --image=nginx --replicas 5
```
We can see that our policy is enforced, great!
```plaintext
error: failed to create deployment: deployments.apps "nginx" is forbidden: ValidatingAdmissionPolicy 'max-replicas-deployments' with binding 'max-replicas-deployments' denied request: failed expression: object.spec.replicas <= 3
```

So that's for new admission requests, but what about our existing app we previously deployed? Interestingly, there is nothing telling me that my existing resources are not compliant, I'm a bit disappointed here, I used to do `kubectl get constraints` and see the violations raised by Gatekeeper. I think that's a miss here, let's see if in the future it will be supported. Nonetheless, `kubectl rollout restart deployments sample-app -n sample-app` or `kubectl scale deployment sample-app --replicas 6 -n sample-app` for example will fail, like expected.

## Pass parameters to a policy

With the policy we just created we hard-coded the number of replicas we allow, but what if you want to have this more customizable? Here comes a really interesting feature where you can pass parameters!

The `paramKind` field allows you to pass an existing CRD that you could [create by yourself](https://kubernetes.io/docs/tasks/extend-kubernetes/custom-resources/custom-resource-definitions/) or you can easily leverage existing ones like `ConfigMap` or `Secrets`. Let's update our policy with a `ConfigMap` to achieve this:
```bash
cat << EOF | kubectl apply -f -
apiVersion: admissionregistration.k8s.io/v1alpha1
kind: ValidatingAdmissionPolicy
metadata:
  name: max-replicas-deployments
spec:
  failurePolicy: Fail
  paramKind:
    apiVersion: v1
    kind: ConfigMap
  matchConstraints:
    resourceRules:
    - apiGroups:   ["apps"]
      apiVersions: ["v1"]
      operations:  ["CREATE", "UPDATE"]
      resources:   ["deployments"]
  validations:
  - expression: "params != null"
    message: "params missing but required to bind to this policy"
  - expression: "has(params.data.maxReplicas)"
    message: "params.data.maxReplicas missing but required to bind to this policy"
  - expression: "object.spec.replicas <= int(params.data.maxReplicas)"
EOF
kubectl create ns policies-configs
cat << EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: max-replicas-deployments
  namespace: policies-configs
data:
  maxReplicas: "3"
EOF
cat << EOF | kubectl apply -f -
apiVersion: admissionregistration.k8s.io/v1alpha1
kind: ValidatingAdmissionPolicyBinding
metadata:
  name: max-replicas-deployments
spec:
  paramRef:
    name: max-replicas-deployments
    namespace: policies-configs
  policyName: max-replicas-deployments
EOF
```
_Note: because `ConfigMap` has to reside in a namespace, we are also creating a dedicated `policies-configs` namespace._

Now, let's try to deploy an app with 5 replicas:
```bash
kubectl create deployment nginx --image=nginx --replicas 5
```
We can see that our policy is still enforced with a new message, great!
```plaintext
error: failed to create deployment: deployments.apps "nginx" is forbidden: ValidatingAdmissionPolicy 'max-replicas-deployments' with binding 'max-replicas-deployments' denied request: failed expression: object.spec.replicas <= int(params.data.maxReplicas)
```

## Exclude namespaces from a policy

One of the features used with Gatekeeper policies is the ability to `excludedNamespaces` with a `Constraint`. Very helpful to avoid breaking clusters with policies on system namespaces.

Here, we will use a `namespaceSelector` on our `ValidatingAdmissionPolicyBinding` to exclude system namespaces as well as our own `allow-listed` namespace:
```bash
cat << EOF | kubectl apply -f -
apiVersion: admissionregistration.k8s.io/v1alpha1
kind: ValidatingAdmissionPolicyBinding
metadata:
  name: max-replicas-deployments
spec:
  paramRef:
    name: max-replicas-deployments
    namespace: policies-configs
  policyName: max-replicas-deployments
  matchResources:
    namespaceSelector:
      matchExpressions:
      - key: kubernetes.io/metadata.name
        operator: NotIn
        values:
        - kube-node-lease
        - kube-public
        - kube-system
        - allow-listed
EOF
```
_Note: in order to have this `namespaceSelector` expression working, we are assuming that we are in a Kubernetes cluster version 1.22+ which [automatically adds the `kubernetes.io/metadata.name` label](https://kubernetes.io/docs/concepts/overview/working-with-objects/namespaces/#automatic-labelling) on any `Namespaces`. Very convenient for our use case to exclude namespaces from a policy_

Now, let's try to deploy an app with 5 replicas in the default namespace:
```bash
kubectl create deployment nginx --image=nginx --replicas 5
```

We can see that our policy is still enforced, great!
```plaintext
error: failed to create deployment: deployments.apps "nginx" is forbidden: ValidatingAdmissionPolicy 'max-replicas-deployments' with binding 'max-replicas-deployments' denied request: failed expression: object.spec.replicas <= int(params.data.maxReplicas)
```

On the other hand, we should be able to deploy it in the `allow-listed` namespace:
```bash
kubectl create ns allow-listed
kubectl create deployment nginx --image=nginx --replicas 5 -n allow-listed
```

Sweet!

## Limitations, gaps and thoughts

Again, based on my Gatekeeper experience and the quick tests that I have done so far with this Validation Admission Policies feature, here are some limitations, gaps and thoughts that I'm seeing:

### Failure policy `Ignore`

I don't seem to understand yet what this failure policy `Ignore` as opposed to `Fail` does. I get the same behavior with both...

### Just for admission

It's just for admission, not for evaluating existing resources already in a cluster.

### Client-side validation

Not able to evaluate the resources against policies outside of a cluster, like we can do with the `gator` cli.

### Inline parameters

Inline parameters in `ValidatingAdmissionPolicyBinding` would be way more easier, today we need to create our own CRD or have resources like `ConfigMap`, `Secrets`, etc. which are scoped in a namespace.

### Variables's values in message

Evaluate values in `validation.message` like `"object.spec.replicas should be less than {int(params.data.maxReplicas)}"`

### Cluster-wide exempted namespaces

Repeating the `namespaceSelector` expression for all the `ValidatingAdmissionPolicyBinding` could generate more work and errors, [exempting namespaces cluster-wide](https://open-policy-agent.github.io/gatekeeper/website/docs/exempt-namespaces/) would be really great.

### Mutating

Mutating doesn't exist.

### External data

Advanced scenario like leveraging `cosign` with Gatekeeper's External data feature doesn't exist.

### Referential constraints

Advanced scenario where I want a policy making sure that any `Namespace` has a `NetworkPolicy` or an `AuthorizationPolicy`, based on referential constraints with Gatekeeper could be really helpful. It doesn't seem to be supported today.

I will test it soon, but I'm thinking about passing the associated CRD (`NetworkPolicy` and `Authorization`) as `paramKind` while evaluating `Pods` creation/update (I thought about `Namespace` but there is a chicken and eggs problem here). I will report back upading this blog article as soon as I made my tests. Stay tuned!

### Workload resources

Policies on `Pods` are important but could be tricky with the workload resources generating them, think about `Deployments`, `ReplicaSet`, `Jobs`, `Daemonsets`, etc. I haven't tested it yet, I will report back upading this blog article as soon as I made my tests. Stay tuned!

## Conclusion

We were able to create our own policy, pass a parameter to it and exclude some namespaces. Finally, some limitations and gaps with Gatekeeper policies were discussed.

This feature in alpha since Kubernetes 1.26 is really promising, very easy to leverage and already powerful. I really like the fact that it's also out of the box in Kubernetes and that it's a very light footprint in my cluster as opposed to have others CRDs/containers in my cluster like we have with Gatekeeper or Kyverno.

I think this image below taken from [Joe Betz's session at KubeCon NA 2022](https://sched.co/182Q6) is a good summary about the positioning of this feature versus the advanced scenarios covered by webhooks:

![ValidatingAdmissionPolicies versus Webhooks](https://github.com/mathieu-benoit/my-images/raw/main/validatingadmissionpolicies-versus-webhooks.png)

I'm really looking forward to seeing the next iterations on this feature as it will reach `beta` and then `stable` states in the future. I'm also curious to learn more about when to use it and maybe still using Gatekeeper if I need more advanced scenarios like illustrated in the previous [Limitations, gaps and thoughts section](#limitations-gaps-and-thoughts). Finally, I'm curious also to learn more about how Gatekeeper, [Kyverno](https://github.com/kyverno/kyverno/issues/5441), Styra, etc. will position their projects and products based on this feature upstream in Kubernetes.

Happy sailing, cheers!