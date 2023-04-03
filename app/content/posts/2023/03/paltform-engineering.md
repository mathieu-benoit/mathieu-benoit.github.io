---
title: platform engineering
date: 2023-01-23
tags: [kubernetes, inspiration]
description: let's see what is platform engineering
draft: true
aliases:
    - /platform-engineering/
---
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
https://martinfowler.com/articles/talk-about-platforms.html
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

The term platform engineering has been around for a while, but gained significant traction in the past year. Gartner has even added it to the 2022 ‘Hype Cycle’ Software Engineering. The reality is DevOps teams continue to be overburdened and developers are at odds with taking on operations tasks. The term ‘you build it you run it’ comes with its challenges.
Platform engineering addresses these issues by providing the technology and tooling that will automate repetitive DevOps tasks as well as provide developers with self-service.
Platform engineering enables organizations to better focus their developer efforts. With developer self-service and the use of golden paths, developers can optimize their productivity for business related tasks. This enables them to deliver software faster, more securely and with organizational best practices.

https://youtu.be/jjwrIra7Dx4 - Camille Fournier

DevOps is not a role. DevOps is a set of best practices in order 

SRE (Site Reliability Engineer) is a role.

Platform Engineer is also a role, collaborating with SREs
https://platformengineering.org/blog/what-is-platform-engineering
Developer toil and cognitive load in the cloud-native space is real. The complexity posed by microservices, Kubernetes, and “software-defined everything” almost necessitated that ops needed to solve many of these issues to support cloud-native development.
Developers have reported frustration—they are wasting a lot of time on repetitive work and routine tasks that deliver no business value, such as setting up environments and troubleshooting CI pipelines along with slow feedback loops in the development process.
The developer platform concept, supported by architecture, DevOps and SRE teams, contains the ingredients of transformation both for business and for developer experience.

In this blog post, I will hightlight key aspects defining what is a Platform and 

A platform...

## ...accelerates delivery of business value

According to Gartner(https://www.gartner.com/en/articles/what-is-platform-engineering):
> Platform engineering is an emerging technology approach that can accelerate the delivery of applications and the pace at which they produce business value.

## ...enables developer self-service

https://internaldeveloperplatform.org/what-is-an-internal-developer-platform/
> An Internal Developer Platform (IDP) is built by a platform team to build golden paths and enable developer self-service. An IDP consists of many different techs and tools, glued together in a way that lowers cognitive load on developers without abstracting away context and underlying technologies. Following best practices, platform teams treat their platform as a product and build it based on user research, maintain and continuously improve it.

## ...has a Product mindset

Evan Bottcher touches 
> A digital platform is a foundation of self-service APIs, tools, services, knowledge and support which are arranged as a compelling internal product. Autonomous delivery teams can make use of the platform to deliver product features at a higher pace, with reduced co-ordination.

PO/PM, SWEs, roadmap, user interviews

Product Management best practices with a Product Manager, with a vision, a roadmap, with a...

## ...focuses on the Customer Experience

https://youtu.be/4N2ywun-wTE
> Platform Engineering is a discipline which involved doing whatever it takes to build, maintain and provide a curated platform experience for the communities using it.

A platform has customers and users part of the tech communities using it. With a platform as product approach, you should focus on the personas consuming yoru platform and make sure that their usability journey is as efficient as possible.





## ...uses Cloud Native technologies

https://medium.com/contino-engineering/creating-your-internal-developer-platform-part-2-65ff217cecd6

Kubernetes is API-first, modular, declarative, self-healing

Cloud Native technologies...



## Further thoughts

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

https://youtu.be/jJSo3kdflpA
> A digital platform is a foundation of self-service APIs, tools, services, knowledge and support which are arranged as a compelling internal product. Autonomous delivery teams can make use of the platform to deliver product features at a higher pace, with reduced co-ordination.
- Who are the users
- Is the platform meeting their needs
- Do you have backlog of features and issues in priority
Platform is internal product, drives flow + Enables DevOps at scale + Build according to needs
Identity platform users in app / product teams + Gather feedback / measure progress + Drive adoption
--> Product Manager of the Platform
--> Engineering Manager or Tech Lead of the Platform
--> 

Security, SRE, Support, Compliance, Tech Writer, UX/Designer

Survey, friction logging, dog fooding, live interview, usability interview

Do you have a brand? Logo, stickers, newsletter, t-shirts, lunch&learn, platform advocate

DevX/UX: do they have a fast way, limiting the coginitive load, to ship secure, compliand and resilient apps in production?

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

There are more opiniated products where you don t need to build your own platform but you can buy it: Humanitec --> platform orchestrator
These tools are not incompatible with the other tools mentioned earlier, you can see articles about their collaboration.

A platform team should include a product manager, (or the team lead should perform that function) have a roadmap, and have mechanisms for prioritizing incoming requests.




https://youtu.be/x8kDNO1Pjc0
https://youtu.be/6sCTIVpdC08
Non-Technical Challenges of Platform Engineering - https://youtu.be/m6nlREbQ6LQ


Tips:
- Start small, solve concrete issues/challenges
- Show value, track metrics
- Have a product owner
- Eat your own dogfood
- Listen to your user, be empathetic

https://platformcon.com/
