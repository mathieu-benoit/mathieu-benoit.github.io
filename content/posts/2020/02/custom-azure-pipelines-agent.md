---
title: my own custom and private azure pipelines agent as a docker container
date: 2020-02-24
tags: [azure, containers, kubernetes, azure devops]
description: let's build a custom linux container image as an azure pipelines agent
aliases:
    - /custom-azure-pipelines-agent/
---
On May 2018 I documented [how to host your own and private Azure DevOps (formerly VSTS) agent](https://alwaysupalwayson.blogspot.com/2018/05/host-your-private-vsts-linux-agent-in.html). It was all about hosting this agent as a Docker Linux container and we were able to host it on Kubernetes.  
Since then the recommended approach by Microsoft is to review how to customize your own custom and private Docker agent. We don't have anymore to get the huge/heavy base Docker image with all the tools preconfigured. Now we could just install the tools we need, you could follow the official documentation for this: [Running a self-hosted agent in Docker](https://docs.microsoft.com/azure/devops/pipelines/agents/docker#linux).

In my case I'm building and using my own Docker Linux container image with the tools I need: Docker, Terraform and Helm, here is my GitHub repository to see how I do this: [https://github.com/mathieu-benoit/my-azure-pipelines-agent](https://github.com/mathieu-benoit/my-azure-pipelines-agent)

You will be able to find the important files there:
- [Dockerfile](https://github.com/mathieu-benoit/my-azure-pipelines-agent/blob/master/Dockerfile)
    - _The definition and the content of my custom agent._
- [azure-pipeline.yml](https://github.com/mathieu-benoit/my-azure-pipelines-agent/blob/master/azure-pipeline.yml)
    - The Azure Pipeline definition in YAML to build and push my custom agent in my DockerHub
- [example/use-my-custom-ado-agent.yml](https://github.com/mathieu-benoit/my-azure-pipelines-agent/blob/master/example/use-my-custom-ado-agent.yml)
    -  _An example to see how to use this custom private agent in your Azure Pipelines definitions_

Once built and pushed we could easily deploy this Docker container like illustrated below on any Docker host, Azure Container Instances (ACI) or Kubernetes (say AKS for example):
```
AZP_TOKEN=FIXME
AZP_URL=https://dev.azure.com/FIXME
AZP_AGENT_NAME=myadoagent
AZP_POOL=myadoagent
```

On any Docker host:
```
docker run \
    -e AZP_URL=$AZP_URL \
    -e AZP_TOKEN=$AZP_TOKEN \
    -e AZP_AGENT_NAME=$AZP_AGENT_NAME \
    -e AZP_POOL=$AZP_POOL \
    -it mabenoit/ado-agent:latest
```

On ACI:
```
az container create \
    -g $rg -n $name \
    --image mabenoit/ado-agent:latest \
    --ip-address Private \
    -e AZP_URL=$AZP_URL AZP_TOKEN=$AZP_TOKEN AZP_AGENT_NAME=$AZP_AGENT_NAME AZP_POOL=$AZP_POOL
```

On Kubernetes:
```
kubectl create secret generic azp \
    --from-literal=AZP_URL=$AZP_URL \
    --from-literal=AZP_TOKEN=$AZP_TOKEN \
    --from-literal=AZP_AGENT_NAME=$AZP_AGENT_NAME \
    --from-literal=AZP_POOL=$AZP_POOL
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ado-agent
spec:
  replicas: 1
  selector:
    matchLabels:
      app: ado-agent
  template:
    metadata:
      labels:
        app: ado-agent
    spec:
      containers:
        - name: ado-agent
          image: mabenoit/ado-agent:latest
          env:
            - name: AZP_URL
              valueFrom:
                secretKeyRef:
                  name: azp
                  key: AZP_URL
            - name: AZP_TOKEN
              valueFrom:
                secretKeyRef:
                  name: azp
                  key: AZP_TOKEN
            - name: AZP_AGENT_NAME
              valueFrom:
                secretKeyRef:
                  name: azp
                  key: AZP_AGENT_NAME
            - name: AZP_POOL
              valueFrom:
                secretKeyRef:
                  name: azp
                  key: AZP_POOL
          volumeMounts:
            - mountPath: /var/run/docker.sock
              name: docker-socket-volume
      volumes:
        - name: docker-socket-volume
          hostPath:
            path: /var/run/docker.sock
EOF
```

_Remark: you could see the volumeMounts section with the Kubernetes deployment, that's how you could leverage this way to build Docker container in a Docker container. You could do that with the Docker host example but it's not possible to do this with ACI._

The advantages of doing that for me is having my own tools but most important having the ability to host my agent as a Docker container anywhere, especially important if I need to secure it in my own Azure Infrastructure (think VNET/Subnet and restricting access in Azure). I will blog about this in more details later.

Resources:
- [Deploying Azure Pipelines agents as containers to Kubernetes](https://juliocasal.com/2020/01/14/deploying-azure-pipelines-agents-as-containers-to-kubernetes/)
- [Elastic Self-hosted Agent Pools](https://github.com/microsoft/azure-pipelines-agent/blob/master/docs/design/byos.md)
- [Fully isolated private Agents for Azure Pipelines in Azure Container Instances](https://www.henrybeen.nl/fully-isolated-private-agents-for-azure-pipelines-in-azure-container-instances/)
- [Ephemeral Pipelines Agents](https://github.com/microsoft/azure-pipelines-ephemeral-agents)

Hope you enjoyed this blog article and its associated code to reuse and adapt for your own needs.

Cheers!