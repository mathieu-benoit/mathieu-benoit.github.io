---
title: deploying azure cognitive services as docker containers
date: 2019-03-31
tags: [azure, containers, ai]
description: let's deploy azure cognitive services as docker containers
---
{{< youtube hdfbn4Q8jbo >}}

> _[Azure Cognitive Services](https://aka.ms/cognitive-services) is a set of APIs, SDKs and container images that enables developers to integrate ready-made AI directly into their applications. Azure Cognitive Services contains a broad set of capabilities including text analytics; facial detection, speech and vision recognition; natural language understanding, and more.
> Container support in Azure Cognitive Services allow developers to use the same rich APIs that are available in Azure but with the flexibility that comes with containers. See [Container support in Azure Cognitive Services](http://aka.ms/cognitive-services-containers) for details._

As we speak only LUIS, Key Phrase Extraction (Text), Language Detection (Text) and Sentiment Analysis (Text) are in Public Preview with Containers. Recognize Text (Computer Vision) and Face are in Private Preview, you could request access.

FYI here are the size of the Docker images as for today:
- `mcr.microsoft.com/azure-cognitive-services/sentiment` - 1.45GB
- `mcr.microsoft.com/azure-cognitive-services/keyphrase` - 1.25GB
- `mcr.microsoft.com/azure-cognitive-services/language` - 0.845GB
- `mcr.microsoft.com/azure-cognitive-services/luis` - 0.474GB

_Note: if you need a specific version and not the latest, you could get the list of tags available via the following url (example for the sentiment): [https://mcr.microsoft.com/v2/azure-cognitive-services/sentiment/tags/list](https://mcr.microsoft.com/v2/azure-cognitive-services/sentiment/tags/list)_  

Even if you are using Azure Cognitive Services on Containers, you need to provision the Azure service, here, to do so let's do it by Azure CLI:
```
$ cs=<your-cs-name>  
$ rg=<your-rg-name>  
$ location=eastus  
$ az cognitiveservices account create -n $cs -g $rg --kind CognitiveServices --sku S0 -l $location --yes  
```

Then we will need the access key and the endpoint to reuse later:
```
$ key=$(az cognitiveservices account keys list -n $cs -g $rg --query key1 -o tsv)  
$ endpoint=$(az cognitiveservices account show -n $cs  -g $rg --query endpoint -o tsv)  
```

From there you could run locally your Docker container (sentiment with the example below):
```
$ docker run --rm -it -p 5000:5000  mcr.microsoft.com/azure-cognitive-services/sentiment Eula=accept Billing=${endpoint}text/analytics/v2.0 ApiKey=$key
```
  
You could then test your API here: [http://localhost:5000/swagger/index.html](http://localhost:5000/swagger/index.html)  
  
You could also run this container on an Azure Container Instances (ACI):
```
aci=<your-aci-name>  
az container create \
    -g $rg \
    -n $aci \
    --image mcr.microsoft.com/azure-cognitive-services/sentiment \
    -e Eula=accept Billing=${endpoint}text/analytics/v2.0 ApiKey=$key \
    --ports 5000 \
    --cpu 1 \
    --memory 4 \
    --ip-address public
```
  
You will be able to test the same swagger url by replacing localhost by the ACI IP address:
```
az container show -g $rg -n $aci --query ipAddress.ip -o tsv
```
  
You will find more details and all you need to know to run your Container support in Azure Cognitive Services here:  
- [Install and run containers](https://docs.microsoft.com/azure/cognitive-services/text-analytics/how-tos/text-analytics-how-to-install-containers)
- [Configure containers](https://docs.microsoft.com/azure/cognitive-services/text-analytics/text-analytics-resource-container-config)

You will for example see an important information about [billing and the requirement for your Docker container to connect to Azure](https://docs.microsoft.com/azure/cognitive-services/text-analytics/how-tos/text-analytics-how-to-install-containers#connecting-to-azure).
  
Another option is to deploy this container in a Kubernetes cluster, let's do it:
```
$ deploymentName=sentiment-test
$ kubectl run $deploymentName --image mcr.microsoft.com/azure-cognitive-services/sentiment --port 5000 --env Eula=accept --env ApiKey=$key --env Billing=${endpoint}text/analytics/v2.0
$ kubectl expose deployment $deploymentName --port=5000 --target-port=5000 --type LoadBalancer
```
  
You will be able to test the same swagger url by replacing localhost by the K8S service's `EXTERNAL-IP`:
```
kubectl get svc $deploymentName
```
  
If you are looking for a more complete documentation about Azure Cognitive Services on Kubernetes, feel to leverage this official tutorial: [How to run on Azure Kubernetes Service](https://docs.microsoft.com/azure/cognitive-services/text-analytics/how-tos/text-analytics-how-to-use-container-instance).  
  
Further resources and considerations:  
- [Getting started with Azure Cognitive Services in containers](https://azure.microsoft.com/blog/getting-started-with-azure-cognitive-services-in-containers)
- [Running Cognitive Service containers](https://azure.microsoft.com/blog/running-cognitive-service-containers)
- [Bringing AI to the edge](https://azure.microsoft.com/blog/bringing-ai-to-the-edge)
- [Microsoft Professional Program for Artificial Intelligence](https://aka.ms/AI-training)

Hope you enjoyed this blog article and you will be able to leverage and adapt this for your own needs and context.

Cheers!