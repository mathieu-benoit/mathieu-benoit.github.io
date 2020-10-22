---
title: cloud adoption framework with gcp
date: 2020-10-21
tags: [gcp, inspiration]
description: let's go through resources such as the google cloud adoption framework, cloud center of excellence, the google cloud setup checklist and best practices for enterprise organizations and eventually the google cloud security foundations guide
aliases:
    - /gcp-caf/
---
[![](https://storage.googleapis.com/gweb-cloudblog-publish/images/Google_Blog_CloudMigration_B_L8be8Js.max-2200x2200.jpg)](https://storage.googleapis.com/gweb-cloudblog-publish/images/Google_Blog_CloudMigration_B_L8be8Js.max-2200x2200.jpg)

The [Google Cloud Adoption Framework](https://cloud.google.com/adoption-framework/) builds a structure on the rubric of people, process, and technology that you can work with, providing a solid assessment of where you are in your journey to the cloud and actionable programs that get you to where you want to be. It’s informed by Google’s own evolution in the cloud and many years of experience helping customers. This [Google Cloud Adoption Framework whitepaper](https://services.google.com/fh/files/misc/google_cloud_adoption_framework_whitepaper.pdf) goes through the following concepts:
- 4 cloud adoption themes: Lean, Lead, Scale, Secure
- 3 maturity phases: Tactical, Strategic, Transformational

Which is heading us to this interesting resource: [Managing change in the Cloud](https://services.google.com/fh/files/misc/managing_change_in_the_cloud.pdf). Organizations will only realize the full potential of new technology if employees use it, if they know how to make the most of it, and if they are empowered to do things differently than before:
1. Focus on the people, and all else will follow
2. Measure, measure, measure — so you’ll know if you’ve been successful
3. Be clear about the critical capabilities you will need in the future, and where you’ll get them — either internally or through your partner(s)
4. Fast is better than slow. But finding your balance between central control and agility can be hard
5. Sweat the basics: people will look to you for guidance
6. Ensure that there is a "nontech" learning plan available
7. Start thinking about the longer-term tech skills, now
8. Appeal to self-interest and growth
9. Things won’t be perfect the first time
10. Share what you learn along the way, both the positive and the negative

Another important aspect is the notion of Cloud Center of Excellence (CCoE), I found [this whitepaper about CCoE](https://services.google.com/fh/files/misc/cloud_center_of_excellence.pdf) very instructive.
> A well-appointed CCOE begins with a small team who understands the [Google Cloud Adoption Framework](https://cloud.google.com/adoption-framework/) and is able to use it as a guide for implementing cloud technology aligned with a business’s goals and strategy. The CCOE team then becomes the conduit for transforming the way that the other internal teams serve the business in the transition to the cloud.
> The most successful CCOE teams are: Multidisciplinary, Empowered, Visionary, Agile, Technical, Engaged, Cloud-centric, Integrated, Hands-on and Small.


Complementery to this, I also found very insightful such external articles:
- [Building a CCOE in 2020: 13 Pitfalls and Practical Steps](https://www.contino.io/insights/cloud-centre-of-excellence-2020)
    - Think of a CCoE as an enablement function. On the one hand, a CCoE is there to provide a product (i.e. the cloud) but on the other hand it exists to enable consumers (i.e. the product and development teams) to consume this product. It does this by providing a set of repeatable standards, governance frameworks and best practices for the rest of the business to follow during the cloud migration. At Contino, they recommend using [Simon Wardley’s organisational model](https://medium.com/wardleymaps/getting-started-yourself-e1a359b785a2) of Town Planners, Settlers and Pioneers (PST) to tailor and model the products and services being offered by the CCoE. The ‘PST’ model uses a cell-based organisational structure in which there are three groups of consumers that represent different levels of cloud maturity.
- [Why Organizations Choose a Multicloud Strategy by Gartner](https://www.gartner.com/smarterwithgartner/why-organizations-choose-a-multicloud-strategy/)
    - Most organizations adopt a multicloud strategy out of a desire to avoid vendor lock-in or to take advantage of best-of-breed solutions
- [Hybrid & Multi Cloud](https://www.contino.io/insights/multi-cloud)
- [A case against “Platform Teams”](https://kislayverma.com/organizations/a-case-against-platform-teams/)


Where to start with your Google Cloud Foundation? Here comes the [Google Cloud setup checklist](https://cloud.google.com/docs/enterprise/onboarding-checklist) and the associated illustrations with [Best practices for enterprise organizations](https://cloud.google.com/docs/enterprise/best-practices-for-enterprise-organizations). These resources will get you started with Identity, Governance, Security, Networking, etc. and all aspects you need to have in place for your GCP Foundation.

[Cost Control and Financial Governance Best Practices (Cloud Next '19)](https://youtu.be/MM4wZ5JwYdE) is great feedback from Deloitte, Etsy, Broad Institute, and Vendasta on how they are managing their businesses on GCP and increasing the predictability of their cloud costs with financial governance policies, controls, and cost optimizations. Build proactive alerts, dashboard and reports visible to a broad list of stakeholders: transparency, shared responsibilities, encourage collaboration, etc.
{{< youtube MM4wZ5JwYdE >}}

[Cloud is Complex. Managing It Shouldn’t Be](https://cloud.withgoogle.com/next/sf/sessions?session=CMP100#infrastructure). Active Assist is making it easier for customers to manage their cloud efficiently and securely with smart analytics and machine learning built into Google Cloud itself. Learn how to better understand your cloud, prevent problems, and get actionable insights and recommendations on how to optimize and improve your environment with the tools that Google provides:
{{< youtube A2tvDIfevos >}}

Now do you want to go more technical and hands-on? Here you are with the [Google Cloud security foundations guide](https://services.google.com/fh/files/misc/google-cloud-security-foundations-guide.pdf)!
> The goal of this security foundations blueprint is to provide you with curated, opinionated guidance and accompanying automation that helps you build a secure starting point for your Google Cloud deployment. This security foundations blueprint covers the following: Google Cloud organization structure, Authentication and authorization, Resource hierarchy and deployment, Networking (segmentation and security), Logging, Detective controls and Billing setup.

I addition to this, you have this [Rapid cloud foundation buildout and workload deployment using Terraform](https://cloud.google.com/blog/products/devops-sre/using-the-cloud-foundation-toolkit-with-terraform) walkthrough leveraging the same [Cloud Foundation Toolkit Terraform example foundation](https://github.com/terraform-google-modules/terraform-example-foundation). I hightly invite you to play with it and reuse it!



That's it for now! Hope you enjoyed this one giving pointers and thoughts about Google Cloud Adoption Framework, Cloud Center of Excellence, Google Cloud setup checklist and Google Cloud Security foundations.

Further and complementary resources:
- [Cloud migration: What you need to know (and where to find it)](https://cloud.google.com/blog/products/cloud-migration/guide-to-all-google-cloud-migration-guides)
- [GCP Training](https://cloud.google.com/training)
- [Google Cloud for Azure professionals](https://cloud.google.com/docs/compare/azure)
- [Google Cloud for AWS Professionals](https://cloud.google.com/docs/compare/aws)

Cheers!