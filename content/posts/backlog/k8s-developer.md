---
title: kubernetes developer, is it a/one thing?
date: 2021-11-26
tags: [gcp, kubernetes, containers, thoughts]
description: let's see how to improve your cloud security posture with workload identity federation, no service account keys necessary anymore - let's see taht in actions with GitHub actions.
draft: true
aliases:
    - /k8s-developer/
    - /kubernetes-developer/
    - /k8s-developer/
---
What's a Kubernetes developer? What does they cover? What's their job? What do they do?

Let's be more specific, does a Kubernetes developer role even exist?

Actually, no.

_Note: here, I'm not talking about someone contributing to Kubernetes upstream, I'm talking about someone who has a persona or a role as developer and who is leveraging the Kubernetes as a platform._

Let's be more specific, one person, unicorn, superwoman or superman being an expert and dealing with everything related to Kubernetes is not possible.

My journey with Kubernetes started in 2017. At that time, I worked at Microsoft, I learned about both Docker and Kubernetes. I approached this with my application developer eyes. It was hard. I felt that Docker was amazing as a universal application packager. Awesome, pure best practice for DevOps. But for Kubernertes, I was like, why everyone is talking about this? Is it really a thing? Why this open source project started by Google, is now the defacto containers orchestrator adopted by the planet and even making competitors like RedHat, Suse, VMware, Microsoft, Amazon, Apple, Google, etc. working together?! I mean, there is something going on for sure there.

I studied hard, I worked hard and I got mentors who were able to answers my questions when I got them. And the community out there, just awesome, everyone wiht the same goal, and the same mindset to share while learning and improve the platform.

That's where I found out 2 things:
- Kubernetes is more an infrastructure play where Security, Networking, Infrastructure concepts are important.
- Kubernetes itself is not an end goal, it's a plateforme where tools on top of it or in addition to it will simplify how application developers

That was key here for me.

FIXME - experiences with 3 customers (developers) I just touched the containerisation and CI/CD parts. It took some times to have them digesting those new concepts and paradigms. But we failed, because we didn't touch other areas around Kubernetes such as the monitoring, security, infrastucture, networking and governance parts. It took s

When I joined Google in 2020, it was a good timing for me to reflect with all of that. Anthos was a thing at that time and to be honest I didn't get it at the first place.

FIXME - SRE
- concept of developer
- navigating resources, eager to automate or document

And that's where I came with this presentation https://github.com/mathieu-benoit/sail-sharp describing the different personas involved with Kubernetes as a platform.

FIXME - I recently worked with a mature Startup who had such personas in place. They are serious about automation, security without compromise and in the meantime making sure the developers are shipping code often with quality, without doing Kubernetes themselves.

## Apps developers

Should be focus on shipping code and features to add value to the end users. The could build web app, mobile app, apis, machine learning models, etc. They could develop with C#, Java, Golang, Python, Rust, etc. Whatever, they shouldn't deal with Kubernetes manifests! But they are encouraged to leverage Docker on their local workstation. They commit code in Git repositories.

What?! Is it kind of a silo and an anti-pattern to DevOps? Nop. The point here is you are an expert in Android, Javascript, Python notebook, etc. to ship code in Production, that's it. Again you shouldn't do Kubernetes, there is too much to cover there, just focus on what you are recognized for as expert and actually paid for.

## Apps operators



## Security operators

## Platform operators

## Services operators

## Infrastructure operators


There is more personas for sure, for example an overall Governance operator or a Financial operator are very important too as you will scale with Kubernetes.

So again, you may tell you that's just silos and anti-pattern to DevOps, but it isn't. Kubernetes is more than pure joy, it's pure DevOps in the sense that's the defacto platform making sure all the stakeholders and personas just illustrated will work toward the same goal with the same platform.

FIXME - each persona is a developer, maybe link to SRE?