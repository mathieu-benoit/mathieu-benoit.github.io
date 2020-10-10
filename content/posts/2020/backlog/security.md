---
title: fixme
date: 2020-10-10
tags: [gcp, security]
description: fixme
draft: true
aliases:
    - /fixme/
---
https://cloud.google.com/security/beyondprod
https://cloud.google.com/security/infrastructure/design/

[![](https://storage.googleapis.com/gweb-cloudblog-publish/images/GCP_Security_kLUG9v5.max-2200x2200.jpg)](https://storage.googleapis.com/gweb-cloudblog-publish/images/GCP_Security_kLUG9v5.max-2200x2200.jpg)

Are you looking for a step-by-step guide to setup your GCP foundation? Here you are with this [Google Cloud Security Foundations guide](https://services.google.com/fh/files/misc/google-cloud-security-foundations-guide.pdf)!

> Security in public clouds differs intrinsically from customer-owned infrastructure because there is shared responsibility for security between the customer and the cloud provider.

> You have many decisions to make when setting up your Cloud deployment. You might need help deploying workloads with secure defaults simply, quickly, and effectively in order to accelerate your ability to deliver business impact and value to your customers. But you might not have the time to build the new skills necessary to cope with the differences and new challenges of a cloud transition. Therefore, you can often benefit from curated and opinionated guidance for both a secure foundational starting point and for customization to match your specific needs.

Beginning with a security foundations blueprint
This guide provides the GCP opinionated security foundations blueprint and captures a step-by-step view of how to configure and deploy your Google Cloud estate. This document can provide a good reference and starting point because we highlight key topics to consider. In each topic, we provide background and discussion of why we made each of our choices. In addition to the step-by-step guide, this security foundations blueprint has an accompanying [Terraform automation repository](https://github.com/terraform-google-modules/terraform-example-foundation) and an example demonstration Google organization so you can learn from and experiment with an environment configured according to the blueprint.

Organization
Folders
Projects
https://cloud.google.com/resource-manager/docs/cloud-platform-resource-hierarchy

Organization Policy
https://cloud.google.com/resource-manager/docs/organization-policy/overview

Identity
https://cloud.google.com/architecture/identity/overview-google-authentication#google_identities
Google Cloud Directory Sync
https://support.google.com/a/answer/106368?hl=en
IAM
https://cloud.google.com/iam
IAM Recommender
https://cloud.google.com/iam/docs/recommender-managing

Networking
Shared VPC
https://cloud.google.com/vpc/docs/shared-vpc
VPC Service Controls
https://cloud.google.com/vpc-service-controls
Best practices and reference architectures for VPC design
https://cloud.google.com/solutions/best-practices-vpc-design
Dedicated Interconnect
https://cloud.google.com/network-connectivity/docs/interconnect/concepts/dedicated-overview

Complementary resources:
- [Google Cloud Blog - Identity & Security](https://cloud.google.com/blog/products/identity-security)
- [Google Infrastructure Security Design Overview](https://cloud.google.com/security/infrastructure/design)


FIXME/TOWATCH:
BeyondProd: A new approach to cloud-native security
https://cloud.google.com/security/beyondprod
Google Infrastructure Security Design (Google Cloud Next '17)
https://www.youtube.com/watch?v=O-JXFQezWOc
--> really great resource
--> Hardware --> Boot --> OS + IPC --> Storage --> 
https://www.youtube.com/watch?v=ZQHoC0cR6Qw