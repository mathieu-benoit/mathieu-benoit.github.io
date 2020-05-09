---
title: my bot just became a cloud native app
date: 2019-12-23
tags: [azure, containers, kubernetes, dotnet, terraform, helm]
description: let's leverage docker, helm, kubernetes and terraform to make your bot app more cloud native
---
On April 2018, I played for the first time with the Bot Framework, [I got that idea to leverage such technologies and feature for my monthly "Azure News & Updates" blog article](https://alwaysupalwayson.blogspot.com/2018/04/my-monthly-azure-news-updates-blog.html). It was a good opportunity for me to make my app [a great conversationalist](https://alwaysupalwayson.blogspot.com/2018/03/make-your-apps-great-conversationalists.html). At that time, I built this with Azure Functions v1, Bot Framework v3, static and not-compiled code in .NET Framework, I got issue with the cold start; none of this was cross-platform at that time... Since then I have learned a lot about OSS, Docker and Kubernetes. On that regard, why not modernizing my Bot with more Cloud Native Computing practices?!

Before trying to reinvent the wheel I found those following insightful and inspirational resources:
- [In 2017-01](https://medium.com/@sozercan/deploying-microsoft-bot-framework-bots-using-kubernetes-on-azure-container-service-acs-ea5c6ffead1f), Sertaç Özercan used Docker, ACR and ACS to deploy his Bot in NodeJS
- [In 2018-02](https://itnext.io/building-a-kubernetes-deployment-pipeline-for-microsoft-bot-framework-part-1-ddbb9f6f1796), Jonathan Harrison used Docker, ARM Templates, AKS, Helm 2, Nginx, TravisCI to deploy his Bot in NodeJS
- [In 2018-09](https://medium.com/@AliMazaheri/building-a-chat-bot-using-azure-aks-and-bot-framework-bfa1f698cc3c), Ali Mazaheri used Docker, Draft, ACR and AKS to deploy his Bot in .NET Core 2
- [In 2019-03](https://github.com/microsoft/app-innovation-team/tree/master/1.%20labs/walkthrough-bot-dotnet), Roberto Cervantes used Docker, ACR, AKS, Helm 2, Nginx, Cert-Manager, Azure DevOps to deploy his Bot in .NET Core 2
- [In 2019-05](https://mybuild.techcommunity.microsoft.com/sessions/77153), Luis Antonio Beltran Prieto and Humberto Jaimes used Docker to deploy their Bot in .NET Core 2

**Huge kudos to them** for taking the time to share and document their knowledge and learnings!

From this and as we speak in December 2019, I have been able to leverage latest and greatest features and technologies to modernize and containerize my Bot, here below are few highlights and concepts you will be able to find with my own implementation:

[![](https://1.bp.blogspot.com/-ZvSZ8KCoQ9w/Xg0lnjh7ZnI/AAAAAAAAUls/zp9FgCt49GkUekauUqX4Ulowwl-zZtBmwCLcBGAsYHQ/s1600/FlowAndArchitecture.PNG)](https://1.bp.blogspot.com/-ZvSZ8KCoQ9w/Xg0lnjh7ZnI/AAAAAAAAUls/zp9FgCt49GkUekauUqX4Ulowwl-zZtBmwCLcBGAsYHQ/s1600/FlowAndArchitecture.PNG)

# .NET Core 3.1

I was able to implement my Bot with [.NET Core 3.1 just announced early December 2019](https://devblogs.microsoft.com/dotnet/announcing-net-core-3-1). That's the new LTS version, where performance is greatly improved, the garbage collector use less memory and this version has been hardened for Docker.

# Docker base image

I'm using the [mcr.microsoft.com/dotnet/core/aspnet](https://hub.docker.com/_/microsoft-dotnet-core-aspnet) base image, you could find the entire list of tags available here: [https://mcr.microsoft.com/v2/dotnet/core/aspnet/tags/list](https://mcr.microsoft.com/v2/dotnet/core/aspnet/tags/list). If you don't know yet, base images of Microsoft related products are now published in the Microsoft Container Registry, [read the story here](https://devblogs.microsoft.com/dotnet/net-core-container-images-now-published-to-microsoft-container-registry/). Furthermore, I'm using the alpine version of this base image in order to [reduce the size of the image as well as the surface of threat]({{< ref "/posts/2019/11/scanning-containers-with-asc.md" >}}) with such small alpine distribution. Notice also that I'm not using latest, 3 nor 3.1 but explicitly `aspnet:3.1.0` and `sdk:3.1.100` versions to be able to update them accordingly as new versions will arrive.  
The size of my image is now 112 MB.

# Helm 3 and Helm chart

[Helm 3 went out in November 2019]({{< ref "/posts/2019/11/helm3.md" >}}), this major version got rid of Tiller, but that's not all! With this implementation I was able to build the associated Helm 3 chart, pushed it in Azure Container Registry (ACR) and deploy it in a Tiller-less Kubernetes cluster. Furthermore, this Helm chart contains all the Kubernetes objects the application needs to successfuly run on any Kubernetes cluster: `Deployment`, `Service`, `Ingress`, `Issuer`, `NetworkPolicies`, `Secrets` as well as its dependency with the Nginx Ingress Controller chart (see inside the `Chart.yaml`).

# Azure Pipelines

Inspired by my blog article [Tutorial: Using Azure DevOps to setup a CI/CD pipeline and deploy to Kubernetes](https://cloudblogs.microsoft.com/opensource/2018/11/27/tutorial-azure-devops-setup-cicd-pipeline-kubernetes-docker-helm) I was able to implement both CI/Build and CD/Release in YAML, to build the Docker image and Helm chart, push them in ACR to then trigger the deployment in AKS via Helm. In addition to that, I was able to leverage my blog article [A recipe to deploy your Azure resources with Terraform via Azure DevOps]({{< ref "/posts/2019/09/deploy-terraform-via-azure-pipelines.md" >}}) to combine my CI/CD with Terraform within the same Appplication's pipeline. I also added an [Approval/Check point between the Build/CI and Release/CD Stages](https://docs.microsoft.com/azure/devops/pipelines/process/approvals) (note: it's a manual process for now).

[![](https://1.bp.blogspot.com/-s251aiDj80I/Xg5JBR9s_uI/AAAAAAAAUl4/yjUvRnN-Fkgey-RvynUbk76sCwXWEXNdwCLcBGAsYHQ/s1600/Capture.PNG)](https://1.bp.blogspot.com/-s251aiDj80I/Xg5JBR9s_uI/AAAAAAAAUl4/yjUvRnN-Fkgey-RvynUbk76sCwXWEXNdwCLcBGAsYHQ/s1600/Capture.PNG)

# Kubernetes Ingress Controller

To be able to register the backend of your [Azure Bot Service](https://docs.microsoft.com/azure/bot-service), even if it could be hosted anywhere (literally), it should expose an HTTPS endpoint. In my case, I'm exposing my Bot by Nginx as an Ingress Controller by deploying the [ingress-nginx Helm chart](https://kubernetes.github.io/ingress-nginx). I'm also using the following annotation to add a DNS on my public Azure IP Address:  
service.beta.kubernetes.io/azure-dns-label-name  
Furthermore, I'm leveraging the [jetstack/cert-manager Helm chart](https://cert-manager.io) for generating my Certificate and configure my TLS termination.

You could find my GitHub Pull Request showing in details the implementation of the 5 topics mentioned above: [https://github.com/mathieu-benoit/MyMonthlyBlogArticle.Bot/pull/10](https://github.com/mathieu-benoit/MyMonthlyBlogArticle.Bot/pull/10). Furthermore, you will find this other GitHub PR where my Helm chart got enrich with more Kubernetes objects and Helm dependencies: [https://github.com/mathieu-benoit/MyMonthlyBlogArticle.Bot/pull/18](https://github.com/mathieu-benoit/MyMonthlyBlogArticle.Bot/pull/18).

# Application Insights

To be able to get telemetry with this Bot like Requests, Exceptions, Response time, Search terms used, etc. I'm leveraging [Application Insights embedded in my Bot](https://github.com/mathieu-benoit/MyMonthlyBlogArticle.Bot/pull/19).

# Unit Tests

Unit Tests run within the Dockerfile and the results are published as part of the CI/Build in Azure Pipeline. This allows to run unit tests consistently whenever and wherever a docker build command runs. You could [have a look at the associated GitHub PR I did for this](https://github.com/mathieu-benoit/MyMonthlyBlogArticle.Bot/pull/20).

# Terraform

At first when I implemented this Bot, [I leveraged ARM Templates](https://github.com/mathieu-benoit/MyMonthlyBlogArticle.Bot/blob/oldversion/azure-deploy.json), but my preference now is more with Terraform to accomplish Infrastructure-as-Code (IaC), so [here is my GitHub PR for the implementation of this](https://github.com/mathieu-benoit/MyMonthlyBlogArticle.Bot/pull/25). In my Azure Pipeline, I do terraform plan in the Build/CI Stage and do terraform apply in the Release/CD Stage.

Interesting stuffs, isn't it!?

Regarding the price, before this new implementation it was almost free with an Azure Functions in the backend because I don't have a lot of traffic, and actually I could still continue leverage Azure Functions, if I would like. But now, I have made the decision to do it with Kubernetes, to learn more about it, so it will cost me 3 Kubernetes Nodes (VMs), but I have other workloads running on that Kubernetes cluster so this cost is shared by multiple workloads. Furthermore, I have now common practices to deploy any workload consistently via Kubernetes APIs, so I'm saving the cost for the deployments, the automation, the maintenance, etc. that's other invisible/implicit costs to take into account when comparing the real and concrete cost...

Great learnings for me! Feel free to leverage all of this for your own context and needs!

Cheers! ;)