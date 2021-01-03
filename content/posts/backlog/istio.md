---
title: fixme
date: 2020-08-10
tags: [fixme]
description: fixme
draft: true
aliases:
    - /fixme/
---
https://www.istiobyexample.dev/

https://youtu.be/LFfAGDMvJG8

Incrementally Adopting Istio (Cloud Next '19)
https://youtu.be/0cgTHQFXYPQ

[Building Globally Scalable Services with Istio and ASM](https://youtu.be/clu7t0LVhcw)
All about multi clusters pattern and distributed services. Ameer does a really great job to explain the advantages and responsibilities to come from monolith, going to microserives, embracing service mesh to what's the value of Istio and Anthos Service Mesh. In other words, that's the presentation you need if you would like to understand what's a service mesh, and why you may need one (or not)!
Pointing to complementary resources:
- [Kubernetes Engine (GKE) multi-cluster life cycle management series](http://bit.ly/gke-multicluster-lifecycle)
- [ASM Workshop](http://bit.ly/asm-workshop)

[Hands-on Lab: Managing Traffic Routing with Istio and Envoy](https://cloudonair.withgoogle.com/events/next20-studyjam/watch?talk=w7-talk-2) [[Youtube](https://youtu.be/J0bEeh5P9hE)]
    - A 50 min video walking through this Qwiklabs lab: [Managing Traffic Routing with Istio and Envoy](https://www.qwiklabs.com/focuses/8456?parent=catalog).

Extending your Istio service mesh across GKE clusters and Compute Engine instances
https://cloud.google.com/solutions/extend-istio-service-mesh-across-gke-clusters-compute-instances

Canary deployments with Istio
https://youtu.be/CmZWau04ZS4

https://github.com/GoogleCloudPlatform/microservices-demo

https://cloud.google.com/anthos/service-mesh
https://cloud.google.com/blog/topics/anthos/anthos-service-mesh-deep-dive
https://cloud.google.com/blog/products/networking/welcome-to-the-service-mesh-era-introducing-a-new-istio-blog-post-series
https://youtu.be/SMhTI0Pjn1Q
https://youtu.be/7cINRP0BFY8

Understanding SLOs and Error Budgets With Istio (Cloud Next '19)
https://youtu.be/AKh8uuVCpFI

https://codelabs.developers.google.com/codelabs/cloud-hello-istio/index.html?index=..%2F..index#0
https://codelabs.developers.google.com/codelabs/cloud-istio-aspnetcore-part1/#0

https://cloud.google.com/istio
https://istio.io/latest/docs/examples/bookinfo/

https://youtu.be/CFtGi1M8BIM

https://youtu.be/QyxQfW-Izs8

https://youtu.be/7cINRP0BFY8

Emoji Vote from Linkerd
https://linkerd.io/2/getting-started/

Service proxies provide features between the microservices comprising a cloud-native app within a Kubernetes cluster. These features usually include the following:
Service discovery
When a microservice needs to make a request of another microservice, the first microservice’s service proxy needs to find an instance of the second microservice that can handle the request. In some cases the instance also needs to have particular characteristics or attributes. In a dynamic, distributed system with large numbers of microservices, service discovery is a significant undertaking.
Resilience
These may include implementing any or all of the resilience strategies for traffic management discussed in Chapter 3, like load balancing, timeouts, deadlines, and circuit breakers, as well as others on behalf of the service proxy’s microservice. Resilience also includes verifying that the desired microservice instances are available and sending requests on behalf of the service proxy’s microservice to the right place.
Observability
A service proxy can observe each request and reply that it receives. It can also collect telemetry data, such as on the performance or health of its microservice. Most importantly, it can collect metrics about the traffic itself, such as throughput, latency, and failure rates.
Security
A service proxy can identify requests and replies that violate policies and stop them from being passed through. Other security features service proxies may provide include authenticating the identity of other microservices and enforcing access control policies based on the authenticated identity.

Service Mesh Technologies
Envoy Proxy is a popular choice for service meshes to use as their data plane. Originally developed by Lyft, Envoy Proxy is now a Cloud-Native Computing Foundation project, with hundreds of contributors from many companies such as AirBnb, Amazon, Microsoft, Google, Pinterest, and Salesforce.

Examples of Envoy-based service meshes include:

Consul
Consul is an open source software project stewarded by HashiCorp.
Istio
Istio is an open source project from Google, IBM, and Lyft.
Kuma
Kuma is a service mesh control plane implementation. Kuma is provided by Kong Inc.
Linkerd is a non-Envoy-based service mesh that uses its own proxy, linkerd2-proxy. Linkerd is hosted by the Cloud Native Computing Foundation (CNCF).

When Do You Need a Service Mesh?
Not every cloud-native app deployed with microservices needs a service mesh. In fact, many apps do not need a service mesh, and adding a service mesh to them might actually do more harm than good. Here are two important factors you should consider when deciding whether a service mesh is right for a particular situation.
The number of microservices
If your app has a small number of microservices, the benefits of using a service mesh will be limited. Say that your app has two microservices. There’s not much a service mesh can do to improve resilience and observability from their existing states.
As the number of microservices in an app increases, the growing complexity of the app makes a service mesh more beneficial for supporting resilience, observability, and security among all the microservices and their interrelationships.
The microservice topology
This refers to the flows of the microservices being called and calling each other. In a shallow topology, there’s not much interaction directly between microservices; most requests come from outside the cluster. Service meshes usually don’t provide much value in shallow topologies because their primary purpose is to handle service-to-service requests.
In deeper microservice topologies, with many microservices sending requests to other microservices, which in turn send requests to other microservices, and so on, service meshes can be invaluable in having visibility into these requests, as well as securing the communications and adding resilience features to prevent cascading failures and other issues.
If you’re not sure if a service mesh is needed for a particular situation, consider if an Ingress controller alone may be sufficient. There is some overlap in the features provided by Ingress controllers and service meshes, particularly for resilience and observability.
The biggest difference between Ingress controllers and service meshes is that in a service mesh, you control all communication between the microservices; with an Ingress controller, you don’t. An implication of that is when you adopt a service mesh, it will affect the development of your microservices and app. With an Ingress controller, there’s no such impact.

https://kiali.io/