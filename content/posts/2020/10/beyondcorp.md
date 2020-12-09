---
title: zero trust security model with google's beyondcorp
date: 2020-10-09
tags: [gcp, security]
description: let's see how google shared best practices and technologies about its own zero trust security model, beyondcorp
aliases:
    - /beyondcorp/
    - /iap/
---
[![](https://storage.googleapis.com/gweb-cloudblog-publish/images/BeyondCorps_high-level_architecture.max-900x900.jpg)](https://storage.googleapis.com/gweb-cloudblog-publish/images/BeyondCorps_high-level_architecture.max-900x900.jpg)

Have you heard about [BeyondCorp or ZeroTrust security model](https://cloud.google.com/beyondcorp)?

Here you are for a quick visual introduction: [What is BeyondCorp? What is Identity Aware Proxy (IAP)](https://medium.com/google-cloud/what-is-beyondcorp-what-is-identity-aware-proxy-de525d9b3f90)?
{{< youtube TtmsV-xq0r0 >}}

By reading this whitepaper [BeyondCorp: A New Approach to Enterprise Security, 2014](https://research.google/pubs/pub43231/), we could learn that BeyondCorp is a security-oriented engineering effort which begun in 2012 to re-architect the Google Corp network to remove any privileges granted solely on the basis of having a Corp IP, instead basing authentication on more secure factors.

> Virtually every company today uses firewalls to enforce perimeter security. However, this security model is problematic because, when that perimeter is breached, an attacker has relatively easy access to a company’s privileged intranet. As companies adopt mobile and cloud technologies, the perimeter is becoming increasingly difficult to enforce. Google is taking a different approach to network security. We are removing the requirement for a privileged intranet and moving our corporate applications to the Internet.

Why Zero Trust Networks?
- Lateral movement is much harder
    - Each service has to authenticated - internal netwrok is not permissive
- Stolen credentials are less valuable
    - Strong auth requirements increases cost of cred theft and MITM attacks
- Known vulnerabilities that are easy to exploit will be rarer
    -Increased ecosystem hygiene
- Non-targeted attacks have less value
    - Forces targeted attacks - higher cost to attacker

[Identity Aware Proxy (IAP)](https://cloud.google.com/iap) is one of the components of the BeyondCorp security model and lets you establish a central authorization layer for applications accessed by HTTPS. Problems it solves:
- May remove need for VPN
    - Hard to configure, arguably secure, does not implement zero-trust
- Access by Contractor (can't install VPN Client)
    - Some Companies implement SSL VPN - normally a webpage hosted on a NGFW
- Save costs
    - Utilizing VPN normally means paying for agents installed on devices + sizing large NGFWs due to the encryption they need to support hundreds of users
- Reduce latency

> IAP can help you control access to your public cloud apps, your on-prem apps and your VMs running on Google Cloud. IAP works by verifying a users’s identity and considering the context of their request to determine if they should be allowed access. This is one building block in the zero trust model of access, an enterprise security model that enables every employee to work from untrusted networks without the use of a VPN.

Here is visual demonstration of IAP and Access Context Manager for both HTTPS (web app) and SSH/TCP (VM) resources:
{{< youtube RC5IhUF1618 >}}

And here are concrete implementations of IAP if you are looking for more examples:
- [How to ssh into your GCE machine without a public IP](https://medium.com/google-cloud/how-to-ssh-into-your-gce-machine-without-a-public-ip-4d78bd23309e)
- [Control access to your web sites with Identity-Aware Proxy](https://cloud.google.com/blog/topics/developers-practitioners/control-access-your-web-sites-identity-aware-proxy)
- [Verify the identity and context of a client before serving an App Engine app](https://medium.com/google-cloud/beyond-corp-in-a-bottle-uncorked-5e8c7acce52)
- [Use BeyondCorp with any identity provider and any back-end](https://medium.com/google-cloud/zero-trust-for-enterprise-cooking-up-some-access-controls-cfd05ba54d12)

Still a bit confused about how to get started with BeyondCorp and IAP? Here you are:
{{< youtube goAWiQGRefw >}}


Further and complementary resources:
- [Google Cloud Security Showcase](https://cloud.google.com/security/showcase)
- [Democratizing Zero Trust with an expanded BeyondCorp Alliance](https://cloud.google.com/blog/products/identity-security/google-cloud-announces-new-partners-in-its-beyondcorp-alliance)
- [How Google adopted BeyondCorp](https://security.googleblog.com/2019/06/how-google-adopted-beyondcorp.html)
- [Preparing for a BeyondCorp world at your company](https://cloud.google.com/blog/products/gcp/preparing-beyondcorp-world-your-company)
- [Keep your teams working safely with BeyondCorp Remote Access](https://cloud.google.com/blog/products/identity-security/keep-your-teams-working-safely-with-beyondcorp-remote-access)
- [Towards Zero Trust at GitLab.com (Cloud Next '19)](https://youtu.be/DrPiCBtaydM)
    - GitLab sharing lessons learned like implementing Zero Trust is always ongoing, each roadmap can be built independently, build root mechanisms first - order matters (central SSO, etc.), UX matters, serious automation will be needed, one size does not fill all (org requirements may differ), your mileage may vary (mature environments are more challenging).
- [How Airbnb Secured Access to Their Cloud With Context-Aware Access (Cloud Next '19)](https://youtu.be/Sq9gp8KBsY0)
    - Airbnb deployed IAP in front of AWS + on prem backends to manage access to LOB web apps, G Suite, and GCP resources with context-aware access enabling stronger security posture, anywhere access, and more intuitive end-user experiences.
- [BeyondCorp Beyond Google by Veolia (Cloud Next '18)](https://youtu.be/ei1CxF1BHh4)
    - After exposing their Cloud strategy, Veolia is illustrating how they are leveraging Google's BeyondCorp concept especially with IAP.

Hope you enjoyed this blog article, and hope it's giving you some ideas about how to modernize your way to implement your Zero Trust security model when dealing with accessing internal web apps, APIs, GSuite, VMs, etc.

Cheers and stay safe!