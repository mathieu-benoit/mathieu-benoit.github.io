---
title: scanning container images for vulnerabilities in acr with asc
date: 2019-11-29
tags: [azure, containers, security]
description: let's use azure security center (asc) to scan your containers in azure container registry (acr)
aliases:
    - /scanning-containers-with-acr/
---
One of the new feature announced during [Ignite 2019]({{< ref "/posts/2019/11/ignite2019.md" >}}) with Azure Security Center (ASC) is the ability in Preview to [scan container images in Azure Container Registry (ACR)](https://azure.microsoft.com/updates/scan-container-images-for-vulnerabilities-in-azure-security-center).  
Yes you could for sure use any container images scanning tool of your choice like Aqua Security or Twistlock, but now you could leverage ASC too.

I just gave it a try, loved it!

To continue my [Security Posture on Azure]({{< ref "/posts/2019/05/azure-security.md" >}}), I have been leveraging ASC (Standard SKU) and followed [this guide](https://docs.microsoft.com/azure/security-center/azure-container-registry-integration).

Now for any container images pushed in ACR I will trigger a scan to get the potential vulnerabilities detected by Qualys. For example, I gave it a try with the [azure/phippyandfriends](https://github.com/Azure/phippyandfriends) GitHub repository, and here is the resulting PR of the scans I got: [https://github.com/Azure/phippyandfriends/pull/36](https://github.com/Azure/phippyandfriends/pull/36)

Typically, here are the changes of the base images I was able to do/fix:
- `microsoft/aspnetcore:2.0` --> `mcr.microsoft.com/dotnet/core/aspnet:3.1-alpine`
- `node:8.9-alpine` --> `node:10-alpine`
- `php:7.1-apache` --> `php:7.3.12-apache-stretch`
- `golang:1.10.3` --> `golang:1.13.4`

As a result:
- 6 Major/High CVEs were fixed ([see details in this PR](https://github.com/Azure/phippyandfriends/pull/36))
- Container images size have been reduced (more agility + less surface of attack)
    - `nodebrady`: 86.9MB --> 77.6MB
    - `parrot`: 360MB --> 116MB
    - `captainkube`: 45.4MB --> 43.1MB
    - `phippy`: 406MB --> 379MB

Here is an example from within the Azure portal of what I fixed today for the PHP base image:

[![](https://1.bp.blogspot.com/---mC40Qlk9Q/XeGPd5r2Y7I/AAAAAAAAUaE/S-TThL0YNSAq8zaugZI2S7FeYMYv6Sv0QCLcBGAsYHQ/s1600/phippy.PNG)](https://1.bp.blogspot.com/---mC40Qlk9Q/XeGPd5r2Y7I/AAAAAAAAUaE/S-TThL0YNSAq8zaugZI2S7FeYMYv6Sv0QCLcBGAsYHQ/s1600/phippy.PNG)

Really interesting! I have learned a lot through the research I have made to update those base images.

_NB: I have now in my long TODO list, the implementation of this following tutorial to help me keeping such base image up-to-date automatically: [Automate container image builds when a base image is updated in an Azure container registry](https://docs.microsoft.com/azure/container-registry/container-registry-tutorial-base-image-update)._

For the pricing details, you could look at [this](https://docs.microsoft.com/azure/security-center/security-center-pricing) and [this](https://azure.microsoft.com/pricing/details/security-center/).

Cheers!