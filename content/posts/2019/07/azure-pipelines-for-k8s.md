---
title: ci/cd pipeline with azure devops to deploy any apps on kubernetes
date: 2019-07-10
tags: [azure, azure-devops, kubernetes, containers]
description: let's build and deploy a containerized app in kubernetes via azure pipelines
aliases:
    - /azure-pipelines-for-k8s/
---
Back in October 1st 2018, I published [Azure DevOps to deploy your apps/services into a Kubernetes cluster](https://alwaysupalwayson.blogspot.com/2018/10/azure-devops-to-deploy-your.html), then I updated it on October 12th 2018 with [Helm charts repository with Azure Container Registry](https://alwaysupalwayson.blogspot.com/2018/10/helm-charts-repository-with-azure.html), to finally published on November 27th 2018 a more generic and professional one in the official Microsoft Open Source blog: [Tutorial: Using Azure DevOps to setup a CI/CD pipeline and deploy to Kubernetes](https://cloudblogs.microsoft.com/opensource/2018/11/27/tutorial-azure-devops-setup-cicd-pipeline-kubernetes-docker-helm).

I got great feedback from customers and colleagues which brought to my attention few ideas of improvements.

Today, I would like to walk you through 4 improvements I have made:
1.  Helm chart versioning improvement
2.  Specific Service Principal to deploy apps in AKS
3.  YAML definition for both the Build and the Release pipelines
4.  Azure Key Vault to store and retrieve secrets throughout the CI/CD pipeline

The workflow is now:

![Architecture diagram showing the worklflow of the different steps and components such as Source repository, to the build, to the release into AKS going through the container registry.](https://1.bp.blogspot.com/-ahnbFR-xLbc/XQrcr5v5oII/AAAAAAAATO0/Eqmr-lefZx4uf_Bhwz7z2bhVDzaKd97MACLcBGAs/s640/Picture2.png)

# 1. Helm chart versioning improvement

Again I got great feedback from my original blog article, here is the story about how I have improved the Helm chart versioning: [Helm chart management in CI/CD with ACR and Azure DevOps]({{< ref "/posts/2019/07/ci-cd-with-helm-chart.md" >}}).

# 2. Specific Service Principal to deploy apps in AKS

From Azure DevOps pipelines we need to get access to the AKS cluster to be able then to deploy our Helm chart. Typically we will get the kubeconfig file to be able to run the helm upgrade command. To do so we will need to do az login and then az aks get-credendials.
Furthermore, we would like to respect the Least privilege Security Principle [by restricting the role and scope of the associated Service Principal](https://docs.microsoft.com/azure/aks/control-kubeconfig-access). Here is how you will achieve that:
```
aksSpSecret=$(az ad sp create-for-rbac -n aks-sp --skip-assignment --query password -o tsv)  
aksSpId=$(az ad sp show --id http://aks-sp --query appId -o tsv)  
aks=_<your-aks-cluster-name>_  
aksId=$(az aks show -g $aks -n $aks --query id)  
az role assignment create --assignee $aksSpId --role "Azure Kubernetes Service Cluster User Role" --scope aksId  
aksSpTenantId=$(az account show --query tenantId -o tsv)  
```
We will use those values later.

_Note: previously we were using a Kubernetes Service Endpoint which typically allows you to provide the kubeconfig or create for you a Service Principal but Contributor on a specific Resource Group or at the Subscription level._

# 3. YAML definition for both the Build and the Release pipelines

[Since Multi-Stage pipeline is supported with the YAML definition](https://devblogs.microsoft.com/devops/whats-new-with-azure-pipelines/) we could now integrate our Release definition and our Build definition with our Azure pipeline.
On that regard, we will have 3 files:
- [azure-pipelines.yml](https://github.com/Azure/phippyandfriends/blob/mathieu-benoit/azure-pipelines/phippy/azure-pipelines.yml), which will define the entire CI/CD pipeline with 3 Stages: Build, Development and Production
- [build-steps-template.yml](https://github.com/Azure/phippyandfriends/blob/mathieu-benoit/azure-pipelines/common/build-steps-template.yml), acting as the template for the Build steps (CI)
- [stage-steps-template.yml](https://github.com/Azure/phippyandfriends/blob/mathieu-benoit/azure-pipelines/common/stage-steps-template.yml), acting as the template for the Release steps (CD - Development and Production)

![Screenshot of the summary of successfull run of an Azure Pipeline showing the 3 stages: Build, Development and Production.](https://1.bp.blogspot.com/-4StA1t_kQCA/XR6j-7ybn4I/AAAAAAAATUA/eP0yN6k4R80l_p3aeT3-EiHTk0sp37J5gCLcBGAs/s640/Capture.PNG)

TIPS: you could leverage the [Azure DevOps CLI](https://devblogs.microsoft.com/devops/using-azure-devops-from-the-command-line) to create your Azure pipeline definition based on this YAML file: `az pipelines create --yml-path`.
_Note: There is currently a limitation with Azure pipeline with YAML definition where we don't have yet the ability to use Gates or Pre-Condition for each Stage, [but it's coming](https://dev.azure.com/mseng/AzureDevOpsRoadmap/_workitems/edit/1510336)! As a workaround currently, I'm using a boolean variable deployToProduction [as a condition for the Production Stage](https://github.com/Azure/phippyandfriends/blob/mathieu-benoit/azure-pipelines/phippy/cicd/azure-pipelines.yml#L51)._

# 4. Azure Key Vault to store and retrieve the secrets

Here the goal is to store secrets needed throughout the CI/CD pipeline in Azure Key Vault to be more secure.
```
rg=<your-rg>
kv=<your-kv>
subscriptionId=$(az account show --query id -o tsv)
tenantId=$(az account show --query tenantId -o tsv)

# Create an Azure Key Vault instance
az group create -n $rg -l $location
az keyvault create -l $location -n $kv -g $rg
  
# Create a Service Principal which will be able to read the secrets from that specific Azure Key Vault
kvSpSecret=$(az ad sp create-for-rbac -n $kv --skip-assignment --query password -o tsv)
kvSpId=$(az ad sp show --id http://$kv --query appId -o tsv)
kvId=$(az keyvault show -n $kv --query id -o tsv)
az role assignment create --assignee $kvSpId --role Reader --scope $kvId
  
# Add the specific policies to this Service Principal  
az keyvault set-policy -n $kv --spn $kvSpId --secret-permissions get list
```

TIPS: you could leverage the [Azure DevOps CLI](https://devblogs.microsoft.com/devops/using-azure-devops-from-the-command-line) to create your Service Endpoint based on this specific Service Principal created for your Azure Key Vault:
```
az devops service-endpoint create \
    --authorization-scheme ServicePrincipal \
    --service-endpoint-type azurerm \
    --azure-rm-service-principal-id $kvSpId \
    --azure-rm-subscription-id $subscriptionId \
    --azure-rm-tenant-id $tenantId
  
# Now let's add our secrets into our Azure Key Vault for our Development Environment (for other Environments like Production, you could repeat the exact same way accordingly)  
az keyvault secret set --vault-name $kv -n dev-aksSpTenantId --value $tenantId  
az keyvault secret set --vault-name $kv -n dev-aksSpId --value $aksSpId  
az keyvault secret set --vault-name $kv -n dev-aksSpSecret --value $aksSpSecret  
```
Note: You could also store your Azure Container Registry login and password (see the [original blog article](https://cloudblogs.microsoft.com/opensource/2018/11/27/tutorial-azure-devops-setup-cicd-pipeline-kubernetes-docker-helm) to see how to get them).

From there, you could now create a [Variable Group in Azure DevOps linked to this Azure Key Vault](https://docs.microsoft.com/azure/devops/pipelines/library/variable-groups#link-secrets-from-an-azure-key-vault) by leveraging this Service Principal just created.

![Screenshot of the Variable Groups tab in the Phippy's build definition in Azure Pipelines.](https://1.bp.blogspot.com/-iPmxCkZX2a4/XSYEdoFEmwI/AAAAAAAATWU/AVTMPPZYijAABiNT_Z897KGStYdVR3cOwCLcBGAs/s640/Capture2.PNG)

And voila, for today!

Throughout this blob article, we were able to add more security in our CI/CD pipeline by storing our Secrets into Azure Key Vault and by following the Least Privilege Security Principle, we rigorously improved our Helm chart versioning as well as we leveraged the multi-stage definition as YAML file to gain in automation with Configuration-as-Code.

Hope you enjoyed this blog article and hope you are able to leverage and adapt it for your own needs and context.

Cheers! ;)