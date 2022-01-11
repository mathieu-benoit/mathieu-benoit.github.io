---
title: lessons learned from the log4shell cves
date: 2021-12-23
tags: [gcp, kubernetes, containers, security]
description: let's see what we could learn on a kubernetes point of view from the log4shell cves
aliases:
    - /log4shell/
---
Wow, the IT security world was on fire. LinkedIn and Twitter feeds were almost just talking about that: The commonly used [Apache Log4j 2 library has been compromised](https://logging.apache.org/log4j/2.x/security.html). 5 CVEs have been reported to date: [CVE-2021-44228](https://nvd.nist.gov/vuln/detail/CVE-2021-44228), [CVE-2021-45046](https://nvd.nist.gov/vuln/detail/CVE-2021-45046), [CVE-2021-45105](https://nvd.nist.gov/vuln/detail/CVE-2021-45105), [CVE-2021-4104](https://nvd.nist.gov/vuln/detail/CVE-2021-4104) and [CVE-2021-44832](https://nvd.nist.gov/vuln/detail/CVE-2021-44832).

Google has been providing their findings of ongoing investigations for both [Google](https://security.googleblog.com/2021/12/apache-log4j-vulnerability.html) and [Google Cloud](https://cloud.google.com/log4j2-security-advisory) products and services:

The [Google Cybersecurity Action Team provides recommendations and solutions](https://cloud.google.com/blog/products/identity-security/recommendations-for-apache-log4j2-vulnerability) available to Google Cloud customers and security teams to manage the risk of the Apache Log4j 2 vulnerability. You will find in there concrete examples with Cloud Armor, Chronicle, Cloud IDS, Security Command Center, Container scanning, Binary Authorization, Cloud Logging and Apigee.

Impacted or not by those current events, there is some lessons learned that we could leverage to make sure that whatever languages used by the developers, there is tools in place to detect, protect and remediate such compromised dependencies. In the context of containers and Kubernetes, here are 4 easy ways to help with this:
- [Update dependencies]({{< ref "#update-dependencies" >}})
- [Scan containers]({{< ref "#scan-containers" >}})
- [Protect Ingress]({{< ref "#protect-ingress" >}})
- [Restrict Egress]({{< ref "#restrict-egress" >}})

## Update dependencies

The second section of the recent article [The past, present, and future of Kubernetes with Eric Brewer](https://cloud.google.com/blog/products/containers-kubernetes/the-rise-and-future-of-kubernetes-and-open-source-at-google) highlights a very important security aspect regarding to the dependencies of applications:

> As the number of dependencies used in software development grows, the security risks multiply. Investing in software supply chain security is imperative, and a move towards managed services is actually safer than self-managed solutions.

> 99% of our vulnerabilities are not in the code you write in your application. They’re in a very deep tree of dependencies, some of which you may know about, some of which you may not know about.

If you are using GitHub, you could leverage [GitHub’s security features like `dependabot` and `CodeQL`](https://github.blog/2021-12-14-using-githubs-security-features-identify-log4j-exposure-codebase/) to help identify exposure in your codebase.

As an example, you could leverage `dependabot` on any GitHub repository just by creating this `.github/dependabot.yml` file to check updates on both your containers base images in your `Dockerfile` as well as your `gradle` packages ([here is the list of all available packages ecosystem](https://docs.github.com/en/code-security/supply-chain-security/keeping-your-dependencies-updated-automatically/configuration-options-for-dependency-updates#package-ecosystem)):
```
cat <<EOF > .github/dependabot.yml
version: 2
updates:
  - package-ecosystem: "docker"
    directory: "/"
    schedule:
      interval: "daily"
  - package-ecosystem: "gradle"
    directory: "/"
    schedule:
      interval: "daily"
EOF
```

You could read and learn more [here](https://security.googleblog.com/2021/12/understanding-impact-of-apache-log4j.html) about the impact of Apache Log4j 2 vulnerabilities and the packages depending on it. In addition to understand how widespread are those vulnerabilities, you will also learn more about the initiatives such as [Secure Open Source Rewards](https://sos.dev/) and [Open Source Insights](https://deps.dev/) driven by Google.

## Scan containers

Scanning your containers as early as possible, at least from within your [Continuous Integration pipelines]({{< ref "/posts/2021/09/container-scanning.md" >}}) to block any critical vulnerabilities, is also very key to secure and trust your software supply chain.

If you [scan a Java container](https://cloud.google.com/container-analysis/docs/java-scanning) having those Log4j 2 vulnerabilities by running this command `gcloud artifacts docker images scan --additional-package-types=MAVEN`, you will be able to get the following information:
```
CRITICAL            9.3         projects/goog-vulnz/notes/CVE-2021-44228    org.apache.logging.log4j:log4j-api    2.13.3        2.15.0
CRITICAL            5.1         projects/goog-vulnz/notes/CVE-2021-45046    org.apache.logging.log4j:log4j-api    2.13.3        2.16.0
HIGH                4.3         projects/goog-vulnz/notes/CVE-2021-45105    org.apache.logging.log4j:log4j-api    2.13.3        2.17.0
MEDIUM              6.0         projects/goog-vulnz/notes/CVE-2021-44832    org.apache.logging.log4j:log4j-api    2.13.3        2.17.1
```

In addition to that, you could use [Binary Authorization]({{< ref "/posts/2020/11/binauthz.md" >}}) by leveraging the [vulnerability-based attestations feature](https://cloud.google.com/binary-authorization/docs/creating-attestations-kritis) too.

Another important aspect is to scan your containers actually running on your Kubernetes clusters, for example with GKE you could leverage the [Container Thread Detection](https://cloud.google.com/security-command-center/docs/concepts-container-threat-detection-overview) feature from Security Command Center. A new [Active Scan: Log4j Vulnerable to RCE rule](https://cloud.google.com/release-notes#December_21_2021) has been launched too.

## Protect Ingress 

Web Application Firewalls (WAF) are often the first option for protecting and mitigating vulnerabilities that require HTTP transport. [Google Cloud Armor]({{< ref "/posts/2021/04/cloud-armor.md" >}}) helps protect your applications and websites against denial of service (DDOS) and web attacks (WAF).

Google Cloud Armor customers can now deploy a [new preconfigured WAF rule](https://cloud.google.com/blog/products/identity-security/cloud-armor-waf-rule-to-help-address-apache-log4j-vulnerability) that will help detect and, optionally, block attempted exploits of CVE-2021-44228 and CVE-2021-45046:
```
gcloud compute security-policies rules create 12345 \
    --security-policy $securityPolicyName \
    --expression "evaluatePreconfiguredExpr('cve-canary')" \
    --action "deny-403" \
    --description "CVE-2021-44228 and CVE-2021-45046"
```

From there, you could look at the denied logs generated by this rule via [Cloud Logging](https://cloud.google.com/logging/docs/log4j2-vulnerability):
```
filter="resource.type=\"http_load_balancer\" "\
"jsonPayload.enforcedSecurityPolicy.name=\"${securityPolicyName}\" "\
"httpRequest.requestUrl=~\"jndi\" "\
"OR httpRequest.userAgent=~\"jndi\" "\
"OR httpRequest.referer=~\"jndi\""
gcloud logging read \
    --project $projectId \
    "$filter" \
    --format='table(httpRequest.requestUrl)'
```

## Restrict Egress

Because the compromised Apache Log4j 2 fetches malicious variables over the network, filtering your workload's egress connections is key to mitigate and protect your entire platform. To accomplish a defense in depth security setup, there is three layers of features you could leverage: Private GKE cluster with NAT Gateway, Kubernetes Network Policies and Istio Egress Gateway.

First, [Private GKE clusters](https://cloud.google.com/kubernetes-engine/docs/concepts/private-cluster-concept) will guarantee that your nodes don't have any public IPs which will avoid any egress communications. To define outbound internet access for certain private nodes you can use [Cloud NAT](https://cloud.google.com/kubernetes-engine/docs/how-to/private-clusters#private-nodes-outbound).

Second, [Kubernetes Network Policies]({{< ref "/posts/2019/09/calico.md" >}}) will allow you to restrict egress from your applications. For example, the following example illustrates how to deny all egress in the namespace `your-namespace`:
```
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-all
  namespace: your-namespace
spec:
  podSelector: {}
  policyTypes:
  - Egress
```
With GKE Dataplane V2 you could even leverage the logging capabilities to get the `deny` logs, I illustrated this in my blog [ebpf and cilium, to bring more security and more networking capabilities in gke]({{< ref "/posts/2021/04/gke-cilium.md" >}}).

_Note: if you want to set DNS based policies, you will need to leverage [Cilium Network Policy](https://isovalent.com/blog/post/2021-12-log4shell) or the [FQDNNetworkPolicies](https://github.com/GoogleCloudPlatform/gke-fqdnnetworkpolicies-golang)._

Third, [Egress Gateway with your service mesh](https://istio.io/latest/blog/2019/egress-traffic-control-in-istio-part-3/#performance-considerations), directing all the egress traffic through it, and allocating public IPs to the egress gateway nodes allows the application nodes to access external services in a controlled way.
The most important security aspect for a service mesh is probably ingress traffic like we saw earlier in this blog article. You definitely must prevent attackers from penetrating the cluster through ingress APIs. Having said that, securing the traffic leaving the mesh is also very important. Once your cluster is compromised, and you must be prepared for that scenario, you want to reduce the damage as much as possible and prevent the attackers from using the cluster for further attacks on external services and legacy systems outside of the cluster. To achieve that goal, you need secure control of egress traffic.

Looking for a concrete implementation with the 3 of them together with GKE? Here is the [high-level guide](https://cloud.google.com/service-mesh/docs/security/egress-gateways-best-practices) and its [tutorial companion](https://cloud.google.com/service-mesh/docs/security/egress-gateway-gke-tutorial).


## Complementary and further resources

- [Container Security: Building trust in your software supply chain](https://cloudonair.withgoogle.com/events/container-security)
- [Zero-Day Exploit Targeting Popular Java Library Log4j by GovCERT.ch](https://www.govcert.ch/blog/zero-day-exploit-targeting-popular-java-library-log4j/)
- [The Nightmare Before Christmas: Looking Back at Log4j Vulnerabilities](https://blog.aquasec.com/log4j-vulnerabilities-overview)
- [CVE-2021-44228 aka Log4Shell Vulnerability Explained by Aqua](https://blog.aquasec.com/cve-2021-44228-log4shell-vulnerability-explained)
- [Log4Shell in a nutshell (for non-developers & non-Java developers) by Snyk](https://snyk.io/blog/log4shell-in-a-nutshell/)
- [Log4Shell remediation cheat sheet by Snyk](https://snyk.io/blog/log4shell-remediation-cheat-sheet/)
- [Threat Alert: Tracking Real-World Log4j Attacks by Aqua](https://blog.aquasec.com/real-world-log4j-attacks-analysis)
- [Google Cloud IDS signature updates help detect Apache Log4j vulnerabilities](https://cloud.google.com/blog/products/identity-security/cloud-ids-to-help-detect-cve-2021-44228-apache-log4j-vulnerability)
- [Detecting and responding to Apache “Log4j 2” using Google Chronicle](https://chroniclesec.medium.com/detecting-and-responding-to-apache-log4j-2-cve-2021-44228-using-google-chronicle-ec77d676eaea)

Hope you enjoyed that one to improve your security posture, sail safe out there!