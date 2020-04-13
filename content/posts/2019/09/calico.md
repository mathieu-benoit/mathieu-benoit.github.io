---
title: kubernetes network policies, how to secure the communications between your pods
date: 2019-09-30
tags: [azure, containers, security, kubernetes]
description: let's secure the communications between your pods with calico kubernetes network policies
draft: true
---
On May 2019, [Network Policies on AKS was announced GA](https://azure.microsoft.com/updates/user-defined-network-policy-in-azure-kubernetes-service-aks-is-now-available/):

> _A user-defined network policy feature in AKS enables secure network segmentation within Kubernetes. This feature also allows cluster operators to control which pods can communicate with each other and with resources outside the cluster.
> Network policy is generally available through the Azure native policy plug-in or through the community project Calico._

I encourage you to give a read of this article too: [Integrating Azure CNI and Calico: A technical deep dive](https://azure.microsoft.com/blog/integrating-azure-cni-and-calico-a-technical-deep-dive/) where you will see all the concepts explained on a Networking perspective with AKS.
Furthermore here is the [Kubernetes tutorial](https://kubernetes.io/docs/tasks/administer-cluster/declare-network-policy/), the [Calico tutorial](https://docs.projectcalico.org/v3.9/security/calico-network-policy) and the [AKS tutorial](https://docs.microsoft.com/azure/aks/use-network-policies) you could give a try to practice with those concepts.

Some gotchas here:
- By default, any pods could communicate with any other pods across namespaces within a Kubernetes cluster, it's by design.
*   But [Kubernetes Network Policies](https://kubernetes.io/docs/concepts/services-networking/network-policies/) will guarantee the "Just Enough Access" principle of your Security posture
*   By default, there is no default plugin pre-installed with Kubernetes to actually apply such Network Policies
*   You need to install this plugin, otherwise your Network Policies won't have any effect.
*   With AKS, you have the option between azure or calico as your Network Policy plugin
*   You could only define this at the cluster creation, update is not yet supported
*   With calico you could either use kubenet or azure as your  CNI but for Azure CNI it's only with azure (not kubenet) as Network Policy plugin.
*   It's not yet supported for Windows nodes
*   Both azure and calico Network Policy plugin are open source:
*   `azure`: [https://github.com/Azure/azure-container-networking](https://github.com/Azure/azure-container-networking) 
*   `calico`: [https://github.com/projectcalico/calico](https://github.com/projectcalico/calico)
*   AKS currently, as we speak, supports Calico version 3.5.0

Because I love practicing while learning, here is a scenario where I was able to build 4 different Network Policies for this setup below:
*   WEB is exposed and accessible publicly from the Internet
*   WEB talks to API
*   API talks to DB
*   Not any other exposures nor communications, just this.

[![](https://github.com/mathieu-benoit/k8s-netpol/raw/master/db-api-web-deployments.png)](https://github.com/mathieu-benoit/k8s-netpol/raw/master/db-api-web-deployments.png)

Let's have a look to share with you my learnings there!

First we need to provision a cluster with Network Policies enabled, in my case I will go ahead with Calico:
```
az aks create **\--network-policy calico**

  

To start and illustrate this we need to deploy those Pods:

ns=yournamespace

kubectl create ns $ns  
kubectl config set-context --current --namespace $ns  
kubectl apply -f https://raw.githubusercontent.com/mathieu-benoit/k8s-netpol/master/db-api-web-deployments.yaml

  

You now have 3 Pods and 3 Services:

kubectl get pod,svc -n $ns

  
We could check that WEB is publicly accessible:  
curl $(kubectl get svc web -o jsonpath='{.status.loadBalancer.ingress\[0\].ip}')  
  

Our first test is to see that any pods could communicate with each others even externally, let's run few successful commands:

kubectl run curl-$RANDOM --image=radial/busyboxplus:curl --rm -it --generator=run-pod/v1

\# curl www.microsoft.com

\# curl http://db:15984  
\# exit

  

Let's apply the first Network Policy that should be for any namespace, [Deny all ingress and egress](https://orca.tufin.io/netpol/?yaml=apiVersion:%20networking.k8s.io%2Fv1%0Akind:%20NetworkPolicy%0Ametadata:%0A3name:%20deny-all%0Aspec:%0A3podSelector:%20%7B%7D%0A3policyTypes:%0A3-%20Ingress%0A3-%20Egress)!

kubectl apply -f https://raw.githubusercontent.com/mathieu-benoit/k8s-netpol/master/deny-all-netpol.yaml

  
We could check that WEB isn't anymore publicly accessible:  
curl \--connect-timeout 2 $(kubectl get svc web -o jsonpath='{.status.loadBalancer.ingress\[0\].ip}')  
  

Let's also re-run the two previous tests which should fail now:

kubectl run curl-$RANDOM --image=radial/busyboxplus:curl --rm -it --generator=run-pod/v1

\# curl --connect-timeout 2 www.microsoft.com

\# curl --connect-timeout 2 http://db:15984  
\# exit

  

Actually no one could communicate from/to that namespace at this stage, that's what we want. Now let's be more granular and illustrate the "Least Access" and "Just Enough Access" Security Principles.

  

First, we want [DB be accessible only from API on port 5984 and doesn't have access to anything](https://orca.tufin.io/netpol/?yaml=apiVersion:%20networking.k8s.io%2Fv1%0Akind:%20NetworkPolicy%0Ametadata:%0A3name:%20db-netpol%0Aspec:%0A3podSelector:%0A5matchLabels:%0A7app:%20db%0A3policyTypes:%0A3-%20Ingress%0A3ingress:%0A3-%20from:%0A5-%20podSelector:%0A9matchLabels:%0A11app:%20api%0A5ports:%0A6-%20port:%205984%0A8protocol:%20TCP):

kubectl apply -f https://raw.githubusercontent.com/mathieu-benoit/k8s-netpol/master/db-netpol.yaml

  

Let's validate that DB doesn't have access to anything:

kubectl run curl-$RANDOM --image=radial/busyboxplus:curl --labels **app=db** \--rm -it --generator=run-pod/v1 -n $ns

# curl \--connect-timeout 2 http://web:80  
# curl \--connect-timeout 2 www.microsoft.com  
\# exit

  

We now want [API having access only to DB on port 5984 and be accessible only from WEB on port 8080](https://orca.tufin.io/netpol/?yaml=apiVersion:%20networking.k8s.io%2Fv1%0Akind:%20NetworkPolicy%0Ametadata:%0A3name:%20api-netpol%0Aspec:%0A3podSelector:%0A5matchLabels:%0A7app:%20api%0A3policyTypes:%0A3-%20Ingress%0A3-%20Egress%0A3ingress:%0A3-%20from:%0A5-%20podSelector:%0A9matchLabels:%0A11app:%20web%0A5ports:%0A6-%20port:%203000%0A8protocol:%20TCP%0A3egress:%0A3-%20to:%0A5-%20podSelector:%0A9matchLabels:%0A11app:%20db%0A5ports:%0A6-%20port:%205984%0A8protocol:%20TCP%0A3-%20to:%0A5-%20namespaceSelector:%0A9matchLabels:%0A11name:%20kube-system%0A7podSelector:%0A9matchLabels:%0A11k8s-app:%20kube-dns%0A5ports:%0A6-%20port:%2053%0A8protocol:%20UDP):

kubectl apply -f https://raw.githubusercontent.com/mathieu-benoit/k8s-netpol/master/api-netpol.yaml

  

Actually we need also to do an extra action here by adding a Label on the kube-system Namespace (NetworkPolicies are all about Labels ;)):  
kubectl label ns kube-system name=kube-system  
  

Let's validate that API has access to DB but doesn't have access to WEB nor Internet:

kubectl run curl-$RANDOM --image=radial/busyboxplus:curl --labels **app=api** \--rm -it --generator=run-pod/v1

# curl http://db:15984  
# curl \--connect-timeout 2 http://web:80  
# curl \--connect-timeout 2 www.microsoft.com  
\# exit

  

And finally we want [WEB having access only to API on port 3000 and be accessible only from Internet on port 80](https://orca.tufin.io/netpol/?yaml=apiVersion:%20networking.k8s.io%2Fv1%0Akind:%20NetworkPolicy%0Ametadata:%0A3name:%20web-netpol%0Aspec:%0A3podSelector:%0A5matchLabels:%0A7app:%20web%0A3policyTypes:%0A3-%20Ingress%0A3-%20Egress%0A3ingress:%0A3-%20from:%20%5B%5D%0A5ports:%0A6-%20port:%2080%0A8protocol:%20TCP%0A3egress:%0A3-%20to:%0A5-%20podSelector:%0A9matchLabels:%0A11app:%20api%0A5ports:%0A6-%20port:%203000%0A8protocol:%20TCP%0A3-%20to:%0A5-%20namespaceSelector:%0A9matchLabels:%0A11name:%20kube-system%0A7podSelector:%0A9matchLabels:%0A11k8s-app:%20kube-dns%0A5ports:%0A6-%20port:%2053%0A8protocol:%20UDP):

kubectl apply -f https://raw.githubusercontent.com/mathieu-benoit/k8s-netpol/master/web-netpol.yaml

  

Let's validate that WEB has access to API but doesn't have access to DB or Internet:

kubectl run curl-$RANDOM --image=radial/busyboxplus:curl --labels **app=web** \--rm -it --generator=run-pod/v1

# curl http://api:8080  
# curl \--connect-timeout 2 www.microsoft.com  
# curl \--connect-timeout 2 http://db:15984  
\# exit

  
We could check that WEB is publicly accessible again:  
curl $(kubectl get svc web -o jsonpath='{.status.loadBalancer.ingress\[0\].ip}')  

Here you are! We have secured communications for our 3 Pods: WEB, API and DB by defining the very strict minimal requirements on that regard, nothing less and nothing more.

Some gotchas:
- It's all about Labels on Pods and Namespaces
- It's not about Services nor the ports exposed there, it's about Pods' ports
- You could use podSelector and namespaceSelector
- In one NetworkPolicy, you could combine multiple to: and multiple from:, therefore they will be applied as AND rules
- Again, the scope is per Namespace,  but via the namespaceSelector for Ingress or Egress you could reference external Namespaces
- You could use [GlobalNetworkPolicy with Calico](https://docs.projectcalico.org/v3.9/reference/resources/globalnetworkpolicy) to apply rules across Namespaces
- To be able to reach out to another Pod via its Service name exposure you need to add an Egress rule for the DNS resolver (with the label k8s-app=kube-dns) in the kube-system Namespace. We saw that we need to add a label name=kube-system on the kube-system Namespace.
- Network Policy Engine is doing the union of all the rules, Rule1 OR Rule2 OR...
- Default rules are for Ingress, as soon as you are adding Egress you need to specify this in the policyTypes: section

Resources:
- [Secure traffic between pods using network policies in Azure Kubernetes Service (AKS) | Azure Friday](https://www.youtube.com/watch?v=131_TIa_ftI)
- [Securing Cluster Networking with Network Policies - Ahmet Balkan, Google](https://www.youtube.com/watch?v=3gGpMmYeEO8)
- [https://github.com/ahmetb/kubernetes-network-policy-recipes](https://github.com/ahmetb/kubernetes-network-policy-recipes)
- [An Introduction to Kubernetes Network Policies for Security People](https://medium.com/@reuvenharrison/an-introduction-to-kubernetes-network-policies-for-security-people-ba92dd4c809d)
- [Kubernetes Network Policies Viewer](https://orca.tufin.io/netpol)

Hope you enjoyed this blog article and this learning process and hope you will be able to leverage this for your own context and needs.

Cheers!