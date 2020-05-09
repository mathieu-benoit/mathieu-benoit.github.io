---
title: protect your terraform state files with azure private endpoints for azure storage
date: 2020-03-14
tags: [azure, security, terraform]
description: let's leverage azure private endpoint to protect the azure blob storage account used to store the terraform state file
aliases:
    - /protect-terraform-state/
---
Few weeks ago, [Azure Private Link was announced GA for Azure Storage, Azure SQL and Azure CosmosDB](https://azure.microsoft.com/updates/azure-private-link-is-now-available) and more recently for Azure Database for [MariaDB](https://azure.microsoft.com/updates/aziure-private-link-for-azure-database-for-mariadb-is-now-generally-available/), [PostgreSQL](https://azure.microsoft.com/updates/private-link-for-azure-database-for-postgresql-single-server-is-now-available) and [MySQL](https://azure.microsoft.com/updates/azure-private-link-for-azure-database-for-mysql-is-now-available). And actually [Private AKS cluster with Azure Private Link](https://docs.microsoft.com/azure/aks/private-clusters) just became GA too.
Azure Private Link includes two concepts: Private Endpoint and Private Link Service. With this blog article we won't discuss about [Private Link Service](https://docs.microsoft.com/azure/private-link/private-link-service-overview).
  
I would like to leverage Azure Private Link to protect the Azure Blob Storage account used to store the TF State of [my Terraform deployment]({{< ref "/posts/2019/09/deploy-terraform-via-azure-pipelines.md" >}}).  
For this I have leveraged a combination of the following resources:  
- [Quickstart: Create a private endpoint using Azure CLI](https://docs.microsoft.com/azure/private-link/create-private-endpoint-cli)
- [Connect privately to a storage account using Azure Private Endpoint](https://docs.microsoft.com/azure/private-link/create-private-endpoint-storage-portal)
- [Using Private Endpoints for Azure Storage](https://docs.microsoft.com/azure/storage/common/storage-private-endpoints)

First let's create the Azure Storage account (if you don't have one yet):
```
rg=<your-resourcegroup-name>
storageName=<your-storage-name>
location=<your-location>
az group create \
    -n $rg \
    -l $location
storageAccountId=$(az storage account create -g $rg -n $storageName --sku Standard\_LRS --kind StorageV2 --encryption-services blob --query id -o tsv)
```

Then let's create the VNET and Subnet we will put the Azure Storage account into (if you don't have one yet):
```
vnetName=<your-vnet-name>
subnetName=<your-subnet-name>
az network vnet create \
    -n $vnetName \
    -g $rg \
    --subnet-name $subnetName
```

Now, we need to create the Azure Private Endpoint bound to our Azure Storage account:  
```
privateEndpointName=<your-private-endpoint-name>  
az network vnet subnet update \
    -n $subnetName \
    -g $rg \
    --vnet-name $vnetName \
    --disable-private-endpoint-network-policies true  
az network private-endpoint create \
    -n $privateEndpointName \
    -g $rg \
    --vnet-name $vnetName \
    --subnet $subnetName \
    --private-connection-resource-id $storageAccountId \
    --group-id blob \
    --connection-name $privateEndpointName  
az storage account update \
    -g $rg \
    -n $storageName \
    --default-action Deny  
```

Finally, we need to create a Private DNS for this Azure Storage and create an association link with the VNET:
```
zoneName="privatelink.blob.core.windows.net"
az network private-dns zone create \
    -g $rg \
    -n $zoneName
az network private-dns link vnet create \
    -g $rg \
    --zone-name $zoneName \
    -n $privateDnsName \
    --virtual-network $vnetName \
    --registration-enabled false
networkInterfaceId=$(az network private-endpoint show -n $privateEndpointName -g $rg --query 'networkInterfaces[0].id' -o tsv)
privateIpAddress=$(az resource show --ids $networkInterfaceId --api-version 2019-04-01 --query properties.ipConfigurations[0].properties.privateIPAddress -o tsv)
az network private-dns record-set a create \
    -n $storageName \
    --zone-name $zoneName \
    -g $rg
az network private-dns record-set a add-record \
    --record-set-name $storageName \
    --zone-name $zoneName \
    -g $rg \
    -a $privateIpAddress
```

Here you are, with all the above commands, your Azure Storage account is not anymore accessible publicly but now only by who has access to its VNET:  
- Any resources in the same VNET
- Any resources in [peered VNET](https://docs.microsoft.com/azure/virtual-network/virtual-network-peering-overview)
- Any resources in [Gateway-ed network](https://docs.microsoft.com/azure/expressroute/expressroute-about-virtual-network-gateways)

In my case, like illustrated in [my Terraform deployment]({{< ref "/posts/2019/09/deploy-terraform-via-azure-pipelines.md" >}}), I'm leveraging [my own custom and private Azure Pipelines Agent as a Docker container]({{< ref "/posts/2020/02/custom-azure-pipelines-agent.md" >}}) deployed on my AKS cluster in the same VNET or on a peered VNET. FYI, there is limitations with Azure Web App for Containers or Azure Container Instances (ACI) which don't support 1/ build docker container images on Docker + 2/ like [described here](https://docs.microsoft.com/azure/container-instances/container-instances-vnet#unsupported-networking-scenarios) they don't support internal name resolution which won't work with the Private DNS setup required by Azure Private Endpoints.

Complementary resources:
- [Azure Private Link FAQ](https://docs.microsoft.com/azure/private-link/private-link-faq)
- [Azure Private Link Pricing](https://azure.microsoft.com/pricing/details/private-link/)
- [Using Azure Private Link for Storage Accounts](https://stefanstranger.github.io/2019/11/03/UsingAzurePrivateLinkForStorageAccounts/)

Hope you enjoyed this blog article and this walk-through process to secure your Azure Blob Storage account hosting your Terraform State files.

Stay safe! Cheers!