---
title: security with microsoft azure
date: 2019-05-15
tags: [azure, security]
description: let's go through all the security concept in azure to nurture your security posture
---
Security in IT is important.
Security in IT is the matter and the responsibility of everyone, every stakeholders. Not just for security professionals, not just for SecOps.
In IT solutions implementation, Security is like UnitTests, IntegrationTests, LoadTests and Monitoring, they are always low priority in the backlog. Something we postpone by thinking "_we will do that later, just before going live, in Production_" or even worst "_it's not important_"... big mistake! You won't do that later because you will be focused on new features and bug fix...

When implementing any IT solutions we should always have in mind best practices like:
- **Reduce the surface of vulnerabilities**
    - _For example: don't expose publicly the stuffs which don't need to be publicly accessible._
- **Start with least privileges and zero trust approach**
    - _For example: don't give broad access and roles to user or automation tools, just grant them access to what they need to do._
- **Segment the network design**
    - _For example: use Network Security Group (NSG) to segment your infrastructure_

Microsoft is taking Security very seriously like you could read with the [Microsoft Cyber Defense Operations Center](https://www.microsoft.com/msrc/cdoc).  

> _The Cyber Defense Operations Center brings together security response experts from across the company to help protect, detect, and respond to threats in real-time. Staffed with dedicated teams 24x7, the Center has direct access to thousands of security professionals, data scientists, and product engineers throughout Microsoft to ensure rapid response and resolution to security threats._

But Security is a shared responsibility, on your end, you could also leverage these resources and learn more about Security at Microsoft, especially with Microsoft Azure:
- [Microsoft Security](https://www.microsoft.com/security)
- [Azure Security](https://docs.microsoft.com/azure/security/)
- [Microsoft Trust Center](https://www.microsoft.com/trustcenter/security/azure-security)

[![](https://2.bp.blogspot.com/-UaEFRGNHXa4/XN2EgfKu-wI/AAAAAAAAS-4/kHYESCHDf7wZSWJaO3p62ru0httjRZoFwCLcBGAs/s640/ProtectDetectRespond.PNG)](https://2.bp.blogspot.com/-UaEFRGNHXa4/XN2EgfKu-wI/AAAAAAAAS-4/kHYESCHDf7wZSWJaO3p62ru0httjRZoFwCLcBGAs/s1600/ProtectDetectRespond.PNG)

The [Microsoft Cybersecurity Reference Architecture](https://aka.ms/MCRA) provides an interesting landscape of the Microsoft security products and services:

[![](https://3.bp.blogspot.com/-Yh59KPPoVts/XNzLDnzZInI/AAAAAAAAS-s/GuK7EWVDE6oPuoEUmZLtTx0mFnbOEseLgCLcBGAs/s640/MCRA.PNG)](https://3.bp.blogspot.com/-Yh59KPPoVts/XNzLDnzZInI/AAAAAAAAS-s/GuK7EWVDE6oPuoEUmZLtTx0mFnbOEseLgCLcBGAs/s1600/MCRA.PNG)

You will tell me that's a lot, too much! Where to start in Azure? I recommend starting with [Azure Security Center and Azure Sentinel](https://azure.microsoft.com/en-us/blog/securing-the-hybrid-cloud-with-azure-security-center-and-azure-sentinel).
Give [Azure Security Center](https://azure.microsoft.com/services/security-center) a try, it's free to start! And check out your [Secure score](https://docs.microsoft.com/azure/security-center/security-center-secure-score), what does it tell you?
The secret is to start earlier than later and start small. Add quick fix tasks and user stories as security implementations in your backlog. You could also watch this //build 2019 session [DIY Azure Security Assessments](https://mybuild.techcommunity.microsoft.com/sessions/77141), it will help you building your own backlog/todo list.
You could also have a look at the new [Azure Sentinel service](https://azure.microsoft.com/services/azure-sentinel), the cloud native SIEM service, very promising.
If you are doing Docker and Kubernetes, with [Azure Kubernetes Service](https://azure.microsoft.com/services/kubernetes-service), you have different concepts and tools to setup, here are 3 pointers for you to get started:  
- [Azure webinar series- Help Deliver Applications Securely with DevSecOps](https://info.microsoft.com/ww-ondemand-help-deliver-applications-securely-with-devsecops-us.html)
- [Enterprise security in the era of containers and Kubernetes](https://mybuild.techcommunity.microsoft.com/sessions/77061)
- [Azure Kubernetes Services: Container Security for a Cloud Native World](https://info.cloudops.com/azure-kubernetes-services-container-security)

Further resources:  
- [Mark Simos's list](https://aka.ms/markslist)
- [Beyond the GDPR](https://info.microsoft.com/ww-landing-CMPL-Beyond-the-GDPR-ebook.html)
- [Security Practice Development](https://assets.microsoft.com/mpn-security-playbook.pdf)
- [Get Started With Developing Rich Security Applications](https://mybuild.techcommunity.microsoft.com/sessions/77800)
- [Stopping threats with WAF at the edge](https://mybuild.techcommunity.microsoft.com/sessions/77284)
- [DIY Azure Security Assessments](https://mybuild.techcommunity.microsoft.com/sessions/77141)

Do you want to practice with those tools and services? Do you want some hands-on experience? Here you are with those workshops, labs & trainings:
- [Microsoft CISO Workshop](https://aka.ms/CISOWorkshop)
- [How to Effectively Perform an Azure Security Center PoC](https://techcommunity.microsoft.com/t5/Security-Identity/How-to-Effectively-Perform-an-Azure-Security-Center-PoC/m-p/516874)
- [Microsoft Cloud Workshop - Security baseline on Azure](https://github.com/Microsoft/MCW-Security-baseline-on-Azure)
- [Microsoft Learn - Secure your cloud data Learning Path](https://docs.microsoft.com/learn/paths/secure-your-cloud-data/)
- [Microsoft Learn - Security, responsibility and trust in Azure](https://docs.microsoft.com/learn/modules/intro-to-security-in-azure/)

Certifications:
- [MS-500: Microsoft 365 Security Administration](https://www.microsoft.com/learning/exam-MS-500.aspx)
- [AZ-500: Microsoft Azure Security Technologies](https://www.microsoft.com/learning/exam-az-500.aspx)

Stay safe!