---
title: set a multi-stage output variable with azure devops
date: 2019-06-09
tags: [azure devops]
description: let's see how to easily pass variables from one stage to another in azure devops pipelines
aliases:
    - /azure-pipelines-stages-variables/
---
_Update on May 4th, 2020: Azure DevOps now supports this feature: [Jobs can access output variables from previous stages](https://docs.microsoft.com/azure/devops/release-notes/2020/sprint-168-update#jobs-can-access-output-variables-from-previous-stages). So you don't need anymore this tips, but could just read this article for fun and to learn few commands with `jq` ;)_

Since [I wrote my first Multi-stage YAML Azure Pipelines](https://alwaysupalwayson.blogspot.com/2019/05/i-wrote-my-first-multi-stage-yaml-azure.html) I played few times with this new capability to have both Build and Release pipelines in one YAML file, I really love it!

One of the limitation I have found is it's not possible to create/write/pass variables from one Stage to another Stage, but [it's possible from one Job to another Job within one Stage](https://docs.microsoft.com/azure/devops/pipelines/process/variables?view=azure-devops&tabs=yaml%2Cbatch#set-a-multi-job-output-variable).  
Donovan Brown recently proposed one way to do that: [Passing variables from stage to stage in Azure DevOps release](http://donovanbrown.com/post/Passing-variables-from-stage-to-stage-in-Azure-DevOps-release). Furthermore, still on the same track, Stephan Stranger recently wrote [Passing variables from stage to stage in Azure DevOps Release Pipelines](https://stefanstranger.github.io/2019/06/26/PassingVariablesfromStagetoStage) too.  
Interesting, but... to be honest I was looking for something lighter and easier to setup and maintain.  
  
After a quick chat with my colleague [Chris Wiederspan](https://www.linkedin.com/in/cwiederspan), we came with the idea to leverage the [Artifacts within Azure pipelines](https://docs.microsoft.com/azure/devops/pipelines/artifacts/pipeline-artifacts) (not [Azure Artifacts](https://azure.microsoft.com/services/devops/artifacts)). So typically creating a file with key/value pairs in it and then shared across Stages.  
  
And here is how I was able to accomplish that with an Ubuntu agent to play a little bit with `jq`:  

# Stage 1
```
- bash: |
 echo $(jq -n --arg jqVar "$(oneAdoVariable)" '{yourVariableToShare: $jqVar}') > $(build.artifactStagingDirectory)/variables.json
- publish: $(build.artifactStagingDirectory)
 artifact: yourartifact
```
_Note: "$(oneAdoVariable)" could be replaced by either "yourvalue" or "$oneBashVariable", depending on your use case._

# Stage 2..n
```
- download: current  
 artifact: yourartifact  
- bash: |  
 valueOfYourVariableShared=$(jq .yourVariableToShare $(pipeline.workspace)/yourartifact/variables.json -r)  
```

Not that complicated, isn't it? Hope you could leverage this approach for your own needs.

Cheers!