---
title: fasten your seatbelt, and turn autopilot mode on
date: 2021-03-01
tags: [containers, gcp, kubernetes, security]
description: let's see in actions the new gke's autopilot mode
aliases:
    - /autopilot/
---
GKE just got a new mode: [Autopilot](https://cloud.google.com/blog/products/containers-kubernetes/introducing-gke-autopilot)! :rocket:

> The future of Kubernetes is here, Node-less.

{{< youtube id="_JKsv2BtAnY" title="Introducing GKE Autopilot" >}}

> With Autopilot, you no longer have to monitor the health of your nodes or calculate the amount of compute capacity that your workloads require. Autopilot supports most Kubernetes APIs, tools, and its rich ecosystem. You stay within GKE without having to interact with the Compute Engine APIs, CLIs, or UI, as the nodes are not accessible through Compute Engine, like they are in Standard mode. You pay only for the CPU, memory, and storage that your Pods request while they are running.

Autopilot:
- is GA :metal:
- is GKE
- is the a GKE mode, [see the differences with the Standard mode](https://cloud.google.com/kubernetes-engine/docs/concepts/autopilot-overview#comparison)
- brings the concept of Nodeless Kubernetes
- provides a [Pod level SLA](https://cloud.google.com/kubernetes-engine/sla) (Pods in Multi Zones, Autopilot cluster is regional)
- has a [per Pod billing](https://cloud.google.com/kubernetes-engine/pricing) (per second for vCPU, memory and disk resource requests)
  - Is it going to be cheaper per month than GKE Standard, certainly not. But it will for sure get you have a lower TCO and help you set best practices with your workloads on Kubernetes.
- is pre-configured with an optimized cluster configuration that is ready for production workloads with: [COS-containerd](https://cloud.google.com/kubernetes-engine/docs/concepts/node-images#cos-variants), [VPC-native](https://cloud.google.com/kubernetes-engine/docs/concepts/alias-ips), [Workload Identity](https://cloud.google.com/kubernetes-engine/docs/how-to/workload-identity), [Shielded nodes](https://cloud.google.com/kubernetes-engine/docs/how-to/shielded-gke-nodes), [Secure boot](https://cloud.google.com/kubernetes-engine/docs/how-to/shielded-gke-nodes#secure_boot), [NodeLocal DNSCache](https://cloud.google.com/kubernetes-engine/docs/how-to/nodelocal-dns-cache)
- upgrades automatically your nodes, [see more information here](https://cloud.google.com/kubernetes-engine/docs/concepts/cluster-upgrades-autopilot#automatic_upgrades)
- won't answer all your needs, there is [Workloads](https://cloud.google.com/kubernetes-engine/docs/concepts/autopilot-overview#limits), [Security](https://cloud.google.com/kubernetes-engine/docs/concepts/autopilot-overview#security_limitations) and [other](https://cloud.google.com/kubernetes-engine/docs/concepts/autopilot-overview#other_limitations) limitations, so you may need to still use the Standard edition with more controls.
    - In my case with [my own GKE cluster](https://github.com/mathieu-benoit/mygkecluster), I will keep the Standard mode for now because I'm using [Confidential Computing]({{< ref "/posts/2020/10/confidential-computing.md" >}}), [Binary Authorization]({{< ref "/posts/2020/11/binauthz.md" >}}), [ACM]({{< ref "/posts/2021/01/config-sync.md" >}}), [ASM](https://cloud.google.com/anthos/service-mesh) and [Config Connector](https://cloud.google.com/config-connector/docs/overview) which are not yet supported by the Autopilot mode. Looking forward to it, stay tuned!

Let's see [how to create your first GKE Autopilot](https://cloud.google.com/kubernetes-engine/docs/how-to/creating-an-autopilot-cluster) in actions:
```
gcloud container clusters create-auto $CLUSTER_NAME \
    --region $REGION \
    --project $PROJECT_ID
```

Here are the other options you may want to leverage too:
```
--cluster-ipv4-cidr
--cluster-secondary-range-name
--cluster-version
--create-subnetwork
--network
--release-channel
--services-ipv4-cidr
--services-secondary-range-name
--subnetwork
--enable-master-authorized-networks
--master-authorized-networks
--enable-private-endpoint
--enable-private-nodes
--master-ipv4-cidr
--scopes
--service-account
```

For example, to have a more secure Autopilot cluster, you want to provide [your own `--service-account` with least privileges]({{< ref "/posts/2020/10/gke-service-account.md" >}}). Using `--enable-private-endpoint` and `--enable-private-nodes` could be a good thing to improve your security posture too.

And from there, that's just business as usual, you could retrieve your GKE cluster credentials `gcloud container clusters get-credentials $CLUSTER_NAME --region $REGION --project $PROJECT_ID` and then do your `kubectl` commands to be able to interact with your cluster.

Now let's see what we have in place once this Autopilot is deployed:
```
$ kubectl get nodes -o wide
NAME                                          STATUS   ROLES    AGE     VERSION             OS-IMAGE                             KERNEL-VERSION   CONTAINER-RUNTIME
gk3-my-autopilot-default-pool-a1a187e2-nrlq   Ready    <none>   2m38s   v1.18.12-gke.1210   Container-Optimized OS from Google   5.4.49+          containerd://1.4.1
gk3-my-autopilot-default-pool-fbc0f3a4-h6z5   Ready    <none>   2m37s   v1.18.12-gke.1210   Container-Optimized OS from Google   5.4.49+          containerd://1.4.1

$ kubectl top nodes
NAME                                          CPU(cores)   CPU%   MEMORY(bytes)   MEMORY%   
gk3-my-autopilot-default-pool-a1a187e2-nrlq   100m         10%    599Mi           21%       
gk3-my-autopilot-default-pool-fbc0f3a4-h6z5   69m          7%     605Mi           21% 

$ kubectl get ns
NAME                STATUS   AGE
default             Active   5m48s
gatekeeper-system   Active   5m6s
kube-node-lease     Active   5m50s
kube-public         Active   5m50s
kube-system         Active   5m50s
```

Doing a `kubectl describe node` could show us that Autopilot's Node type is `e2-medium` (2 vCPUs, 4 GB memory). We could also see that our nodes are spread across the different zones (`topology.kubernetes.io/zone=us-east4-a`) of our Autopilot cluster's region (`topology.kubernetes.io/region=us-east4`). You may want to leverage the [Pod affinity or anti-affinity](https://cloud.google.com/kubernetes-engine/docs/concepts/autopilot-overview#pod_affinity_and_anti-affinity) with your workloads if you would like to avoid cross-zones communications between your Pods (like you will have to deal with any regional Kubernetes cluster). 

Interestingly, another best practice GKE Autopilot brings to you is using [OPA Gatekeeper](https://www.openpolicyagent.org/docs/latest/kubernetes-introduction/) via [Policy Controller](https://cloud.google.com/anthos-config-management/docs/concepts/policy-controller) to be able to apply its own policies (you can't change anything here, so JFYI), `kubectl get ConstraintTemplates -n gatekeeper-system`:
```
autogkeallowlistedworkloadlimitation    31m
autogkecsrlimitation                    31m
autogkegpulimitation                    31m
autogkehostnamespaceslimitation         31m
autogkehostpathvolumes                  31m
autogkehostportlimitation               31m
autogkelinuxcapabilitieslimitation      31m
autogkemanagednamespaceslimitation      31m
autogkenodeaffinityselectorlimitation   31m
autogkenodelimitation                   31m
autogkepodaffinitylimitation            31m
autogkepodlimitconstraints              31m
autogkepolicycrdlimitation              31m
autogkeprivilegedpodlimitation          31m
autopilotexternaliplimitation           31m
autopilotvolumetypelimitation           31m
```

Now let's try to deploy our first app in there:
```
$ kubectl create deployment hello-app --image=gcr.io/google-samples/hello-app:1.0
$ kubectl describe pods -l app=hello-app
...
Containers:
  hello-app:
    Image:      gcr.io/google-samples/hello-app:1.0
    Limits:
      cpu:                500m
      ephemeral-storage:  1Gi
      memory:             2Gi
    Requests:
      cpu:                500m
      ephemeral-storage:  1Gi
      memory:             2Gi
...
Events:
  Type     Reason            Age                From                                   Message
  ----     ------            ----               ----                                   -------
  Warning  FailedScheduling  52m (x2 over 52m)  gke.io/optimize-utilization-scheduler  0/2 nodes are available: 2 Insufficient cpu.
  Normal   TriggeredScaleUp  52m                cluster-autoscaler                     pod triggered scale-up
  Warning  FailedScheduling  51m (x2 over 51m)  gke.io/optimize-utilization-scheduler  0/3 nodes are available: 1 Insufficient ephemeral-storage, 2 Insufficient cpu.
  Warning  FailedScheduling  51m (x3 over 51m)  gke.io/optimize-utilization-scheduler  0/3 nodes are available: 1 node(s) had taint {node.kubernetes.io/not-ready: }, that the pod didn't tolerate, 2 Insufficient cpu.
  Normal   Scheduled         51m                gke.io/optimize-utilization-scheduler  Successfully assigned default/hello-app-87bbb7d45-54dlt to gk3-my-autopilot-default-pool-a1a187e2-xlzp
  Normal   Pulling           51m                kubelet                                Pulling image "gcr.io/google-samples/hello-app:1.0"
  Normal   Pulled            51m                kubelet                                Successfully pulled image "gcr.io/google-samples/hello-app:1.0"
  Normal   Created           51m                kubelet                                Created container hello-app
  Normal   Started           50m                kubelet                                Started container hello-app
```

We could see we got few `FailedScheduling` events to eventually get the `hello-app` Pod deployed until a new Node is provisioned. `kubectl get nodes` will show you this new 3rd node. Why's that?!
Actually, in the way we deployed our `hello-app`, we didn't provide any `resources.requests`, so by default [Autopilot assigns half-a-CPU, 2 GiB of RAM and 1 GiB of storage to a pod](https://cloud.google.com/kubernetes-engine/docs/concepts/autopilot-overview#default_container_resource_requests).

Now as a good practice, it's recommended to set your own granular and optimal `resources.requests`. After running the example below, you could see with `kubectl get pods -o wide` that you have some of the `my-app` pods running on existing nodes and not involving the creation of new nodes.
```
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
spec:
  replicas: 6
  selector:
    matchLabels:
      run: my-app
  template:
    metadata:
      labels:
        run: my-app
    spec:
      containers:
      - name: hello-app
        image: gcr.io/google-samples/hello-app:1.0
        resources:
            requests:
              cpu: 10m
              memory: 10Mi
EOF
```

What we could see also is that our Pod got this annotation [`seccomp.security.alpha.kubernetes.io/pod: runtime/default`](https://kubesec.io/basics/metadata-annotations-seccomp-security-alpha-kubernetes-io-pod/) injected, [which enforces a hardened configuration for your Pods with Autopilot](https://cloud.google.com/kubernetes-engine/docs/concepts/autopilot-overview#container_isolation). `securityContext.capabilities.drop: NET_RAW` is also applied on our Pod for us.

Complementary resources:
- [GKE on Autopilot, Databricks on GKE and Multi-Cluster Service](https://www.linkedin.com/pulse/gke-autopilot-databricks-more-srikanth-desikan/)
- [Autopilot Architecture](https://cloud.google.com/kubernetes-engine/docs/concepts/autopilot-architecture)
- [Autopilot cluster upgrades](https://cloud.google.com/kubernetes-engine/docs/concepts/cluster-upgrades-autopilot)
- [Forbes - Google Makes Kubernetes Invisible In The Cloud With GKE Autopilot](https://www.forbes.com/sites/janakirammsv/2021/02/26/google-makes-kubernetes-invisible-in-the-cloud-with-gke-autopilot)
- [How to use GitLab with GKE Autopilot](https://about.gitlab.com/blog/2021/02/24/gitlab-gke-autopilot/)

That's a wrap! Hope you enjoyed that one, happy sailing and enjoy turning your GKE Autopilot mode on! ;)