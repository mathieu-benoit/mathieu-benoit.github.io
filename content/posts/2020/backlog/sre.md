---
title: site reliability engineering
date: 2020-10-10
tags: [gcp, sre]
description: let's discuss about site reliability engineering (sre)
draft: true
aliases:
    - /sre/
---
The Art of SLOs Handbook letter
https://static.googleusercontent.com/media/landing.google.com/en//sre/static/pdf/art-of-slos-handbook-letter.pdf
SRE and the art of SLOs at the DevOpsDays 2019 Chicago: https://youtu.be/fWvNzDVOJDE

Three months, 30x demand: How we scaled Google Meet during COVID-19
https://cloud.google.com/blog/products/g-suite/keeping-google-meet-ahead-of-usage-demand-during-covid-19

> Hope is not a strategy. Engineering solutions to design, build, and run large-scale systems scalably, reliably, and efficiently is a strategy, and a good one.
> We approach the SRE work with a spirit of constructive pessimism: we hope for the best, but plan for the worst.
> Reliability vs. feature velocity: We seek to maintain production reliability and stability while removing obstacles to shipping new features.
> SRE vs. DevOps: DevOps is a set of principles—an interface of which SRE is one implementation.
> Put simply, a user on a 99% reliable smartphone cannot tell the difference between 99.99% and 99.999% service reliability! With this in mind, rather than simply maximizing uptime, Site Reliability Engineering seeks to balance the risk of unavailability with the goals of rapid innovation and efficient service operations, so that users’ overall happiness—with features, service, and performance—is optimized.

What is Site Reliability Engineering?
SRE is a specialized job function that focuses on the reliability and maintainability of large systems. SRE is also a mindset, and a set of engineering approaches to running better production systems.
Key principles:
- The most important feature of any system is reliability
- Our monitoring doesn't decide our reliability - our Users do
- Well engineered software can only get you to 99.9%
  Well engineered operations --> 99.99%
  Well engineered business --> 99.999%
Takeaway: SREs manage service reliability by balancing the risk of unavailability and rapid innovation so that overall user happiness is optimized.

https://cloud.google.com/blog/products/devops-sre/another-way-to-gauge-your-devops-performance-according-to-dora

SRE Classroom: Distributed PubSub
https://cloud.google.com/blog/products/devops-sre/join-sre-classroom-nalsd-workshops
https://landing.google.com/sre/resources/practicesandprocesses/sre-classroom/

How to build an SRE team
https://www.blameless.com/blog/how-to-build-an-sre-team

You don’t need SRE. What you need is SRE.
https://sdarchitect.blog/2020/02/20/you-dont-need-sre-what-you-need-is-sre/

Really great intro: Optimizing SRE Effectiveness at The New York Times (Cloud Next '19)
https://www.youtube.com/watch?v=QCRe-Vo-PPo

https://cloudplatform.googleblog.com/2018/07/sre-fundamentals-slis-slas-and-slos.html

https://queue.acm.org/detail.cfm?id=3404974

SLOs with Stackdriver Service Monitoring
https://medium.com/google-cloud/slos-with-stackdriver-service-monitoring-62f193147b3f
Automating Application Dashboard Creation for Services on GKE/Istio
https://medium.com/google-cloud/automating-application-dashboard-creation-for-services-on-gke-istio-a55a5a79aa15

https://www.cncf.io/blog/2020/07/17/site-reliability-engineering-sre-101-with-devops-vs-sre/

http://go/sre-books

SRE versus DevOps
https://cloud.google.com/blog/products/gcp/sre-vs-devops-competing-standards-or-close-friends
SRE versus DevOps
https://youtu.be/uTEL8Ff1Zvk
Now SRE Everyone Else with CRE! 
https://youtu.be/GQPzaq-owYM

https://cloudblog-withgoogle-com.cdn.ampproject.org/c/s/cloudblog.withgoogle.com/products/management-tools/practical-guide-to-setting-slos/amp/

SLO with GKE at Equifax: cloud.withgoogle.com/next/sf/sessions?session=OPS200
- CUJ: critical user journey
    - _specific steps that a user takes to accomplish goals_
- SLI: service level indicator
    - _a well-defined measure of successful enough_
- SLO: service level objective
    - _a top-line target for fraction of successful interactions_
- SLA: service level agreement
    - consequences
- Error Budgets
    - _inverse of availability: amount of errors allowed based on SLAs_

5 key areas with SRE:
1. Reduce organizational silos: Share ownershop
2. Accept failure as normal: Error budgets & blameless postmortems
3. Implement gradual changes: Reduce cost of failure
4. Leverage tooling and automation: Automate common cases
5. Measure everything: Measure toil and reliability

How customers can adopt SRE:
1. Establish SLOs
    - Developers and business owners should work together to define service-level objectives that can be met most months. Consider starting with on application or major project.
2. Blameless postmortems
    - Google found that establishing a culture of blameless postmortems results in more reliable systems and is critical to creating and maintaining a successful SRE organization.
3. Form an SRE Team
    - Start with an advocate for SRE within an organization and decide how to embed them, such as within development, operations or horizontally (consulting) across teams. Evaluate the pros/cons of each model.

Achieving Resiliency on Google Cloud
https://www.youtube.com/watch?v=DplYhUrADao
--> priority on user activities
--> don't just try to avoid failures

https://uptime.is/

TODOs:

SRE: The Cloud Native Approach to Operations by Container Solutions:
https://info.container-solutions.com/sre-the-cloud-native-approach-to-operations-e-book

The Art of SLOs workshop
https://landing.google.com/sre/resources/practicesandprocesses/art-of-slos/

Coursera - Site Reliability Engineering: Measuring and Managing Reliability
https://www.coursera.org/learn/site-reliability-engineering-slos

Building good SLOs—CRE life lessons
https://cloud.google.com/blog/products/gcp/building-good-slos-cre-life-lessons
Know thy enemy: how to prioritize and communicate risks—CRE life lessons
https://cloud.google.com/blog/products/gcp/know-thy-enemy-how-to-prioritize-and-communicate-risks-cre-life-lessons
Coursera - Site Reliability Engineering: Measuring and Managing Reliability
https://www.coursera.org/learn/site-reliability-engineering-slos