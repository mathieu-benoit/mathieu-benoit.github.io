---
title: istio sidecar to reduce istio proxy resource consumption
date: 2021-12-01
tags: [security, kubernetes, service-mesh]
description: let's see how you could leverage the istio sidecar to reduce istio proxy resource consumption
aliases:
    - /istio-sidecar/
---
> [`Sidecar`](https://istio.io/latest/docs/reference/config/networking/sidecar/) describes the configuration of the sidecar proxy that mediates inbound and outbound communication to the workload instance it is attached to. By default, Istio will program all sidecar proxies in the mesh with the necessary configuration required to reach every workload instance in the mesh, as well as accept traffic on all the ports associated with the workload. The `Sidecar` configuration provides a way to fine tune the set of ports, protocols that the proxy will accept when forwarding traffic to and from the workload. In addition, it is possible to restrict the set of services that the proxy can reach when forwarding outbound traffic from workload instances.

Typically, if you run this command below, you will find out that any pod in your mesh will have all the services endpoints on its proxy configuration, which could land with performance (CPU and memory) issues as you will scale with the number of workloads in your cluster:
```
namespace=your-namespace
app=your-app-label
istioctl proxy-config clusters $(kubectl -n $namespace get pod -l app=$app -o jsonpath={.items..metadata.name}) \
    -n $namespace
```

This video shows you concretely in action how the `Sidecar` resource could help you with high resource consumption of the Istio proxy:
{{< youtube id="JcfLUHdntN4" title="Istio 1.1 Review: Istio Sidecar resource to reduce memory overhead">}}

Based on that, you should at least have this `Sidecar` for your cluster, it will apply for all of your namespaces:
```
cat <<EOF | kubectl apply -f -
apiVersion: networking.istio.io/v1beta1
kind: Sidecar
metadata:
  name: default
  namespace: istio-system
spec:
  egress:
  - hosts:
    - "./*"
    - "istio-system/*"
EOF
```
You could then apply other more fine granular `Sidecar` resource per namespace if you need other configuration in there.

If you run again the previous `istioctl pc c` command you will now see that the list of endpoints is very small.

You could find below additional resources to illustrate this:
- [Watch Out for This Istio Proxy Sidecar Memory Pitfall](https://medium.com/geekculture/watch-out-for-this-istio-proxy-sidecar-memory-pitfall-8dbd99ea7e9d)
- [Reducing Istio proxy resource consumption with outbound traffic restrictions](https://banzaicloud.com/blog/istio-sidecar/)

_Note: `Sidecar` is not supported yet by Istio `Gateway` resources, so this is not working with [my `asm-ingress` namespace](https://github.com/mathieu-benoit/my-kubernetes-deployments/tree/main/namespaces/asm-ingress)._

Hope you enjoyed that one, stay safe and healthy out there!