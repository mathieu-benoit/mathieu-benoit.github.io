---
title: keda, event-driven containers for Kubernetes
date: 2019-06-09
tags: [azure, containers, kubernetes]
description: let's see what's keda what it is in action
---
[![](https://avatars3.githubusercontent.com/u/49917779?s=200&v=4)](https://avatars3.githubusercontent.com/u/49917779?s=200&v=4)

Recently during the Microsoft //build 2019 conference, [KEDA was announced as a component bringing event-driven containers and functions to Kubernetes](https://cloudblogs.microsoft.com/opensource/2019/05/06/announcing-keda-kubernetes-event-driven-autoscaling-containers).

> _KEDA allows for fine grained autoscaling (including to/from zero) for event driven Kubernetes workloads. KEDA serves as a Kubernetes Metrics Server and allows users to define autoscaling rules using a dedicated Kubernetes custom resource definition._

[![](https://1.bp.blogspot.com/-u2qV3-VC2xk/XPwHQzCBq9I/AAAAAAAATNE/4FFU3iiNPwEann60bkV0S95EM_ovFTZcQCLcBGAs/s640/Capture.PNG)](https://1.bp.blogspot.com/-u2qV3-VC2xk/XPwHQzCBq9I/AAAAAAAATNE/4FFU3iiNPwEann60bkV0S95EM_ovFTZcQCLcBGAs/s1600/Capture.PNG)

[You could find 6 samples](https://github.com/kedacore/keda) to get started:
- [JavaScript Azure Functions + Azure Queue](https://github.com/kedacore/sample-hello-world-azure-functions)
- [Go + RabbitMQ](https://github.com/kedacore/sample-go-rabbitmq)
- [Python Azure Functions + Kafka](https://github.com/kedacore/sample-python-kafka-azure-function)
- [TypeScript Azure Functions + Kafka](https://github.com/kedacore/sample-typescript-kafka-azure-function)
- [Azure Functions + Osiris](https://github.com/kedacore/keda/wiki/Using-Azure-Functions-with-Keda-and-Osiris)
- [Azure Functions + OpenShift 4](https://github.com/kedacore/keda/wiki/Using-Keda-and-Azure-Functions-on-Openshift-4)

I gave the [JavaScript Azure Functions + Azure Queue sample](https://github.com/kedacore/sample-hello-world-azure-functions) a try, I felt how easily I could host an Azure Functions triggered when an item is added in an Azure Queue and leverage Kubernetes resources to scale according to the load I need to process all items in the Queue.
I won't explain here how I did that since it's very straight forward by following the instructions of that sample. But here below are few different variants I did and tried:
```
# Only install keda and not osiris for the purpose of this Azure Queue (not HTTP) sample:  
func kubernetes install \
    --keda \
    --namespace keda  
# See all the k8s resources deployed by the previous command:  
kubectl get all,customresourcedefinition \
    -n keda  
  
# Deploy my hello-keda sample on a specific k8s namespace:  
func kubernetes deploy \
    --name hello-keda \
    --registry <your-docker-id> \
    --namespace hello-keda  
# See all the k8s resources deployed by the previous command:  
kubectl get all,ScaledObject,Secret \
    -n hello-keda  
  
# Watch the pods, deployments and hpas moving while adding items in the Azure Queue (you could even open 3 panes with [tmux](https://en.wikipedia.org/wiki/Tmux)):  
kubectl get pod -w  
kubectl get deploy -w  
kubectl get hpa -w  
  
# Build, tag and deploy a specific version and decoupling the build from the release:  
docker build . -t <your-docker-id>/hello-keda:1  
docker push <your-docker-id>/hello-keda:1  
func kubernetes deploy \
    --name hello-keda \
    --image-name <your-docker-id>/hello-keda:1  
```

I also learned few stuffs around the `AzureWebJobsStorage` setting/secret:
- It's the key and connectionstring to access the Azure Queue, we don't want it stored in the Docker image nor in the Git repo, right? That's where the .dockerignore and .gitignore play an important role. The .dockerignore exclude the copy of the local.settings.json file into our Docker image when building the Docker image, that's what we want, perfect!
- This AzureWebJobsStorage setting is stored as k8s Secret and then used but the k8s Deployment

Some gotchas:
- KEDA is a single modular component that is trying to do one thing well: provide event driven scale.  It has no dependencies and works with any Kubernetes cluster. 
- KEDA is directly looking at the event sources (for examples messages in an Azure Queue) and scale up pods  based on the outstanding "events" (for examples length of an Azure queue)
- KEDA doesn’t use the Azure Functions runtime. It is an independent component that can scale up any Kubernetes deployment based on events. If the Kubernetes deployment happens to target a Functions container then that will be scaled out. 
- There is some tooling in Azure Functions Core Tools (func kubernetes) to be able to easily deploy a Functions container which is scaled through KEDA but again the components are independent.
- [Osiris](https://github.com/deislabs/osiris) and [Virtual Kubelet](https://github.com/virtual-kubelet/virtual-kubelet) alongside with [HPA](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/) and KEDA look really promising by bringing the concept of Serverless containers on Kubernetes.

More resources:
- [KEDA project](https://github.com/kedacore/keda)
- [Azure webinar - Build Event-Driven Containers with Azure Functions on Kubernetes](https://info.microsoft.com/ww-ondemand-Build-Event-Driven-Containers-with-Azure-Functions-on-Kubernetes.html)
- [Microsoft //build 2019 - Serverless Kubernetes, KEDA, and Azure Functions](https://mybuild.techcommunity.microsoft.com/sessions/77799)
- [Microsoft //build 2019 - Where should I host my code? Choosing between Kubernetes, Containers, and Serverless](https://mybuild.techcommunity.microsoft.com/sessions/77338)

Hope you enjoyed this blog article and this new (and experimental for now) open source project bringing more capabilities and more workloads on/with k8s.

Cheers! ;)