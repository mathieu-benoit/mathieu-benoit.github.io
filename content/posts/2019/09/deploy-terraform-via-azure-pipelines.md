---
title: a recipe to deploy your azure resources with terraform via azure devOps
date: 2019-09-04
tags: [azure, terraform, azure pipelines]
description: let's deploy terraform templates via azure pipelines
---
Here is a recipe which is putting altogether the different concepts to deploy any Azure resources with Terraform by leveraging Azure DevOps:
[https://github.com/mathieu-benoit/azure-devops-terraform](https://github.com/mathieu-benoit/azure-devops-terraform)

Here is the summary of the features used:
- **Terraform**
    - AzureRM provider
    - Terraform backend state
    - Terraform Azure AD Service Principal
    - Terraform Validate, Plan versus Apply
    - Terraform Output
- **Azure DevOps**
    - Azure pipelines in YAML (for the entire CI/CD pipeline)
    - Different Azure pipelines features leveraged such as: Templates, Variable Groups, Environments, Checks (Manual approval with YAML pipelines)
    - Azure DevOps CLI

All of this content is already documented and coded in the GitHub repository mentioned above. Happy reading and happy Git cloning! ;)

Hope you enjoyed this recipe and you'll be able to adapt it for your own context and needs, cheers!