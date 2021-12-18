---
title: cloud armor to protect your apps deployed on gke
date: 2021-04-30
tags: [security, gcp, kubernetes, service-mesh]
description: let's see how you could protect your apps deployed on gke against denial of service and web attacks
aliases:
    - /gke-cloud-armor/
    - /cloud-armor/
---
{{< youtube id="w6Z5Ps0rXvk" title="What is Cloud Armor in a one-pager">}}

> [Google Cloud Armor](https://cloud.google.com/armor) helps protect your applications and websites against denial of service (DDOS) and web attacks (WAF).

{{< youtube id="oXJ68Sa8jfU" title="How You Can Protect Your Web Sites and Applications with Google Cloud Armor">}}

Let's see in actions how we could leverage Cloud Armor with GKE.

## Cloud Armor policies

First, we need to define a [security policy](https://cloud.google.com/armor/docs/configure-security-policies), the following example uses a preconfigured rule to mitigate cross-site scripting (XSS) attacks:
```
securityPolicyName="my-security-policy"
gcloud compute security-policies create $securityPolicyName \
    --description "Block XSS attacks"
gcloud compute security-policies rules create 1000 \
    --security-policy $securityPolicyName \
    --expression "evaluatePreconfiguredExpr('xss-stable')" \
    --action "deny-403" \
    --description "XSS attack filtering"
```
> Google Cloud Armor's [preconfigured WAF rules](https://cloud.google.com/armor/docs/rule-tuning) (OWASP Top 10 mitigation, etc.) can be added to a security policy to detect and deny unwelcome layer 7 requests containing SQLi or XSS attempts. Google Cloud Armor detects malicious requests and drops them at the edge of Google's infrastructure. The requests are not proxied to the backend service, regardless of where the backend service is deployed.

To analyze suspicious requests you can enable Cloud Armor’s [verbose logging](https://cloud.google.com/armor/docs/request-logging) capability in the relevant policy. With verbose logging enabled, Cloud Armor’s logs will contain additional information about where in the incoming request the suspicious signature appeared as well as a snippet of the suspicious signature and the field it appeared in.
```
gcloud compute security-policies update $securityPolicyName \
    --log-level=VERBOSE
```

We could also leverage the [Adaptive Protection](https://cloud.google.com/armor/docs/adaptive-protection-use-cases) feature currently in Preview.
> The most common use case for Adaptive Protection is detecting and responding to L7 DDoS attacks such as HTTP GET floods, HTTP POST floods, or other high frequency HTTP activities. L7 DDoS attacks often start relatively slow and grow in intensity over time. By the time humans or automated spike detection mechanisms detect an attack, it is likely to be high in intensity and already having a strong negative impact on the application.
```
gcloud compute security-policies update $securityPolicyName \
    --enable-layer7-ddos-defense
```

From here, you could attach this security policy to any [`backend-service`](https://cloud.google.com/armor/docs/configure-security-policies#attach-policies). The next sections will walk your through how to do that with GKE.

## Cloud-native load balancer with GKE

The default load balancer for a `Service` or an `Ingress` on GKE is the external TCP/UDP (L4) load balancer, what we want to do here, is to expose them via an [external HTTP(S) load balancer (L7)](https://cloud.google.com/kubernetes-engine/docs/concepts/ingress). The latter provides integration with edge services like Identity-Aware Proxy (IAP), Google Cloud Armor, and Cloud CDN, as well as a globally distributed network of edge proxies. For this, you need to provision your GKE cluster with the `--enable-ip-aliases` parameter, then add the `cloud.google.com/neg: '{"ingress": true}'` annotation on your `Service` and finally have an `Ingress` to [actually generate the necessary resources underneath](https://cloud.google.com/kubernetes-engine/docs/concepts/service-networking#understanding_load_balancing).

## Cloud Armor in front of GKE Ingress

Once you have configured a Google Cloud Armor security policy, you can [reference it using a `BackendConfig`](https://cloud.google.com/kubernetes-engine/docs/how-to/ingress-features#cloud_armor):
```
apiVersion: cloud.google.com/v1
kind: BackendConfig
metadata:
  name: my-backendconfig
spec:
  securityPolicy:
    name: $securityPolicyName
```

Then associate this `BackendConfig` to your `Service` with the `neg` annotation:
```
apiVersion: v1
kind: Service
metadata:
  name: my-service
  annotations:
    cloud.google.com/neg: '{"ingress": true}'
    cloud.google.com/backend-config: '{"default": "my-backendconfig"}'
...
```

Finally we could deploy the `Ingress` which will create the GCLB, etc.
```
apiVersion: networking.k8s.io/v1beta1
kind: Ingress
metadata:
  name: my-ingress
spec:
  backend:
    serviceName: my-service
...
```

From here, your Ingress is now protected by Cloud Armor, you could test the associated public IP generated: `kubectl get ingress my-ingress`.

## Cloud Armor in front of Istio or Anthos Service Mesh

Deploying external L7 load balancing outside of the mesh along with a mesh ingress layer offers significant advantages, especially for internet traffic. Even though Anthos Service Mesh (ASM) and Istio ingress gateways provide advanced routing and traffic management in the mesh, some functions are better served at the edge of the network. Taking advantage of internet-edge networking through Google Cloud's External HTTP(S) Load Balancing might provide significant performance, reliability, or security-related benefits over mesh-based ingress.

![Illustration of the L7 load balancing in front of the Service Mesh on GKE.](https://cloud.google.com/architecture/images/exposing-service-mesh-apps-through-gke-ingress-topology.svg)

To accomplish this with ASM we need to adapt a little bit the setup we previously discussed.

The `BackendConfig` needs to be adjusted by specifying custom health checks for the mesh ingress proxies. Anthos Service Mesh and Istio expose their [sidecar proxy health checks](https://istio.io/latest/docs/ops/deployment/requirements/#ports-used-by-istio) on port 15021 at the `/healthz/ready` path. Custom health check parameters are required because the serving ports (80 and 443) of mesh ingress proxies is different from their health check port (15021).
```
apiVersion: cloud.google.com/v1
kind: BackendConfig
metadata:
  name: ingress-backendconfig
spec:
  healthCheck:
    requestPath: /healthz/ready
    port: 15021
    type: HTTP
  securityPolicy:
    name: $securityPolicyName
```

Then, we need to create an `IstioOperator` overlay file which will be used later when we will run the `asmcli` script:
```
cat <<EOF > ingress-backendconfig-operator.yaml
---
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  profile: empty # Do not install CRDs or the control plane
  components:
    ingressGateways:
    - name: asm-ingressgateway
      namespace: asm-ingress
      enabled: true
      label:
        # Set a unique label for the gateway. This is required to ensure Gateways
        # can select this workload
        asm: ingressgateway
      k8s:
          service:
            type: ClusterIP
          serviceAnnotations:
            cloud.google.com/backend-config: '{"default": "ingress-backendconfig"}'
            cloud.google.com/neg: '{"ingress": true}'
  values:
    gateways:
      istio-ingressgateway:
        # Enable gateway injection
        injectionTemplate: gateway
EOF
```

And now we could run the [`asmcli`](https://cloud.google.com/service-mesh/docs/unified-install/install) script:
```
./asmcli \
    --project_id ${PROJECT} \
    --cluster_name ${CLUSTER_NAME} \
    --cluster_location ${CLUSTER_LOCATION} \
    --enable_all \
    --custom_overlay ingress-backendconfig-operator.yaml
```

Here, you could make sure that everything is well deployed by running those commands:
```
kubectl wait --for=condition=available --timeout=600s deployment --all -n istio-system
kubectl wait --for=condition=available --timeout=600s deployment --all -n asm-system
kubectl wait --for=condition=available --timeout=600s deployment --all -n asm-ingress
```

Finally we could deploy the `Ingress` in the `asm-ingress` namespace which will create the GCLB, etc.
```
cat <<EOF > asm-ingressgateway-ingress.yaml
kind: Ingress
metadata:
  name: asm-ingressgateway
  namespace: asm-ingress
spec:
  defaultBackend:
    service:
      name: asm-ingressgateway
      port:
        number: 80
  rules:
  - http:
      paths:
      - path: /*
        pathType: ImplementationSpecific
        backend:
          service:
            name: asm-ingressgateway
            port:
              number: 80
EOF
kubectl apply -f asm-ingressgateway-ingress.yaml
```

From here, your ASM's Ingress Gateway is now protected by Cloud Armor, you could test the associated public IP generated: `kubectl get ingress asm-ingressgateway -n asm-ingress`.

If you are looking for more advanced scenario with this setup, here you are:
- [From edge to mesh: Exposing service mesh applications through GKE Ingress](https://cloud.google.com/architecture/exposing-service-mesh-apps-through-gke-ingress)
- [Secure your apps and your cluster with Anthos Service Mesh]({{< ref "/posts/2021/11/asm-security.md" >}})

## Cloud Logging on HTTP Load Balancer

An important piece from here is to have access to the [Google Cloud Armor logs](https://cloud.google.com/armor/docs/configure-security-policies#enabling_https_request_logging) by security policy name, match rule priority, associated action, and related information logged as part of logging for HTTP(S) Load Balancing.

Here is the `gcloud` command you could run to get the associated `DENY` requests:
```
filter="resource.type=\"http_load_balancer\" "\
"jsonPayload.enforcedSecurityPolicy.name=\"${securityPolicyName}\" "\
"jsonPayload.enforcedSecurityPolicy.outcome=\"DENY\""

gcloud logging read --project $projectId "$filter"
```
_Note: in the output, you could look at the fields `userAgent`, `requestMethod` and `requestUrl` to see what kind of attacks you are now blocking._

## Further and complementary resources

- [OWASP Top 10 mitigation options on Google Cloud](https://cloud.google.com/architecture/owasp-top-ten-mitigation)
- [Meeting the Challenges of Securing Modern Web Applications with WAAP](https://services.google.com/fh/files/misc/esg_google_waap_wp.pdf)
- [Better together: Google Cloud Load Balancing, Cloud CDN, and Google Cloud Armor](https://cloud.google.com/blog/products/networking/using-cloud-armor-and-cloud-cdn-with-your-google-load-balancer)
- [Qwiklabs - HTTP Load Balancer with Cloud Armor](https://www.qwiklabs.com/focuses/1232?parent=catalog)
- [From edge to mesh: Exposing service mesh applications through GKE Ingress](https://cloud.google.com/architecture/exposing-service-mesh-apps-through-gke-ingress)
- [Google Cloud Armor Standard versus Managed Protection Plus](https://cloud.google.com/armor/docs/managed-protection-overview#standard_versus_plus)
- [Cloud Armor pricing](https://cloud.google.com/armor/pricing)
- [GKE Ingress features comparison](https://cloud.google.com/kubernetes-engine/docs/how-to/ingress-features)
- [Exponential growth in DDoS attack volumes](https://cloud.google.com/blog/products/identity-security/identifying-and-protecting-against-the-largest-ddos-attacks)

That's a wrap! That's how you are adding more security in front of your public endpoints against denial of service and web attacks.

Hope you enjoyed that one, stay safe out there, cheers!