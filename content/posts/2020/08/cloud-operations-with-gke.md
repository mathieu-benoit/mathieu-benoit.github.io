---
title: cloud operations with gke
date: 2020-08-17
tags: [gcp, sre, containers, kubernetes]
description: let's see how to leverage google cloud operations (aka stackdriver) with gke
draft: true
aliases:
    - /cloud-operations-with-gke/
---
[![](https://storage.googleapis.com/gweb-cloudblog-publish/images/google_sre.max-500x500.jpg)](https://storage.googleapis.com/gweb-cloudblog-publish/images/google_sre.max-500x500.jpg)

[Cloud Operations](https://cloud.google.com/products/operations) (formerly known as Stackdriver) helps to monitor, troubleshoot, and improve application performance on your Google Cloud environment. It's a combination of different features such as Cloud Logging, Cloud Monitoring, Cloud Trace, Cloud Debugger and Cloud Profiler and [many more](https://cloud.google.com/products/operations#all-features).

So, where to start with your GKE cluster? Actually, that's pretty easy and straight forward! Checkout this blog article about [Using logging for your apps running on Kubernetes Engine](https://cloud.google.com/blog/products/management-tools/using-logging-your-apps-running-kubernetes-engine).

> Cloud Logging, and its companion tool Cloud Monitoring, are full featured products that are both deeply integrated into GKE. In this blog post, we’ll go over how logging works on GKE and some best practices for log collection. Then we’ll go over some common logging use cases, so you can make the most out of the extensive logging functionality built into GKE and Google Cloud Platform.

By default, a GKE cluster is created with the option `--enable-stackdriver-kubernetes`. From there you could [observe your GKE cluster with a pre-built GKE dashboard and GKE metrics](https://cloud.google.com/stackdriver/docs/solutions/gke/observing). You could also create custom metrics, custom dashboards and alerts based on your containers, services, nodes, etc.

Another feature I find very valuable is the [concept of service monitoring combined with the SLO API](https://cloud.google.com/stackdriver/docs/solutions/slo-monitoring). I'm able to [get another pre-defined dashboard for my Kubernetes services](https://cloud.google.com/stackdriver/docs/solutions/slo-monitoring/microservices#gke-base-svc) and actually from there [I'm now able to define some SLIs/SLOs](https://cloud.google.com/stackdriver/docs/solutions/slo-monitoring/ui/create-slo). To know more about SLO, I have found these resources below very valuable:
- [Defining SLOs](https://cloud.google.com/solutions/defining-SLOs)
- [Adopting SLOs](https://cloud.google.com/solutions/adopting-SLOs)
- [Implementing SLOs](https://landing.google.com/sre/workbook/chapters/implementing-slos/)
- [The Art of SLOs workshop](https://landing.google.com/sre/resources/practicesandprocesses/art-of-slos/)

> To determine if an SLO (Service Level Objective) is met/successful, you need a measurement. That measurement is called the SLI (Service Level Indicator). An SLI measures the level of a particular service that you're delivering to your customer. Ideally, the SLI is tied to an accepted CUJ (Critical User Journey).

Complementary resources:
- [SRE books](https://landing.google.com/sre/books/)
- [StackDoctor on Youtube by Yuri Grinshteyn](https://www.youtube.com/results?search_query=%23StackDoctor)
- [21 new ways we're improving observability with Cloud Ops](https://cloud.google.com/blog/products/management-tools/cloud-operations-suite-gets-21-new-features)
- [Qwiklabs - Google Cloud's Operations Suite on GKE](https://www.qwiklabs.com/quests/133)
- [New ways to manage custom Cloud Monitoring dashboards](https://cloud.google.com/blog/products/management-tools/how-to-use-cloud-monitorings-dashboard-api-and-templates)

Happy monitoring and happy sailing! ;)