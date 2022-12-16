---
title: windows containers with kubernetes 1.14
date: 2019-04-09
tags: [azure, containers, kubernetes]
description: let's see what does mean the graduation of the windows nodes support in k8s as stable
aliases:
    - /windows-k8s-nodes-ga/
---
_Update on April 28th, 2020: [Windows Nodes with Azure Kubernetes Service (AKS) is now GA](https://azure.microsoft.com/updates/windows-server-containers-in-aks-now-generally-available)! ;)_

On March 25th, 2019 [Kubernetes 1.14 went out](https://kubernetes.io/blog/2019/03/25/kubernetes-1-14-release-announcement)! And one of the big news with this new major version is the [Windows Server containers now supported and graduated as 'stable' in Kubernetes](https://kubernetes.io/blog/2019/03/25/kubernetes-1-14-release-announcement)!

> _With v1.14, we’re declaring that Windows node support is stable, well-tested, and ready for adoption in production scenarios. This is a huge milestone for many reasons. For Kubernetes, it strengthens its position in the industry, enabling a vast ecosystem of Windows-based applications to be deployed on the platform. For Windows operators and developers, this means they can use the same tools and processes to manage their Windows and Linux workloads, taking full advantage of the efficiencies of the cloud-native ecosystem powered by Kubernetes. [Let’s dig in a little bit into these](https://kubernetes.io/blog/2019/04/01/kubernetes-v1.14-delivers-production-level-support-for-windows-nodes-and-windows-containers/)._

Interesting to see the current [limitations](https://kubernetes.io/docs/setup/windows/intro-windows-in-kubernetes/#limitations) and the [what's coming](https://kubernetes.io/docs/setup/windows/intro-windows-in-kubernetes/#what-s-next) too.

_[Update - 2019-04-24 - The [What's new in Kubernetes 1.14? webinar](https://www.cncf.io/community/webinars/kubernetes-1-14-release/) is now available]_

Now, how to easily get started and deploy your first Kubernetes cluster with Windows Server Nodes? While Azure Kubernetes Service (AKS) doesn't support it yet _[Update - 2019-05-17 - [AKS supports it now in Public Preview](https://azure.microsoft.com/en-us/blog/announcing-the-preview-of-windows-server-containers-support-in-azure-kubernetes-service)! ;)]_, an easy way in Azure is to leverage AKS-Engine. To get started with AKS-Engine, you could follow this [quickstart guide](https://github.com/Azure/aks-engine/blob/master/docs/tutorials/quickstart.md). Furthermore, you could follow the information and instructions of this [Kubernetes Windows Walkthrough](https://github.com/Azure/aks-engine/blob/master/docs/topics/windows.md).

Let's do it! You could [choose one of the examples](https://github.com/Azure/aks-engine/tree/master/examples/windows). Or [download my example](https://github.com/mathieu-benoit/aksengine-agent/blob/master/example/kubernetes-win-vmss.json) for provisioning 1 Master Node (Linux) and 1 Agent Node (Windows) with Kubernetes 1.14. Then run this command:
```
aks-engine deploy -s $subscriptionId \
    --client-id '$clientId' \
    --client-secret '$clientSecret' \
    --dns-prefix $dnsPrefix \
    -l $location \
    --api-model kubernetes-win-vmss.json
```

Once your deployment is done, you could run this command below to get more information about the nodes actually deployed:
```
kubectl get nodes \
    -o wide \
    --kubeconfig output/kubeconfig/kubeconfig.$location.json  
NAME                    STATUS   ROLES    AGE     VERSION   INTERNAL-IP    EXTERNAL-IP   OS-IMAGE                    KERNEL-VERSION      CONTAINER-RUNTIME  
2405k8s00000000         Ready    agent    5h13m   v1.14.1   10.240.0.4     <none>        Windows Server Datacenter   10.0.17763.379      docker://18.9.2  
k8s-master-24055217-0   Ready    master   5h15m   v1.14.1   10.255.255.5   <none>        Ubuntu 16.04.6 LTS          4.15.0-1041-azure   docker://3.0.4  
```

Now let's deploy an IIS image and expose it via a LoadBalancer and a Public IP:
```
kubectl run iis \
    --image mcr.microsoft.com/windows/servercore/iis:windowsservercore-ltsc2019 \
    --port 80 \
    --kubeconfig output/kubeconfig/kubeconfig.$location.json  
kubectl expose deployment iis \
    --port 80 \
    --type LoadBalancer \
    --kubeconfig output/kubeconfig/kubeconfig.$location.json  
kubectl get all \
    --kubeconfig output/kubeconfig/kubeconfig.$location.json  
```

_Note: if you are using a Multiple Node Pools cluster, you will need to use `nodeAffinity` or `nodeSelector` while doing your `Deployment`._  
  
Then you will be able to enter the pod to do a validation: `kubectl exec -it <pod-name> -- cmd`.
  
Or you will be able to browse the Public IP:
```
curl http://$(kubectl get svc iis -o jsonpath="{.status.loadBalancer.ingress[*].ip}" --kubeconfig output/kubeconfig/kubeconfig.$location.json)
```

_Note: it won't work as expected for now with VMSS, [there is a known issue about that](https://github.com/Azure/aks-engine/issues/809). In my case it works because I'm using VMAS (AvailabilitySet) for the Agent Nodes._

If you would like to build your own Windows containers, feel free to leverage [Docker for Windows](https://docs.docker.com/docker-for-windows) locally, [Azure Container Registry Build task](https://docs.microsoft.com/azure/container-registry/container-registry-tasks-overview) (which supports Windows and Linux) or even [Azure DevOps with it Microsoft-hosted agents](https://docs.microsoft.com/azure/devops/pipelines/agents/hosted?view=azure-devops&tabs=yaml#use-a-microsoft-hosted-agent) supporting Windows Containers.

_Note: in the meantime Azure App Service [recently got an update with the support of Windows Server 2019 for its Windows Containers in Public Preview](https://azure.microsoft.com/blog/windows-server-2019-support-now-available-for-windows-containers-on-azure-app-service). We could learn for example:_

> _Windows Server Core 2019 LTSC base image is 4.28 GB compared to the Windows Server Core 2016 LTSC image is 11GB, which equates to a decrease of 61 percent!_

_[Update - 2019-05-06: [Azure Container Instances Windows Server 2019 container support is now in preview](https://azure.microsoft.com/updates/azure-container-instances-windows-server-2019-container-support-is-now-in-preview)]_

Resources:  
- [From Ops to DevOps with Windows Server containers and Windows Server 2019](https://myignite.techcommunity.microsoft.com/sessions/65919) at Ignite 2018
- [Getting started with Windows Server containers in Windows Server 2019](https://myignite.techcommunity.microsoft.com/sessions/65885) at Ignite 2018
- [Take the next step with Windows Server container orchestration](https://myignite.techcommunity.microsoft.com/sessions/65918) at Ignite 2018
- [Optimize Windows Dockerfiles](https://docs.microsoft.com/virtualization/windowscontainers/manage-docker/optimize-windows-dockerfile)
- [Kubernetes on Windows](https://docs.microsoft.com/virtualization/windowscontainers/kubernetes/getting-started-kubernetes-windows)
- You will also find few sessions about [Windows Containers at KubeCon Shanghai and Seattle 2018](https://alwaysupalwayson.blogspot.com/2018/11/microsoft-at-kubecon-cloudnativecon.html)
- [Docker on Windows workshop](http://stefanscherer.github.io/windows-docker-workshop)

Hope you enjoyed this blog article and you could leverage it for your own needs.

Cheers!