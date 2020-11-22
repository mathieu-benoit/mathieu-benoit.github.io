---
title: site reliability engineering (sre)
date: 2020-10-15
tags: [gcp, devops, sre, inspiration]
description: let's discuss about site reliability engineering (sre)
draft: true
aliases:
    - /sre/
---
From Sysadmin to SRE
https://octopus.com/blog/sysadmin-to-sre

Preparing for peak holiday shopping in 2020: War rooms go virtual
https://cloud.google.com/blog/topics/retail/preparing-for-peak-holiday-season-while-wfh

How Mercari reduced request latency by 15% with Cloud Profiler
https://cloud.google.com/blog/products/management-tools/mercari-uses-cloud-profiler-to-reduce-service-latency

https://www.youtube.com/watch?v=c-w_GYvi0eA
https://www.youtube.com/watch?v=oyJFxr4gYXc
https://www.youtube.com/watch?v=tmpm1XI-Oac
https://www.youtube.com/watch?v=nQv9ySa8MTU
https://www.youtube.com/watch?v=3qB7tqx7ZUI
https://www.youtube.com/watch?v=j6zB7emiobY

[![](https://storage.googleapis.com/gweb-cloudblog-publish/images/DevOps_BlogHeader_D_Rnd3.max-2200x2200.jpg)](https://storage.googleapis.com/gweb-cloudblog-publish/images/DevOps_BlogHeader_D_Rnd3.max-2200x2200.jpg)

> Site Reliability Engineering (SRE) is the practice of balancing the velocity of development features with the risk to reliability

{{< youtube 1NF6N2RwVoc >}}

According to Ben Treynor Sloss at Google, who coined the term SRE, “SRE is what happens when you ask a software engineer to design an operations function”. In 2003, Ben was asked to lead Google’s existing “Production Team” which at the time consisted of seven software engineers. The team started as a software engineering team, and since Ben is also a software engineer, he continued to grow a team that he, as a software engineer, would still want to work on. [He gave a talk at SREcon14](https://www.usenix.org/conference/srecon14/technical-sessions/presentation/keys-sre) where he shared the principles of SRE learned over 11 years of building the team at Google. Here are few notes I captured from this talk:
- Error budgets to control is release should be pushed in Production.
- SLA < 100% means that there will be outages. This is OK. Not fun, but OK. Two goals for each outage:
    1. Minimize impact
    2. Prevent recurrence
- Practice, practice, practice --> Wheel of misfortune to simulate and anticipate outages and train teams

## DevOps versus SRE

SRE versus DevOps
https://cloud.google.com/blog/products/gcp/sre-vs-devops-competing-standards-or-close-friends
SRE versus DevOps
https://youtu.be/uTEL8Ff1Zvk

DevOps emerged to help close gaps and break down silos between development and operations teams.
- DevOps is a philosophy, not a development methodology or technology.
- SRE is a practical way to implement DevOps philosophy.
- Developers focus on feature velocity and innovation; operators focus on reliability and consistency.
- SRE consists of both technical and cultural practices.
- SRE practices align to DevOps pillars:
| DevOps | SRE |
| --- | --- |
| Reduce organizational silos | Share ownership |
| Accept failure as normal | Blamelessness |
| Implement gradual change | Reduce cost of failure |
| Leverage tooling and automation | Toil automation |
| Measure everything | Mesure toil and reliability |

Accept failure as normal with blameless postmortems, components of a postmortem:
- blamelessness and psychological safety
- details of the incident and its timeline
- the actions taken to mitigate or resolve the incident
- the incident's impact
- its trigger and root cause or causes
- the follow-up actions to prevent its recurrence



- Blameless postmortem: Detailed documentation of an incident or
outage, its root cause, its impact, actions taken to resolve it, and
follow-up actions to prevent its recurrence.

Key Points:
- The mission of SRE is to protect, provide for, and progress software
and systems with consistent focus on availability, latency,
performance, and capacity.
- Understanding SRE practices and norms will help you build a
common language to use when speaking with your IT teams and
support your organization’s adoption of SRE both in the short and
long term.
- Experienced SREs are comfortable with failure.
- Failures are documented in postmortems, which focus on systems
and processes versus people.
- 100% reliability is the wrong target because it slows the release of
new features, which is what drives your business.
- SLOs and error budgets create shared responsibility and ownership
between developers and SREs.
- Fostering psychologically safe environments is necessary for
learning and innovation in organizations.
- Organizations developing an SRE culture should focus on creating a
unified vision, determining what collaboration looks like, and
sharing knowledge among teams.

Make tomorrow better than today
- CI/CD and Canarying to reduces the cost of failure
Design thinking and prototyping
Toil automation
- Excessive toil: career stagnation, low morale, confusion, slower progress, precedence, attrition, breach of faith
- Value of automation: consistency, a platform, quicker resolutions, faster action
Psychology of change and resistance to change
- Navigators: help you succeed, celebrate their behaviors, use them as champions
- Critics: have passion and energy, have valid fears, spend time with them
- Victims: need to express emotions, take change personally, listen to and empathize with them
- Bystanders: are difficult to understand, do not know what's going on, continue with normal routine, communicate with them, ascertain their feelings
--> Involve people in change, set realistic expectations, identify opportunities for co-creation and provide coaching instead of solutions, simplify messaging and focus on key concepts per user group, ensure that communications are engaging and training is interactive, allow people time to build new habits.
--> Emotional response to change: denial, resistance, acceptance, exploration, commitment, growth

- Continuous integration: Building, integrating, and testing code
within the development environment.
- Continuous delivery: Deploying to production frequently, or at the
rate the business chooses.
- Canarying: Deploying a change in service to a group of users who
don’t know they are receiving the change, evaluating the impact to
that group, and then deciding how to proceed.
- Toil: Work directly tied to a service that is manual, repetitive,
automatable, tactical, or without enduring value, or that scales
linearly as the service grows.

- Change is best when small and frequent.
- Design thinking methodology has five phases: empathize, define,
ideate, prototype, and test.
- Prototyping culture encourages teams to try more ideas, leading to an
increase in faster failures and more successes.
- Excessive toil is toxic to the SRE role.
- By eliminating toil, SREs can focus the majority of their time on work
that will either reduce future toil or add service features.
- Resistance to change is usually a fear of loss.
- Present change as an opportunity, not a threat.
- People react to change in many ways, and IT leaders need to
understand how to communicate with and support each group.

Measure everything by quantifying toil and reliability
Bad metrics: CPU, Memory, Load time will fire more frequently alerts, but are they actually degredating your user happiness?
Measuring toil to reduce efforts and get more collaboration
What to monitor: symptoms, rather than causes, error budget burn, 
4 golden signals: latency, traffic, errors, saturation

- Goal setting, transparency, and data-based decision making
Measure reliability with good service level indicators (SLIs).
- A good SLI correlates with user experience with your service; that is, a
good SLI tells you when users are happy or unhappy.
- Measure toil by identifying it, selecting an appropriate unit of
measure, and tracking the measurements continuously.
- Monitoring allows you to gain visibility into a system, which is a core
requirement for judging service health and diagnosing your service
when things go wrong.
- Goal-setting, transparency, and data-driven decision making are key
components of SRE measurement culture.
- To make truly data-driven decisions, you need to remove any
unconscious biases. 


https://www.youtube.com/watch?v=7Oe8mYPBZmw
https://www.youtube.com/watch?v=FU7wWiD0N44
https://www.youtube.com/watch?v=XPtoEjqJexs

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

- Kitchen Sink/”Everything SRE” team: We recommend this approach
for organizations that have few applications and user journeys and
where the scope is small enough that only one team is necessary, but
a dedicated SRE team is needed in order to implement its practices.
- Infrastructure team: This type of team focuses on maintaining shared
services and components related to infrastructure, versus an SRE
team dedicated to working on services related to products, like
customer-facing code.
- Tools team: This type of SRE team tends to focus on building
software to help their developer counterparts measure, maintain, and
improve system reliability or other aspects of SRE work, such as
capacity planning.
- Product/Application team: This type of SRE team works to improve
the reliability of a critical application or business area. We
recommend this implementation for organizations that already have a
Kitchen Sink, Infrastructure, or Tools-focused SRE team and have a
key user-facing application with high reliability needs.
- Embedded team: This team has SREs embedded with their developer
counterparts, usually one per developer team in scope. The work
relationship between the embedded SREs and developers tends to be
project- or time-bounded and usually very hands-on, where they
perform work like changing code and configuration of the services in
scope.
- Consulting team: This implementation is very similar to the
embedded implementation, except SRE are usually less hands-on. We
recommend staffing one or two part-time consultants before you staff
your first SRE team.

- Organizations with high SRE maturity have well-documented and
user-centric SLOs, error budgets, blameless postmortem culture, and
a low tolerance for toil.
- Engineers with operations experience and systems administrators
with scripting experience are good first SREs to hire.
- Upskill current team members with necessary SRE skills such as
operations and software engineering, monitoring systems, production
automation, system architecture, troubleshooting, culture of trust, and
incident management.
- Contact your Account Executive or Account Director to learn how the
Google Cloud Professional Services team can support your
organization’s adoption of SRE.

How to build an SRE team
https://www.blameless.com/blog/how-to-build-an-sre-team
You don’t need SRE. What you need is SRE.
https://sdarchitect.blog/2020/02/20/you-dont-need-sre-what-you-need-is-sre/

https://queue.acm.org/detail.cfm?id=3404974


## SLI, SLO, SLA and Error Budgets

- Reliability: The number of “good” interactions divided by the number of total interactions. This leaves you with a numerical fraction of real users who experience a service that is available and working.
- Error budget: The amount of unreliability you are willing to tolerate.
- Service level indicator (SLI): A quantifiable measure of the reliability of your service from your users' perspective.
- Service level objective (SLO): Sets the target for an SLI over a period of time.

The Art of SLOs workshop
https://landing.google.com/sre/resources/practicesandprocesses/art-of-slos/
Setting SLOs: a step-by-step guide
https://cloud.google.com/blog/products/management-tools/practical-guide-to-setting-slos
Building good SLOs—CRE life lessons
https://cloud.google.com/blog/products/gcp/building-good-slos-cre-life-lessons
SRE fundamentals: SLIs, SLAs and SLOs
https://cloudplatform.googleblog.com/2018/07/sre-fundamentals-slis-slas-and-slos.html
The Art of SLOs Handbook letter
https://static.googleusercontent.com/media/landing.google.com/en//sre/static/pdf/art-of-slos-handbook-letter.pdf
SRE and the art of SLOs at the DevOpsDays 2019 Chicago: https://youtu.be/fWvNzDVOJDE
SLO with GKE at Equifax: https://cloud.withgoogle.com/next/sf/sessions?session=OPS200
- CUJ: critical user journey
    - _specific steps that a user takes to accomplish goals_
- SLI: service level indicator
    - _a well-defined measure of successful enough_
- SLO: service level objective
    - _a top-line target for fraction of successful interactions_
- SLA: service level agreement
    - _consequences_
- Error Budgets
    - _inverse of availability: amount of errors allowed based on SLAs_

Error Budget = 1 - SLA; removes major source SRE-DEV conflict (it's a math problem, not an opinion or power conflict)
Error Budget Policy is what you agree to do when the application exceeds it's error budget. This is not pay $$$. Must be something that will visibly improve reliability.
Example: until the application is again meeting its SLO and has some Error Budget:
- No new features launches allowed
- Sprint planning may only pull postmortem action items from the backlog
- Software Development Team must meet with SRE Team daily to outline their improvements
SRE Principle #1:
- Any organisation, even without hiring a single SRE can have an Error Budget Policy
- This is any leverage you can use to keep your customers from experience pain using your application
- you can implement this today: measure, account and act.



SLOs for GKE services
https://youtu.be/wB9AKdPDv0Q

https://github.com/ocervell/slo-repository
https://github.com/ocervell/slo-generator-gke

## Where to start?

[Introduction: How Google runs Production systems](https://landing.google.com/sre/sre-book/chapters/introduction/)
[Developing a Google SRE Culture](https://www.coursera.org/learn/developing-a-google-sre-culture)

Experienced SREs:
- are comfortable with failure
- eliminate ambiguity with monitoring
- establish and document processes

Reduce organizational silos with SLOs and Error Budgets

Unify vision, foster collaboration and communications, and share knowledge

1. Establish SLOs
    - Developers and business owners should work together to define service-level objectives that can be met most months. Consider starting with on application or major project.
2. Blameless postmortems
    - Google found that establishing a culture of blameless postmortems results in more reliable systems and is critical to creating and maintaining a successful SRE organization.
3. Form an SRE Team
    - Start with an advocate for SRE within an organization and decide how to embed them, such as within development, operations or horizontally (consulting) across teams. Evaluate the pros/cons of each model.

> Making tomorrow better than today.
- SLOs and Error Budgets are the first step
- The next step is staffing an SRE role
- Real responsibility
- Defining and refining the SLOs
- Making sure that the application meets the reliability for its end users

Project Work for SRE Team:
- Consulting on System Architecture and Design
- Authoring and iterating on Monitoring
- Automation of repetitive work
- Coordinating implementation of postmortem action items

> SREs have time to make tomorrow better than today.

Sharing responsibility: providing an SRE team some way of giving back-pressure to their dev partners provides balance.

- Give 5% of the operational work to the developers: on-call shifts, rollout management, ops tasks.
- Track the project work of the SRE team: if it's not delivering completed projects: there's something wrong
- Analyse new production systems and only on-board them if they can be operated safely
- If every problem with a system has to be esacalated to its developer: give the pager to the developer instead.
- an SRE organisation within a company needs a mandate
- without leadership buy-in, it can not work
- when applications miss their SLOs and run out of Error Budget: it puts additional load on the SRE team: need to devote more company resources to addressing reliability concerns or loosen the SLO.
- fixing a product after launch is always more expensive

The SRE Principles:
- SRE needs SLOs, with consequences
- SREs have time to make tomorrow better than today
- SRE teams have the ability to regulate their workload

New Relic's Two Roles:
- Pure SRE: build and support our core internal platform, container fabric, networking systems
- Embedded SRE: partner with Eng. Teams Domain Experts in Reliability, Tooling and Scaling

## SRE Books

https://landing.google.com/sre/books/

Building Secure & Reliable Systems

[The Site Reliability Workbook](https://landing.google.com/sre/workbook/toc/) - _hands-on companion to the Site Reliability Engineering book and uses concrete examples to show how to put SRE principles and practices to work._

## Technical Implementations

Implementing GCP Stackdriver and Adapting SRE Practices to Samsung’s AI System (Cloud Next '19)
https://youtu.be/45UoGDxuwto
SLOs with Stackdriver Service Monitoring
https://medium.com/google-cloud/slos-with-stackdriver-service-monitoring-62f193147b3f
Automating Application Dashboard Creation for Services on GKE/Istio
https://medium.com/google-cloud/automating-application-dashboard-creation-for-services-on-gke-istio-a55a5a79aa15
SRE Classroom: Distributed PubSub
https://cloud.google.com/blog/products/devops-sre/join-sre-classroom-nalsd-workshops
https://landing.google.com/sre/resources/practicesandprocesses/sre-classroom/

## Complementary and further resources

Gauge the effectiveness of your DevOps organization running in Google Cloud
https://cloud.google.com/blog/products/devops-sre/another-way-to-gauge-your-devops-performance-according-to-dora
Achieving Resiliency on Google Cloud
https://youtu.be/DplYhUrADao
--> priority on user activities
--> don't just try to avoid failures
SRE: The Cloud Native Approach to Operations by Container Solutions:
https://info.container-solutions.com/sre-the-cloud-native-approach-to-operations-e-book
Coursera - Site Reliability Engineering: Measuring and Managing Reliability
https://www.coursera.org/learn/site-reliability-engineering-slos
Know thy enemy: how to prioritize and communicate risks—CRE life lessons
https://cloud.google.com/blog/products/gcp/know-thy-enemy-how-to-prioritize-and-communicate-risks-cre-life-lessons
Coursera - Site Reliability Engineering: Measuring and Managing Reliability
https://www.coursera.org/learn/site-reliability-engineering-slos
Really great intro: Optimizing SRE Effectiveness at The New York Times (Cloud Next '19)
https://youtu.be/QCRe-Vo-PPo
Site Reliability Engineering (SRE) 101 with DevOps vs SRE
https://www.cncf.io/blog/2020/07/17/site-reliability-engineering-sre-101-with-devops-vs-sre/

Hope you enjoyed all this walkthrough and resources about Site Reliability Engineering (SRE) and hope you will find few tips that will inspire you for your own company, projects or role.

Cheers!


Why What How
building blocks for reliable systems: SRE best practices, SLI/SLO/SLA and Error budget