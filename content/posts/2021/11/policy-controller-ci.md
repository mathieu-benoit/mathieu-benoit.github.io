---
title: opa gatekeeper and policy controller during continuous integration (ci) pipelines
date: 2021-11-26
tags: [gcp, security, kubernetes]
description: let's see how to improve your cloud security posture with FIXME.
draft: true
aliases:
    - /policy-controller-ci/
---
https://alwaysupalwayson.com/posts/2021/03/policy-controller/

Policies are an important part of the security and compliance of an organization. Policy Controller, which is part of Anthos Config Management, allows your organization to manage those policies centrally and declaratively for all your clusters. 

Learning about policy violations as early as possible in your development workflow in your CI pipeline instead of during the deployment has two main advantages: it lets you shift left on security, and it tightens the feedback loop, reducing the time and cost necessary to fix those violations.

https://cloud.google.com/anthos-config-management/docs/tutorials/app-policy-validation-ci-pipeline
https://github.com/abbycar/validate-policies
https://cloud.google.com/architecture/policy-compliant-resources#validating_resources_during_development