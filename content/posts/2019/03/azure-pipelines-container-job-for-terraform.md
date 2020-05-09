---
title: azure devops pipeline container job with terraform
date: 2019-03-16
tags: [azure, azure devops]
description: let's leverage container job in azure pipelines for terraform
aliases:
    - /azure-pipelines-container-job-for-terraform/
---
This blog article will leverage the [Azure DevOps pipeline container job](https://docs.microsoft.com/azure/devops/pipelines/process/container-phases) to be able to deploy an Hashicorp Terraform template.

Just to make sure, you don't need to use a container job to deploy a Terraform template with Azure DevOps, one of the [Microsoft-hosted agents](https://docs.microsoft.com/azure/devops/pipelines/agents/hosted), [the Ubuntu 16.04 has already Terraform installed](https://github.com/Microsoft/azure-pipelines-image-generation/blob/master/images/linux/Ubuntu1604-README.md). _But currently, the version pre-installed is 0.11.11, I would like 0.11.13. And when it will changed, I would like to keep the specific version of my choice._  
Another way to deploy a Terraform template and have more control is to manage your own private agent as an [Ubuntu VM](https://docs.microsoft.com/azure/devops/pipelines/agents/v2-linux) or an [Ubuntu Docker image](https://alwaysupalwayson.blogspot.com/2018/05/host-your-private-vsts-linux-agent-in.html) (~10GB...). _But I need to host it and maintain it, that I don't want to do. Here is [an example](https://cloudblogs.microsoft.com/opensource/2018/05/22/cicd-azure-terraform-ansible-vsts-java-springboot-app) with Terraform installed on a custom Docker image agent._

My goal here is to run some tasks on a specific container job with a specific Terraform version installed on a consistent and light way. Here is the GitHub repository I have build for this: [mathieu-benoit/terraform-agent](https://github.com/mathieu-benoit/terraform-agent).
You will find:
- [Dockerfile](https://github.com/mathieu-benoit/azuredevops-terraform-agent/blob/master/Dockerfile) to build my own Docker image with Terraform pre-installed
- [azure-pipeline.yml](https://github.com/mathieu-benoit/terraform-agent/blob/master/azure-pipeline.yml) which defines 2 phases:
    - **Build**: to build my Terraform agent image and push it then here: [mabenoit/terraform-agent](https://cloud.docker.com/u/mabenoit/repository/docker/mabenoit/terraform-agent) (~57MB)
    - **Release**: which uses a container job to actually deploy a Terraform template with the previously built Terraform agent image. In that [simple example we deploy an Azure Resource Group](https://github.com/mathieu-benoit/terraform-agent/blob/master/example/main.tf).

Like you could see [in my Dockerfile](https://github.com/mathieu-benoit/azuredevops-terraform-agent/blob/master/Dockerfile) to build that container image, I've learned how to optimize its size by following these 2 recommendations:
- [Ubuntu 18.04 is now the minimal Ubuntu](https://blog.ubuntu.com/2018/07/09/minimal-ubuntu-released)
    - 16.04=44MB and 18.04=32MB
- [Lightweight Docker Images in 5 Steps](https://semaphoreci.com/blog/2016/12/13/lightweight-docker-images-in-5-steps.html)
    - Fewer layers + integrating the `rm -rf /var/lib/apt/lists/*` command after the `apt-get update` command in the same `RUN` command

Remark: initializing/pulling this Docker image takes ~21 seconds in my build pipeline.

Further considerations:
- For now the Azure DevOps pipeline container job is only available for the Build definition and not the release definition for now. And furthermore it's only supported for the YAML definition and not the yet via the UI designer.
- You could read more about the Container Jobs in Azure Pipelines here: [https://docs.microsoft.com/azure/devops/pipelines/process/container-phases](https://docs.microsoft.com/azure/devops/pipelines/process/container-phases)
- Not part of this blog article, but you need to [store Terraform state in Azure Storage](https://docs.microsoft.com/azure/terraform/terraform-backend) in your CI/CD pipeline to keep the state between 2 Terraform template deployment.
- Even if that blog article was focused on Terraform, you could use this process and concept with any tool of your choice.

Resources:
- [Terraform with Azure](https://docs.microsoft.com/azure/terraform)
- [Provisioning an AKS cluster using Hashicorp Terraform](https://azure.microsoft.com/resources/videos/azure-friday-provisioning-kubernetes-clusters-on-aks-using-hashicorp-terraform)
- [Tutorial: Terraforming your JAMstack on Azure with Gatsby, Azure Pipelines, and Git](https://cloudblogs.microsoft.com/opensource/2018/11/16/terraform-jamstack-azure-gatsby-azure-pipelines-git)
- [Use your own build container image to create containerized apps](https://yuriburger.net/2019/03/04/use-your-own-build-container-image-to-create-containerized-apps)
- I cho, cho, choose you container image [Part 1](https://itnext.io/i-cho-cho-chose-you-container-image-part-1-fa6671d9ae1f) and [Part 2](https://medium.com/@scott.coulton/i-cho-cho-choose-you-container-image-part-2-44b45e47a1f7)

Hope you enjoyed this blog article and you will be able to leverage and adapt it for your own needs and projects!

Cheers! ;)