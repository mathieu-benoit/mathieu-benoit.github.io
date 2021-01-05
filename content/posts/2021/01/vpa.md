---
title: vertical pod autoscaler
date: 2021-01-04
tags: [gcp, kubernetes]
description: let's discuss about the vertical pod autoscaler and how it could help setting your Kubernetes resources request and limits.
aliases:
    - /vpa/
---
With applications running on Kubernetes it's important to properly set the [CPU resources)[https://kubernetes.io/docs/tasks/configure-pod-container/assign-cpu-resource/] and [Memory resources](https://kubernetes.io/docs/tasks/configure-pod-container/assign-memory-resource/). But it could be hard to find and choose the proper values for `cpu` and `memory`. 

Using [monitoring tools with Kubernetes clusters]({{< ref "/posts/2020/08/cloud-operations-with-gke.md" >}}) for getting insights about the usage of `cpu` and `memory` of application could help. Complementary to this, `kubectl top pods` to get complementary insights. All of this on Production environment as well as running load tests to simulate more usage and stress on my application.

I recently discovered that [Vertical Pod Autoscaler](https://github.com/kubernetes/autoscaler/tree/master/vertical-pod-autoscaler) is better at it since that's its job.

> Resource request is a contract between your workload and the Kubernetes scheduler.
> Setting resource request and limit is hard, VPA is here to help.
> Observes usage, Recommends resources and Updates resources (if `Auto` mode).

{{< youtube id="Y4vnYaqhS74" title="Rightsize Your Pods with Vertical Pod Autoscaling - Beata Skiba, Google" >}}

Here is how easy it is to leverage [VPA on a GKE cluster](https://cloud.google.com/kubernetes-engine/docs/how-to/vertical-pod-autoscaling), first enable the VPA feature on it:
```
# For a new cluster
gcloud container clusters create --enable-vertical-pod-autoscaling

# For an existing cluster
gcloud container clusters update --enable-vertical-pod-autoscaling
```

Then deploy a VPA resource for your specific application:
```
apiVersion: autoscaling.k8s.io/v1
kind: VerticalPodAutoscaler
metadata:
  name: myblog
spec:
  targetRef:
    apiVersion: "apps/v1"
    kind: Deployment
    name: myblog
  updatePolicy:
    updateMode: "Off"
```

And finally, after some time and load tests with your applications, you could discover those metrics by running `kubectl describe vpa myblog`:
```
...
Recommendation:
    Container Recommendations:
      Container Name:  myblog
      Lower Bound:
        Cpu:     3m
        Memory:  4194304
      Target:
        Cpu:     6m
        Memory:  5242880
      Uncapped Target:
        Cpu:     6m
        Memory:  5242880
      Upper Bound:
        Cpu:     6m
        Memory:  5242880
...
```

In this illustration, I'm using the `updateMode: "Off"`, with that I need to manually apply those numbers on my `Deployment` manifest. `Lower Bound` could be used to set the `requests` numbers (but you may want to use `Target` to be more conservative). `Upper Bound` could be used to set the `limits` numbers. So with the numbers gotten above, here is what the `Deployment` manifest will look like to represent them:
```
...
          resources:
            requests:
              cpu: 3m
              memory: 4Mi
            limits:
              cpu: 6m
              memory: 5Mi
...
```

_Note: those numbers could be applied automatically and continuously if you are using `updateMode: "Auto"` instead. There is also [some known limitations with VPA](https://cloud.google.com/kubernetes-engine/docs/concepts/verticalpodautoscaler#limitations_for_vertical_pod_autoscaling) to be aware of._

Complementary and further resources:
- [VPA on GKE](https://cloud.google.com/kubernetes-engine/docs/concepts/verticalpodautoscaler)
- [Autoscaling with GKE: Overview and pods](https://youtu.be/7naCIxIaV1M)
- [Best practices for running cost-optimized Kubernetes applications on GKE](https://cloud.google.com/solutions/best-practices-for-running-cost-effective-kubernetes-applications-on-gke#vertical_pod_autoscaler)
- [Kubernetes Autoscaling 101: Cluster Autoscaler, Horizontal Autoscaler, and Vertical Pod Autoscaler](https://www.cncf.io/blog/2019/10/29/kubernetes-autoscaling-101-cluster-autoscaler-horizontal-autoscaler-and-vertical-pod-autoscaler/)

Hope you enjoyed that blog article and that you are now more equiped to properly set your Kubernetes resources request and limits for your own applications.

Cheers! ;)