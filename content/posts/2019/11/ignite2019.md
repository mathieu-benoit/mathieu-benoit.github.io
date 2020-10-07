---
title: ignite 2019, what's new with containers and kubernetes on azure?
date: 2019-11-04
tags: [containers, kubernetes, helm, azure, azure-devops]
description: let's see what has been announced around the containers technologies at the microsoft ignite conference 2019
aliases:
    - /ignite2019/
---
I won't go through all the announcements made at the conference [Microsoft Ignite](https://www.microsoft.com/ignite) 2019, you could find all of them _all-in-one-place_ here: [Book of News, Ignite 2019](http://aka.ms/Ignite2019BookofNews).

Here below, what I would like to highlight, are the updates and news around Docker and Kubernetes on Azure, but first have a look at this blog announcement: [Accelerating cloud-native application development in the enterprise](https://azure.microsoft.com/blog/accelerating-cloud-native-application-development-in-the-enterprise/).  

# Azure Kubernetes Service (AKS)
- [Release 2019-10-28](https://github.com/Azure/AKS/releases/tag/2019-10-28)
- [Authenticated IPs is GA](https://azure.microsoft.com/updates/azure-kubernetes-service-aks-support-for-authenticated-ips-is-now-available)
- [NodePools is GA](https://azure.microsoft.com/updates/support-for-multiple-node-pools-in-azure-kubernetes-service-is-now-available)
- [Autoscaler is GA](https://azure.microsoft.com/updates/generally-available-aks-cluster-autoscaler)
- [Availability Zones is GA](https://azure.microsoft.com/updates/azure-kubernetes-service-aks-support-for-azure-availability-zones-is-now-available)
- [Standard Load Balancer is GA](https://azure.microsoft.com/updates/standard-load-balancers-in-azure-kubernetes-service-aks)
- [Azure Application Gateway Ingress Controller (AGIC) is GA](https://docs.microsoft.com/azure/application-gateway/ingress-controller-overview)
- [Threat protections in Preview](https://azure.microsoft.com/updates/threat-protection-for-azure-kubernetes-service-aks-support-in-security-center)
- [Easier diagnostics and logging in Preview](https://azure.microsoft.com/updates/easier-diagnostics-and-logging-with-azure-kubernetes-service-is-now-in-preview)
- [Dev Spaces in Preview](https://azure.microsoft.com/updates/dev-spaces-connect-for-azure-kubernetes-service-is-now-in-preview)
- [Managed identities integration in Preview](https://azure.microsoft.com/updates/managed-identities-integration-in-azure-kubernetes-service-aks-is-now-in-preview)

# Azure Container Registry (ACR)
- [OCI artifact support is GA](https://azure.microsoft.com/updates/general-availability-azure-container-registry-oci-artifact-support/)
- [UAE North region is GA](https://azure.microsoft.com/updates/general-availability-azure-container-registry-in-uae-north/)
- [Scan container images for vulnerabilities with Qualys in Preview](https://azure.microsoft.com/updates/scan-container-images-for-vulnerabilities-in-azure-security-center/)
- [Repository-scoped permissions in Preview](https://docs.microsoft.com/azure/container-registry/container-registry-repository-scoped-permissions)
- [Teleport in Private Preview](https://stevelasker.blog/2019/10/29/azure-container-registry-teleportation/)
- [Repository-scoped permissions in Preview](https://azure.microsoft.com/blog/azure-container-registry-preview-of-repository-scoped-permissions/)
- [Diagnostic logs in Preview](https://azure.microsoft.com/updates/azure-container-registry-diagnostic-logs-are-now-in-preview/)

# Azure Monitor for containers
- [Live performance metrics and live deployments is GA](https://azure.microsoft.com/updates/live-performance-metrics-and-live-deployments-in-azure-monitor-for-containers)
- [Azure Monitor Prometheus integration is GA](https://azure.microsoft.com/updates/azure-monitor-prometheus-integration-is-now-generally-available)
- [Azure US Government region is GA](https://azure.microsoft.com/updates/general-availability-azure-monitor-for-containers-available-in-azure-us-government)
- [Containers for China regions, Grafana dashboard template, Agent - October 2019 updates](https://azure.microsoft.com/updates/updates-on-azure-monitor-for-containers-for-china-region-grafana-dashboard-template-and-agent)
- [Support for containers on-premises and on Azure Stack in Preview](https://azure.microsoft.com/updates/azure-monitor-now-supports-monitoring-containers-on-premises-and-on-azure-stack)
- [No instrumentation APM for Application on Kubernetes in Private Preview](http://aka.ms/AKSCodelessAPM)

# Miscellaneous
- [Azure Arc](https://azure.microsoft.com/blog/azure-services-now-run-anywhere-with-new-hybrid-capabilities-announcing-azure-arc)
- [Azure RedHat OpenShift hourly prices](https://azure.microsoft.com/updates/azure-red-hat-openshift-hourly-prices)
- [Azure SQL Edge in Preview](https://azure.microsoft.com/services/sql-database-edge)
- [Azure Spring Cloud in Preview](https://azure.microsoft.com/updates/azure-spring-cloud-service-is-now-in-preview)
- [Azure API Management Self-hosted Gateway](https://azure.microsoft.com/updates/azure-arc-enabled-api-management-is-now-available-in-preview) 
- [Dapr Distributed Application Runtime (Dapr)](https://cloudblogs.microsoft.com/opensource/2019/10/16/announcing-dapr-open-source-project-build-microservice-applications)
- [Improved CD capabilities and caching for Azure Pipelines](https://devblogs.microsoft.com/devops/improved-continuous-delivery-capabilities-and-caching-for-azure-pipelines)
- [Secure software supply chain with Azure Pipelines artifact policies](https://devblogs.microsoft.com/devops/secure-software-supply-chain-with-azure-pipelines-artifact-policies)
- [Helm 3.0.0 is out!](https://cloudblogs.microsoft.com/opensource/2019/11/13/helm-3-available-simpler-more-secure)

That's a lot of excitement, isn't it!? Love it!

Here are few sessions you may want to watch on-demand:
- [AKS](https://myignite.techcommunity.microsoft.com/sessions/81598)
- [AGIC](https://myignite.techcommunity.microsoft.com/sessions/82945)
- [ARO](https://myignite.techcommunity.microsoft.com/sessions/81595)
- [Arc](https://myignite.techcommunity.microsoft.com/sessions/84179)
- [OAM and Dapr](https://myignite.techcommunity.microsoft.com/sessions/82059)
- [ASC](https://myignite.techcommunity.microsoft.com/sessions/81972)
- [KEDA](https://myignite.techcommunity.microsoft.com/sessions/83959)
- [Spring Cloud](https://myignite.techcommunity.microsoft.com/sessions/81594)

_Update on November 2019, 25th, you may want to see the [Microsoft Azure related announcements and sessions at KubeCon + CloudNativeCon North America 2019](https://alwaysupalwayson.blogspot.com/2019/11/microsoft-azure-related-announcements.html) too._

Cheers!