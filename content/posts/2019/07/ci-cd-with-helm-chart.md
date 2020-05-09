---
title: helm chart management in ci/cd with acr and azure devops
date: 2019-07-01
tags: [azure, azure devops, kubernetes, containers]
description: let's do ci/cd with your own helm charts, acr and aks via azure pipelines
aliases:
    - /ci-cd-with-helm-chart/
---
I recently got an interesting comment on my blog article [Tutorial: Using Azure DevOps to setup a CI/CD pipeline and deploy to Kubernetes](https://cloudblogs.microsoft.com/opensource/2018/11/27/tutorial-azure-devops-setup-cicd-pipeline-kubernetes-docker-helm):

> _Hi, I am trying to use Helm in CICD pipeline in Azure DevOps. I was going through lot of nice articles about this and this one is really great, but to be honest I am little bit confused about versioning of Helm package and push to repository with each build run. It means, that with each build I need to push same version of Helm chart? Maybe only one change logically in appVersion have to be increased. For me it does not make sense, because in helm doc is written that version and appVersion are different properties. What is the best strategy for this? I am thinking about strategy to have just chart in specific version and use this exact same version until I will need to do changes in chart. Our infra is on Azure and Azure DevOps. The most suitable use case for me is this one, but as I said the only one think against to it is push helm chart for each build. Could you please help? I don't want to create some antipattern ;)_

Fair enough. Indeed, it's a very valid point. **Firstly**, I'm not using the [recommended approach for the Helm chart version](https://helm.sh/docs/developing_charts/#charts-and-versioning), I'm using _on-purpose_ the build.buildId instead. **Secondly**, the Helm chart is built every time there is a new build, even if there is no changes with the Helm templates.

With this blog article today I would like to go through the implementation I would do to take into account those 2 points with Azure DevOps.

# 1. Build definition

Here is how the commands helm package and az acr helm push look like now:
```
- bash: |
    helm package \
        $(system.defaultWorkingDirectory)/$(projectName)/charts/$(projectName)
  displayName: 'helm package'
- bash: |
    chartPackage=$(ls $(projectName)-*.tgz)
    chartVersion=$(echo $(basename $chartPackage) | egrep -o '[0-9].*[0-9]')
    chartVersionAlreadyExists=$(az acr helm list \
                                    -n $(registryName) \
                                    -u $(registryLogin) \
                                    -p $(registryPassword) \
                                    --query "$(projectName)[?version=='$chartVersion'].version" \
                                    -o tsv)
    if [ "$chartVersion" != "$chartVersionAlreadyExists" ]; then
        az acr helm push \
            -n $(registryName) \
            -u $(registryLogin) \
            -p $(registryPassword) \
            $chartPackage
    fi
    echo $(jq -n --arg version "$chartVersion" '{helmChartVersion: $version}') > $(build.artifactStagingDirectory)/variables.json
  name: helmPush
  displayName: 'az acr helm push'
- publish: $(build.artifactStagingDirectory)
  artifact: build-artifact
```

What has changed?

- I'm not using anymore `--version` while running helm package to be now able to leverage the version which resides in the `Chart.yaml` file. This version is not anymore `build.buildId` and is now managed directly from source control with that file. Again [that's the recommendation according to the Helm documentation](https://helm.sh/docs/developing_charts/#charts-and-versioning).
- Before running az acr helm push, I need to check if the Helm chart version already exists otherwise I will have an error on that regard, I don't want that. There is also a `--force` parameter but I don't want to overwrite the previous entry with the same value, if someone forgot to change the version in the `Chart.yaml` file, it will override a previous value... could be dangerous.
- Finally, I'm exposing the `helmChartVersion` value in a file then shared via an Azure pipeline artifact `build-artifact`, [see here why I'm doing that like this]({{< ref "/posts/2019/06/azure-pipelines-stages-variables.md" >}}).

# 2. Release definition

Here is how the commands helm upgrade looks like now:
```
- download: current
  artifact: build-artifact
- bash: |
    helmChartVersion=$(jq .helmChartVersion $(pipeline.workspace)/build-artifact/variables.json -r)
    helm upgrade \
        --namespace $(k8sNamespace) \
        --install \
        --wait \
        --version $helmChartVersion \
        --set image.repository=$(registryServerName)/$(projectName) \
        --set image.tag=$(build.buildId) \
        $(projectName) \
        $(registryName)/$(projectName)
  displayName: 'deploy helm chart'
```

What has changed?  
- I added a task to `download` the file exposed via my `build-artifact`, then I will extract the value of the `helmChartVersion` with `jq`.
- And I'm now using the actual `helmChartVersion` instead of `build.buildId` previously while running `helm upgrade --version`.

That's it, that's how I would do that. Now the Helm chart version is driven by the value included in the Chart.yaml. What about you? How are you doing this? Let me know if you see some improvements here, would love to fine-tune this approach!

Cheers!