---
title: my third week with gcp
date: 2020-08-10
tags: [gcp, security, kubernetes]
description: let's share what I learned during my third week leveraging gcp, focused on gke
draft: true
aliases:
    - /third-week-with-gcp/
---
https://www.cncf.io/blog/2020/07/17/site-reliability-engineering-sre-101-with-devops-vs-sre/

http://go/sre-books

SRE versus DevOps
https://cloud.google.com/blog/products/gcp/sre-vs-devops-competing-standards-or-close-friends

https://cloudblog-withgoogle-com.cdn.ampproject.org/c/s/cloudblog.withgoogle.com/products/management-tools/practical-guide-to-setting-slos/amp/

SLO with GKE at Equifax: cloud.withgoogle.com/next/sf/sessions?session=OPS200

- SLI: service level indicator
    - _a well-defined measure of successful enough_
- SLO: service level objective
    - _a top-line target for fraction of successful interactions_
- SLA: service level agreement
    - consequences


5 key areas with SRE:
1. Reduce organizational silos: Share ownershop
2. Accept failure as normal: Error budgets & blameless postmortems
3. Implement gradual changes: Reduce cost of failure
4. Leverage tooling and automation: Automate common cases
5. Measure everything: Measure toil and reliability

Achieving Resiliency on Google Cloud
https://www.youtube.com/watch?v=DplYhUrADao
--> priority on user activities
--> don't just try to avoid failures