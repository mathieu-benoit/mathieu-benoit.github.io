---
title: cost optimization on gcp
date: 2020-11-18
tags: [gcp]
description: fixme
draft: true
aliases:
    - /gcp-co/
---

https://services.google.com/fh/files/misc/understanding_the_principles_of_cost_optimization_2020_whitepaper_google_cloud.pdf

https://cloud.google.com/blog/products/management-tools/optimize-google-cloud-resources-with-active-assist

tagging
policy

visibility to financial teams

cost optimization tool should be part of the ci/cd pipeline/loop

Cost Optimization on Google Cloud
https://cloud.withgoogle.com/next/sf/explore?session=CST101#industry-insights
https://youtu.be/cwbcNQDo3Eg
Cloud landscape challenges, shifting to OpEx model, elasticity as perceived issue, synergy between Finance, Engineering and Management.
Path to predictable cloud costs: visibility, accountability and control.

https://cloud.google.com/solutions/cost-efficiency-on-google-cloud

https://cloud.google.com/blog/products/gcp/best-practices-for-optimizing-your-cloud-costs

https://www.hashicorp.com/blog/a-guide-to-cloud-cost-optimization-with-hashicorp-terraform

[Cost Control and Financial Governance Best Practices (Cloud Next '19)](https://youtu.be/MM4wZ5JwYdE) is great feedback from Deloitte, Etsy, Broad Institute, and Vendasta on how they are managing their businesses on GCP and increasing the predictability of their cloud costs with financial governance policies, controls, and cost optimizations. Build proactive alerts, dashboard and reports visible to a broad list of stakeholders: transparency, shared responsibilities, encourage collaboration, etc.
{{< youtube id="MM4wZ5JwYdE" title="Cost Control and Financial Governance Best Practices (Cloud Next '19)" >}}

[Cloud is Complex. Managing It Shouldn’t Be](https://cloud.withgoogle.com/next/sf/sessions?session=CMP100#infrastructure). Active Assist is making it easier for customers to manage their cloud efficiently and securely with smart analytics and machine learning built into Google Cloud itself. Learn how to better understand your cloud, prevent problems, and get actionable insights and recommendations on how to optimize and improve your environment with the tools that Google provides:
{{< youtube id="A2tvDIfevos" title="Cloud is complex. Managing it shouldn't be.">}}

- [Optimize Cost to Performance on Google Kubernetes Engine](https://cloud.withgoogle.com/next/sf/sessions?session=APP218#application-modernization) [[Youtube](https://youtu.be/ry7XfEHivgE)]
    - Cluster Autoscaler, Pod Horizontal Autoscaler and Pod Vertical Autoscaler with the combination of continuous monitoring to the rescue. Did you know that [`VerticalPodAutoscaler`](https://cloud.google.com/kubernetes-engine/docs/how-to/vertical-pod-autoscaling#getting_resource_recommendations) could be used to just recommend which CPU or memory requests your containers need?

+ https://cloud.google.com/solutions/reducing-costs-by-scaling-down-gke-off-hours

https://www.finops.org/
https://dannb.org/blog/2020/evolving-cloud-cost-strategy-scale/