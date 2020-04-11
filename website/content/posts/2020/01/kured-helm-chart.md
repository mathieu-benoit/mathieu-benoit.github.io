---
title: flexible kured deployment with its helm chart, schedule, microsoft teams or slack notifications, etc.
date: 2020-01-10
tags: [azure, containers, kubernetes, security, helm]
description: let's have a look at podman, a daemonless container engine
---
[![](https://raw.githubusercontent.com/weaveworks/kured/master/img/logo.png)](https://raw.githubusercontent.com/weaveworks/kured/master/img/logo.png)

Kured (KUbernetes REboot Daemon) is the proper way to keep your Linux Nodes up-to-date automatically with Kubernetes: [https://docs.microsoft.com/azure/aks/node-updates-kured](https://docs.microsoft.com/en-us/azure/aks/node-updates-kured). That's one of your responsibility to setup this tool (or any other alternative you may have) for your own Security Posture.

I recently found out that the proper way to install kured is not by doing this like explained [here](https://github.com/weaveworks/kured#installation):
```
kubectl apply \
    -f https://github.com/weaveworks/kured/releases/download/1.2.0/kured-1.2.0-dockerhub.yaml
```

Yes it works like this for sure. But, how updating that file? how extending it? So [I recently found out](https://github.com/weaveworks/kured/issues/95#issuecomment-551066232) that instead of keeping my own version of this file and update it as I want, I could use the [official Kured Helm chart](https://hub.helm.sh/charts/stable/kured) instead:
```
helm repo update
helm install kured stable/kured
```

Really cool, isn't it!?

_FYI the source code of this Helm chart is here: [https://github.com/helm/charts/tree/master/stable/kured](https://github.com/helm/charts/tree/master/stable/kured)_

Maybe you don't see yet the value of using this Helm chart? Here below are few scenarios and capabilities you are now easily able to do with this Helm chart installation.

# Deploy kured in a specific namespace

It's not a good practice to deploy kured in the `kube-system` namespace, that's what the original file does. _Note: [Azure Security Center integrated with AKS](https://docs.microsoft.com/azure/security-center/azure-kubernetes-service-integration) told me that._

```
kubectl create ns kured
helm install kured stable/kured \
    -n kured
```

# Deploy kured only on Linux nodes

Because it's not working for Windows nodes: [https://github.com/weaveworks/kured/issues/96](https://github.com/weaveworks/kured/issues/96).
```
helm install kured stable/kured \
    --set nodeSelector."beta\.kubernetes\.io/os"=linux
```

# Deploy kured with specific tolerations

Otherwise it will fail if you taint your nodes: [https://github.com/weaveworks/kured/pull/88](https://github.com/weaveworks/kured/pull/88). That's probably what you will find out [as soon as you will leverage Multiple Node Pool for example](https://docs.microsoft.com/azure/aks/use-multiple-node-pools#schedule-pods-using-taints-and-tolerations).
```
helm install kured stable/kured \
    --set tolerations[0].effect=NoSchedule \
    --set tolerations[0].key=node-role.kubernetes.io/master \
    --set tolerations[1].operator=Exists \
    --set tolerations[1].key=CriticalAddonsOnly \
    --set tolerations[2].operator=Exists \
    --set tolerations[2].effect=NoExecute \
    --set tolerations[3].operator=Exists \
    --set tolerations[3].effect=NoSchedule
```

# Deploy a specific version of the kured container

You may want to deploy a [specific tag of the kured container](https://hub.docker.com/r/weaveworks/kured/tags), for example when it's [not yet officially released](https://github.com/weaveworks/kured/releases).
```
helm install kured stable/kured \
    --set image.tag=master-f6e4062
```

# Get notifications in Slack or Microsoft Teams

You may want to receive notifications when nodes are drained and rebooted. With Microsoft Teams you could [get Incoming Webhook URL very easily](https://docs.microsoft.com/microsoftteams/platform/webhooks-and-connectors/how-to/connectors-using#setting-up-a-custom-incoming-webhook) to use it then with the following command:
```
helm install kured stable/kured \
    --set extraArgs.slack-hook-url=<your-webhook-url>
```

[![](https://1.bp.blogspot.com/-wOWxotvcloI/Xhe6wz0N7TI/AAAAAAAAUms/FGg7nwSMNOg1Uj_g-4j6bpi1n4c9TSU_wCLcBGAsYHQ/s1600/Capture.PNG)](https://1.bp.blogspot.com/-wOWxotvcloI/Xhe6wz0N7TI/AAAAAAAAUms/FGg7nwSMNOg1Uj_g-4j6bpi1n4c9TSU_wCLcBGAsYHQ/s1600/Capture.PNG)

# Set a schedule when kured should reboot the nodes

You may want to [set a specific schedule (days and times)](https://github.com/weaveworks/kured#setting-a-schedule) when kured should reboot the nodes when needed. This feature is [only available from a specific version](https://github.com/weaveworks/kured/pull/66#issuecomment-549486983) of the kured container and further versions.
```
helm install kured stable/kured \
    --set image.tag=master-f6e4062 \
    --set extraArgs.start-time=9am \
    --set extraArgs.end-time=5pm \
    --set extraArgs.time-zone=America/Toronto \
    --set extraArgs.reboot-days="mon\,tue\,wed\,thu\,fri"
```

# That's a wrap!

With all of this, here is my final command I use to deploy kured with its Helm chart in my own Kubernetes cluster:
```
ns=kured  
teamsWebHook=<teams-web-hook>  
kubectl create ns $ns  
helm repo update  
helm install kured stable/kured \  
    -n $ns \
    --set image.tag=master-f6e4062 \
    --set nodeSelector."beta\.kubernetes\.io/os"=linux \
    --set extraArgs.start-time=9am \
    --set extraArgs.end-time=5pm \
    --set extraArgs.time-zone=America/Toronto \
    --set extraArgs.reboot-days="mon\,tue\,wed\,thu\,fri" \
    --set tolerations[0].effect=NoSchedule \
    --set tolerations[0].key=node-role.kubernetes.io/master \
    --set tolerations[1].operator=Exists \
    --set tolerations[1].key=CriticalAddonsOnly \
    --set tolerations[2].operator=Exists \
    --set tolerations[2].effect=NoExecute \
    --set tolerations[3].operator=Exists \
    --set tolerations[3].effect=NoSchedule \
    --set extraArgs.slack-hook-url=$teamsWebHook
```

_NB: I submitted a [PR to improve the AKS docs with this](https://github.com/MicrosoftDocs/azure-docs/issues/45912)._

Hope you enjoyed this blog article and you learned enough to adapt this for your own context and needs.

Cheers!