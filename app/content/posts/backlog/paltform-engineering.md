---
title: platform engineering, devops on steroide?
date: 2023-05-25
tags: [kubernetes, inspiration]
description: let's see what is platform engineering
draft: true
aliases:
    - /platform-engineering/
---
https://platifyinsights.com/2023/04/12/what-is-platform-engineering/

https://thenewstack.io/at-platformcon-for-realtor-com-success-is-driven-by-stories/

https://github.blog/2023-06-08-developer-experience-what-is-it-and-why-should-you-care/

[Fidelity’s Software Delivery Platform – Frictionless Approach to Achieve Autonomic DevOps & Enhanced Security/Compliance Practices](https://youtu.be/77_oX2SD7Vs?list=PLj6h78yzYM2M3-reG8FBlsE5s7P_UOvl4)

https://thenewstack.io/kubecon-panel-how-platform-engineering-benefits-developers/
https://www.syntasso.io/post/syntasso-donates-first-version-of-platform-maturity-model-to-cncf-working-group
https://siliconangle.com/2023/04/22/plenty-gas-innovations-continue-apace-first-post-pandemic-kubecon/
https://www.infoq.com/news/2023/04/idp-user-experience/
https://tanzu.vmware.com/content/blog/golden-path-to-cloud-success
https://thenewstack.io/why-you-should-run-your-platform-team-like-a-product-team/
https://humanitec.com/blog/what-is-dynamic-configuration-management
https://humanitec.com/blog/implementing-dynamic-configuration-management-with-score-and-humanitec
https://humanitec.com/blog/gartner-internal-developer-platforms-platform-engineering
https://humanitec.com/blog/what-is-a-platform-orchestrator
https://thenewstack.io/a-platform-for-kubernetes/
https://medium.com/@vincn.ledan/platform-as-a-product-accelerating-cloud-adoption-and-innovation-315f9baafcde
https://www.youtube.com/watch?v=S0an3FnI69Q
https://youtu.be/BnFJzf6Ruwk
https://www.salaboy.com/2023/03/31/what-platform-engineering-why-continuous-delivery/
https://humanitec.com/blog/sre-vs-devops-vs-platform-engineering
https://techpodcast.form3.tech/episodes/ep-26-tech-role-of-a-platform-engineer
https://launchdarkly.com/blog/sre-vs.-platform-engineering-vs.-devops/
https://www.thoughtworks.com/insights/blog/platforms/engineering-platform-key-to-maximizing-software-development-effectiveness
https://medium.com/4th-coffee/building-your-developer-portal-with-backstage-a-comprehensive-tutorial-d9433722c633
https://www.cncf.io/blog/2023/03/06/leveraging-platform-engineering-and-devops-synergy-for-high-performance-systems/
https://www.syntasso.io/post/the-12-platform-challenges-recap
https://internaldeveloperplatform.org/what-is-an-internal-developer-platform/
https://www.contino.io/insights/platform-engineering
https://platformengineering.org/blog/what-is-platform-engineering
https://www.youtube.com/watch?v=4N2ywun-wTE
https://nandovillalba.medium.com/ux-on-platform-engineering-1c7ecfaddea7
https://www.youtube.com/watch?v=Jip3lBnxKXU
https://www.youtube.com/watch?v=SN2uigKsiyc
https://www.infoq.com/minibooks/platform-engineering-guide/
https://www.youtube.com/watch?v=vkYNCZZVMPE
https://www.syntasso.io/post/crossing-the-platform-gap
https://thenewstack.io/how-spotlify-adopted-platform-engineering-culture/
https://platformengineering.org/platform-tooling
https://thenewstack.io/platform-engineering-in-2023-doing-more-with-less/
https://platformengineering.org/talks-library/applying-devsecops-to-kubernetes
https://platformengineering.org/talks-library/internal-platform-enterprise-courtney-kissler
https://platformengineering.org/talks-library/things-to-consider-before-building-your-internal-platform-thoughtworks
https://nirmata.com/2023/03/01/the-need-for-an-enterprise-wide-platform-engineering-strategy/
https://nirmata.com/2023/03/03/reasons-why-platform-teams-adopt-policy-as-code-for-kubernetes/
https://platformcon.com/
https://thenewstack.io/getting-developer-self-service-right/
https://circleci.com/blog/platform-engineering-devops-at-scale/
https://github.com/cncf/tag-app-delivery/blob/main/platforms-whitepaper/latest/index.md
https://youtu.be/jjwrIra7Dx4 - Camille Fournier


The term **Platform engineering** has been around for a while, and gained significant traction most recently. The reality is DevOps teams continue to be overburdened and developers are at odds with taking on operations tasks. The term **you build it, you run it** comes with its challenges. Platform engineering addresses these issues by providing the technology and tooling that will automate repetitive DevOps tasks as well as provide developers with self-service.

I have been impressed by the rich and broad content around [Platform Engineering](https://platformengineering.org/blog/what-is-platform-engineering) and all the best practices and tips shared around it.

> Developer toil and cognitive load in the cloud-native space is real. The complexity posed by microservices, Kubernetes, and “software-defined everything” almost necessitated that ops needed to solve many of these issues to support cloud-native development.

> Developers have reported frustration - they are wasting a lot of time on repetitive work and routine tasks that deliver no business value, such as setting up environments and troubleshooting CI pipelines along with slow feedback loops in the development process.

Coming from a developer background and having learned Kubernetes with all what it requires (networking, security, infrastructure, etc.), this resonates a lot to me.

The [CNCF App Delivery TAG](https://github.com/cncf/tag-app-delivery) recently released this excellent [CNCF Platforms White Paper](https://www.cncf.io/blog/2023/04/11/announcing-a-white-paper-on-platforms-for-cloud-native-computing/).

> A team of platform experts not only reduces common work demanded of product teams but also optimizes platform capabilities used in those products. A platform team also maintains a set of conventional patterns, knowledge and tools used broadly across the enterprise; enabling developers to quickly contribute to other teams and products built on the same foundations.

So what is defining a successful platform? In this blog post, I will summarize 6 key aspects higlighting Platform Engineering best practices:
- [Accelerate delivery of business value](#accelerate-delivery-of-business-value)
- [Enable developer self-service](#enable-developer-self-service)
- [Have a Product mindset](#have-a-product-mindset)
- [Focus on the Customer Experience](#focus-on-the-customer-experience)
- [Abstract Cloud Native technologies](#abstract-cloud-native-technologies)

Finally, to wrap up this blog post, we will conclude with:
- [Navigate the CNCF landscape](#navigate-the-cncf-landscape)
- [Wrap up with Humanitec](#wrap-up-with-humanitec)

## Accelerate delivery of business value

According to Gartner(https://www.gartner.com/en/articles/what-is-platform-engineering):

> Platform engineering is an emerging technology approach that can accelerate the delivery of applications and the pace at which they produce business value.

## Enable developer self-service

https://internaldeveloperplatform.org/what-is-an-internal-developer-platform/

> An Internal Developer Platform (IDP) is built by a platform team to build golden paths and enable developer self-service. An IDP consists of many different techs and tools, glued together in a way that lowers cognitive load on developers without abstracting away context and underlying technologies. Following best practices, platform teams treat their platform as a product and build it based on user research, maintain and continuously improve it.

## Have a Product mindset

[Evan Bottcher](https://martinfowler.com/articles/talk-about-platforms.html) talks about the Product mindset:

> A digital platform is a foundation of self-service APIs, tools, services, knowledge and support which are arranged as a compelling internal product. Autonomous delivery teams can make use of the platform to deliver product features at a higher pace, with reduced co-ordination.

This involves that the platform should follow Product Management best practices with a Product Manager, with a vision, a roadmap, prioritizing incoming requests, conducting user interviews, creating beta tests program for early adopters, etc.

Here are even more considerations you will have as 
- Do you have a brand, a logo, stickers, a newsletter, t-shirts, lunch&learn sessions, platform advocates?
- Do you have dedicated team for support or SRE? Do you monitor metrics and provide SLAs with your services? How to you help your internal customers meeting with their own metrics and SLAs for the services they provide to their end-users?

## Focus on the Customer Experience

A platform has customers and users part of the tech communities using it. With a platform as product approach, you should focus on the personas consuming your platform and make sure that their usability journey is as efficient as possible.

https://youtu.be/4N2ywun-wTE
> Platform Engineering is a discipline which involved doing whatever it takes to build, maintain and provide a curated platform experience for the communities using it.

Meet the developers where they are in their developer flow.

Optimize for adoption and discoverability.

## Abstract Cloud Native technologies

> Because platform teams corral providers and provide consistent experiences over their offerings, they enable efficient use of public clouds and service providers for foundational but undifferentiated capabilities such as databases, identity access, infrastructure operations, and app lifecycle.
https://www.cncf.io/blog/2023/04/11/announcing-a-white-paper-on-platforms-for-cloud-native-computing/

https://medium.com/contino-engineering/creating-your-internal-developer-platform-part-2-65ff217cecd6

Kubernetes is API-first, modular, declarative, self-healing

Cloud Native technologies...


## Navigate the CNCF landscape

CNCF landscape

FIXME - Image from CNCF whitepaper

Terraform, Helm, Kyverno/OPA Gatekeeper, GitLab/GitHub, FluxCD/ArgoCD, etc.

Kubevela, KEDA, Humanitec

UX
https://nandovillalba.medium.com/ux-on-platform-engineering-1c7ecfaddea7
> Recognize and take all your communities into account.
- Clear boundaries and responsabilities
- Self service and automation
- Flexible and evolvable
- Reliable and caters for day operations
--> Adjust your thinking: aim not just to provide a service but rather to be a service (and serve your communities)

TOOLS
https://medium.com/contino-engineering/creating-your-internal-developer-platform-part-2-65ff217cecd6

IdP - the sum of many components that form golden paths for developers.
There is no single open source tool that will give you an entire internal developer platform (IDP), but you can if you wish aim to create your own by combining multiple tools like ArgoCD and Crossplane to manage your kubernetes workloads and infrastructure, with Backstage acting as your service catalog.

VCS - CI - CR - Infra - CD - Obs - Dev portal

INFRASTRUCTURE
Kubernetes
Terraform and/or KRM

FRONTEND
Kubernetes manifests or Helm charts in Git repo?
https://backstage.io/
Backstage is an open platform for building developer portals
A developer portal = one frontend for your entire infrastructure (unifies all your tooling, services, apps, data, docs with a single, consistent UI)
Speed - Scale - Chaos-control

ABSTRACT KUBERNETES RESOURCES
Helm
Crossplane
https://youtu.be/xECc7XlD5kY
--> Key concepts: composition + generated resources with different providers

STORE DESIRED STATE
Git source control like GitHub or GitLab

DEPLOY RESOURCES
GitOps with ArgoCD or FluxCD

GOVERN RESOURCES
Kyverno or OPA Gatekeeper or Styra

https://kubevela.io/

dapr
https://youtu.be/JxyI1Rr1yys?list=PLcip_LgkYwzspITkpyHGRw7L87UqOI2lX




https://youtu.be/x8kDNO1Pjc0
https://youtu.be/6sCTIVpdC08
Non-Technical Challenges of Platform Engineering - https://youtu.be/m6nlREbQ6LQ

## Wrap up with Humanitec

There are more opiniated products where you don't need to build your own platform but you can buy it: Humanitec --> platform orchestrator
These tools are not incompatible with the other tools mentioned earlier, you can see articles about their collaboration.

https://youtu.be/b-67km-wcEo
- Golden paths over cages
  - Pull developers, do not push them. If you abstract, never take context.
- Standardization by design
  - By using the platform, the degree of standardization stays constant or increases.
- Dynamic over static configs
  - The platform should be able to dymanically create configs with every deployment.
- Code first / interface choice
  - Code should be the single source of truth. Users should have interface choice.

Structuring the repos:
- Developer owned:
  - Workload source code
  - Dockerfile
  - Score file
  - CI pipeline definition
- Platform Admin owned:
  - Resource definitions
  - Resource drivers/IaC (static and dynamic)
  - Workload profiles
  - Automations/Compliance

## Conclusion

The developer platform concept, supported by architecture, DevOps and SRE teams, contains the ingredients of transformation both for business and for developer experience.

Tips:
- Start small, solve concrete issues/challenges for your developer teams. Enable others by meeting them where they are today.
- Show value, track metrics
- Have a product owner
- Eat your own dogfood
- Listen to your user, be empathetic

The platform is open to change, collaborate to discover new needs.

## Resources

- [KubeCon Europe 2023 highlights Kubernetes explosion and need for instant platform engineering](https://www.cncf.io/blog/2023/05/08/kubecon-europe-2023-highlights-kubernetes-explosion-and-need-for-instant-platform-engineering/)
- https://humanitec.com/blog/gartner-internal-developer-platforms-platform-engineering
- https://www.youtube.com/@PlatformEngineering
- https://thenewstack.io/how-team-topologies-supports-platform-engineering/ - https://youtu.be/b8YHCDMxqfg?list=PLR74Ng-6aEfCcdBM_l8PPfX85S33-fSFS
- [The ins and outs of delivering your platform as a product - Paula Kennedy from Syntasso](https://youtu.be/jJSo3kdflpA)
- [How Is Platform Engineering Different from DevOps and SRE?](https://thenewstack.io/how-is-platform-engineering-different-from-devops-and-sre/)

https://platformcon.com/
