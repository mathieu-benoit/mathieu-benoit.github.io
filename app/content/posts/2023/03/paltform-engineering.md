---
title: platform engineering
date: 2023-01-23
tags: [kubernetes, inspiration]
description: let's see what is platform engineering
draft: true
aliases:
    - /platform-engineering/
---
https://youtu.be/4N2ywun-wTE
> Platform Engineering is a discipline which involved doing whatever it takes to build, maintain and provide a curated platform experience for the communities using it.

https://www.gartner.com/en/articles/what-is-platform-engineering
> Platform engineering is an emerging technology approach that can accelerate the delivery of applications and the pace at which they produce business value.

https://youtu.be/x8kDNO1Pjc0

The promise of having DevOps people doing everything is painful, not possible. You build it, you run it.

https://platformengineering.org/blog/what-is-platform-engineering

https://internaldeveloperplatform.org/what-is-an-internal-developer-platform/
> An Internal Developer Platform (IDP) is built by a platform team to build golden paths and enable developer self-service. An IDP consists of many different techs and tools, glued together in a way that lowers cognitive load on developers without abstracting away context and underlying technologies. Following best practices, platform teams treat their platform as a product and build it based on user research, maintain and continuously improve it.

Developer toil and cognitive load in the cloud-native space is real. The complexity posed by microservices, Kubernetes, and “software-defined everything” almost necessitated that ops needed to solve many of these issues to support cloud-native development.
Developers have reported frustration—they are wasting a lot of time on repetitive work and routine tasks that deliver no business value, such as setting up environments and troubleshooting CI pipelines along with slow feedback loops in the development process.
The developer platform concept, supported by architecture, DevOps and SRE teams, contains the ingredients of transformation both for business and for developer experience.

https://www.youtube.com/@PlatformEngineering

https://humanitec.com/blog/gartner-internal-developer-platforms-platform-engineering
“Platform engineering is the discipline of building and operating self-service internal developer platforms (IDPs) for software delivery and life cycle management.” And further on: 
“Platform engineering also improves the developer experience, thus reducing employee frustration and attrition.”
“Improve developer experience by building internal developer platforms to reduce cognitive load, developer toil and repetitive manual work.”
“Platforms don’t enforce a specific toolset or approach – it is about making it easy for developers to build and deliver software while not abstracting away useful and differentiated capabilities of the underlying core services”
“Platform engineering teams treat platforms as a product (used by developers) and design the platform to be consumed in a self-service manner.”

https://humanitec.com/blog/jason-warner-why-github-built-their-own-internal-developer-platform
The key change for the organization was that things were scalable now. There is no one person in the app team thinking about DDOS prevention, anyone can care about a subject deeply if they want to, and have it represented in a container manifest. Compliance people aren’t spread out throughout the organization, but instead focus on the settings in the IDP. As long as a concern is represented in the IDP it’s there and you don’t need to worry. As Jason puts it:
‍ “It’s really magical if you have it and I cannot understand how it’s possible to actually ship fast if you don’t have this. “
The impact was easy to measure. Teams were able to ship faster with a smaller headcount in ops. They reduced the degree of freedom every single application developer had and standardization drove efficiency. Developers became entirely self-serving and there is zero unnecessary communication between teams. Because keep in mind that “a good setup is one where Dev and Ops don’t need to talk to each other at all”.

https://thenewstack.io/how-team-topologies-supports-platform-engineering/
https://youtu.be/b8YHCDMxqfg?list=PLR74Ng-6aEfCcdBM_l8PPfX85S33-fSFS
I think that’s why you hear so much about Team Topologies within the context of platform engineering. We talk about the Platform as a Product because it needs to help their platform customers, who are the other teams, do their work more effectively, reduce their cognitive load [and] how much effort it takes to do certain things.
Then we talk about enabling teams, typically a small team of experts around some domain — like data science, security or user research.
Whatever is some domain that requires expert knowledge, how can we bring this knowledge to the stream-aligned teams in an effective way, basically reducing the learning curve to get teams up to speed with what they need to do to make our application or service more secure? How do we get the data that we need and how do we analyze the data to get the insights that we need about our service?
So the enabling teams [are] going to do this with the stream-aligned teams by teaching, by mentoring, by helping them learn quickly.
And then we’re talking about the platform teams.
And inside the platform, you might have also enabling teams. While at a startup or scale-up, the platform might just be some sort of Wiki page, where some people have gathered together some guidance on how to create some databases, how to do some stuff in an effective way for other teams to get started faster — something that reduces cognitive load.
But you need to look at the big picture: If the platform is done right, in this kind of platform-as-a-product approach, then potentially you’re seeing gains in the teams that are developing customer-focused products that are much higher than what you’re going to gain by cutting some of the platform services and teams.
We need to be very focused on, as a platform team or a group of teams, is [whether] this is helping the stream-aligned teams do those things better and faster? Because there’s a real danger of the platform providing services in a way that are not easy to use, or it’s not as reliable as it should be. Or it’s confusing or doesn’t support the use cases that the stream-aligned teams need.
And then you’re not helping them. You’re increasing their cognitive load, because now we have to use the service that is not a good fit for what we need to do, so it’s actually slowing us rather than helping us go faster.
Think about the Platform as a Product, understand your users [and] talk to them. Do fast iteration on what you’re providing in the platform, get feedback as quickly as possible from your users.
What [do] we need to prioritize? What is more valuable? Because you’re likely going to have thousands of requests when you’re working on a platform, because everyone has their own needs. So you need to have this product vision of where are we going. What is the broader value to the organization? Let’s not build things that only help one or two teams.
All of this is product thinking. Do a bit of user research, talk to your customers, see how they use your services. Provide the right level of documentation as self-service, so that people can use the platform and not depend on you as a platform team to answer their requests.

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

IdP - the sum of many components that form golder paths for developers.
There is no single open source tool that will give you an entire internal developer platform (IDP), but you can if you wish aim to create your own by combining multiple tools like ArgoCD and Crossplane to manage your kubernetes workloads and infrastructure, with Backstage acting as your service catalog.

VCS - CI - CR - Infra - CD - Obs - Dev portal

INFRASTRUCTURE
Kubernetes
Terraform and/or KRM

FRONTEND
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

There are more opiniated products where you don t need to build your own platform but you can buy it: Humanitec --> platform orchestrator
These tools are not incompatible with the other tools mentioned earlier, you can see articles about their collaboration.

A platform team should include a product manager, (or the team lead should perform that function) have a roadmap, and have mechanisms for prioritizing incoming requests.