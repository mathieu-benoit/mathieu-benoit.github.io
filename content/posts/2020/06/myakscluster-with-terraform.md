---
title: advanced aks cluster setup with terraform
date: 2020-06-22
tags: [azure, terraform, kubernetes, security]
description: let's see advanced terraform templates around my aks cluster setup
aliases:
    - /myakscluster-with-terraform/
---
Since I wrote my blog article [private aks and private acr, safer you are]({{< ref "/posts/2020/03/private-aks-and-acr.md" >}}), the associated GitHub repository documenting and scripting how I deploy my own AKS cluster got few notable improvements:
- [Managed Identity instead of Service Principal for AKS](https://github.com/mathieu-benoit/myakscluster/issues/62)
- [Optimize data collection with Azure Monitor for containers](https://github.com/mathieu-benoit/myakscluster/issues/61)
- Azure Bastion to access the Jumpbox VM (the latter not anymore exposed via a Public IP)
- [System Node pools](https://docs.microsoft.com/azure/aks/use-system-pools)
- Azure KeyVault to store Service Principals info to be reused later for CI/CD pipelines to deploy my containerized apps
- Azure Arc enabled Kubernetes to setup the AKS cluster config via GitOps

Among these updates made to [my Azure CLI script](https://github.com/mathieu-benoit/myakscluster#provisioning-option-1-azure-cli), I took the opportunity to [write the equivalent in Terraform](https://github.com/mathieu-benoit/myakscluster#provisioning-option-2-terraform). Since it's Infrastructure-as-Code as well as Documentation-as-Code, enjoy your walkthrough of the Terraform files ;)

I think Terraform files are easier (than bash script with Azure CLI) to write, maintain, read/understand, share and extend. Furthermore, you could re-run a new deployment/update with just the delta with the previous one. And destroying the entire infrastucture is just one line of code `terraform destroy`. Think about how you could do the two last scenarios with a bash script with Azure CLI with couple of `if... then... else` :)

Enjoy, cheers! ;)