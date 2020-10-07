---
title: private aks and private acr, safer you are
date: 2020-03-27
tags: [azure, security, kubernetes, azure-devops]
description: let's setup azure private endpoint for both azure kubernetes service (aks) and azure container registry (acr)
aliases:
    - /private-aks-and-acr/
---
To continue improving your Security Posture with [Azure Private Endpoint like I demonstrated with Azure Blob Storage previously]({{< ref "/posts/2020/03/protect-terraform-state.md" >}}), let's now have a look at Azure Private Endpoint with Azure Kubernetes Service (AKS) and Azure Container Registry (ACR).  

Private AKS cluster just reached GA and private ACR has just been announced in Public Preview [among different PaaS service now supporting Azure Private Link](https://azure.microsoft.com/updates/privatelinkforpaasga/).  

Here is how the architecture of my AKS cluster looks like now:  

[![](https://github.com/mathieu-benoit/myakscluster/raw/master/myakscluster.png)](https://github.com/mathieu-benoit/myakscluster/raw/master/myakscluster.png)

To summarize what I have made:  
- [Private AKS](https://docs.microsoft.com/azure/aks/private-clusters) cluster in its own Subnet with Private Endpoint
- [Private ACR](https://docs.microsoft.com/azure/container-registry/container-registry-private-link) in its own Subnet with Private Endpoint
    - I put it in the same AKS's VNET, it's my choice, but it could be placed in another peered VNET as well.
- Jumpbox VM and Bastion in a VNET peered with the AKS's VNET
    - I create a VM with only a Private IP address and I create an Azure Bastion to allow the SSH connection from within the Azure portal.
- [Custom Azure pipelines agent]({{< ref "/posts/2020/02/custom-azure-pipelines-agent.md" >}}) hosted on AKS
    - With that I'm able to push both containers and Helm chart in ACR as well as deploying the Helm chart in AKS for any of my apps.
- [Private Azure Blob Storage Account]({{< ref "/posts/2020/03/protect-terraform-state.md" >}}) with Private Endpoint
    - Not illustrated on this image, but I am using this custom Azure pipelines agent described above to deploy Terraform for different workloads. In order to get access to this associated TF State file locked down in Blob Storage Account behind its Private Endpoint, I need to peer the AKS's VNET with the Blob Storage account's VNET.

If you are interested in seeing how I put all of this together, [here is the PR demonstrating how I have leveraged Private Link with my AKS and ACR](https://github.com/mathieu-benoit/myakscluster/pull/60).  

2 takeaways:  
- The [current documentation about Azure Private Link with ACR](https://docs.microsoft.com/azure/container-registry/container-registry-private-link) is missing the command avoiding public access to your ACR: `az acr update --default-action Deny`. It will be fixed soon by the Product Group team.
- Currently once you have setup Azure Private Link with ACR (and made it private), [the Azure Security Center Scanning (Qualys)](https://docs.microsoft.com/azure/security-center/azure-container-registry-integration) is not working yet.

You could see on the image above that I'm using also [Calico Network Policies]({{< ref "/posts/2019/09/calico.md" >}}), [Kured to patch my K8S nodes]({{< ref "/posts/2020/01/kured.md" >}}), but there is more to come for sure like the new features like [Azure Policy](https://docs.microsoft.com/azure/governance/policy/concepts/rego-for-aks) in Preview, [AAD integration v2](https://docs.microsoft.com/azure/aks/azure-ad-v2) in Preview,  [Managed Identities](https://docs.microsoft.com/azure/aks/use-managed-identity) in GA, etc. If you are looking for more best practices around security for your AKS cluster, I invite you to leverage this GitHub Repository in Work in Progress: [https://github.com/Azure/sg-aks-workshop](https://github.com/Azure/sg-aks-workshop).  

Hope you are enjoying those great news and updates to setup more securely your solution leveraging AKS!

Cheers!