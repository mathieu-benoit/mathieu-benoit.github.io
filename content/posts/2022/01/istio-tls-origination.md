---
title: istio tls origination to secure memorystore (redis) access
date: 2022-01-16
tags: [gcp, service-mesh, kubernetes, security]
description: let's see how we could secure the access of memorystore (redis) via istio tls origination, without changing any code in the application
aliases:
    - /istio-tls-origination/
---
I recently watched this [IstioCon 2021 session: Redis TLS Origination with the sidecar](https://events.istio.io/istiocon-2021/sessions/redis-tls-origination-with-the-sidecar/). 

Very inspiring. Without any change in the code of your apps you could configure Istio to help you do the encrypted connection to an external redis instance. Wow! More security, less impact for developers!

> [TLS origination](https://istio.io/latest/docs/tasks/traffic-management/egress/egress-tls-origination/#tls-origination-for-egress-traffic) occurs when an Istio proxy (sidecar or egress gateway) is configured to accept unencrypted internal HTTP connections, encrypt the requests, and then forward them to HTTPS servers that are secured using simple or mutual TLS. This is the opposite of TLS termination where an ingress proxy accepts incoming TLS connections, decrypts the TLS, and passes unencrypted requests on to internal mesh services.

From this, my idea was about to secure the Memorystore (redis) access and again, without any code change, the `istio-proxy` of the application would transparently upgrade the connection to TLS.

> [Memorystore for Redis supports encrypting all Redis traffic](https://cloud.google.com/memorystore/docs/redis/in-transit-encryption) using the Transport Layer Security (TLS) protocol. When in-transit encryption is enabled Redis clients communicate exclusively across a secure port connection. Redis clients that are not configured for TLS will be blocked. If you choose to enable in-transit encryption you are responsible for ensuring that your Redis client is capable of using the TLS protocol.

After some research and tests to adapt this IstioCon session to use Memorystore (redis), it turned out that there was 2 main differences:
1. An [internal (private) IP address](https://cloud.google.com/memorystore/docs/redis/networking#supported_and_unsupported_networks) is exposing the instance, there is no DNS.
1. A [Certificate Authority](https://cloud.google.com/memorystore/docs/redis/in-transit-encryption#certificate_authority) should be installed on the client machine accessing the Redis instance.

So here is the full step-by-step guide in order to make it working accordingly.

Let's create a Memorystore (redis) instance allowing only in-transit encryption:
```
GKE_REGION=us-east4
GKE_ZONE=us-east4-a
REDIS_NAME=redis-tls
gcloud redis instances create $REDIS_NAME --size=1 --region=$GKE_REGION --zone=$GKE_ZONE --redis-version=redis_6_x --transit-encryption-mode=SERVER_AUTHENTICATION
REDIS_IP=$(gcloud redis instances describe $REDIS_NAME --region=$GKE_REGION --format='get(host)')
REDIS_PORT=$(gcloud redis instances describe $REDIS_NAME --region=$GKE_REGION --format='get(port)')
gcloud redis instances describe $REDIS_NAME --region=$GKE_REGION --format='get(serverCaCerts[0].cert)' > redis-cert.pem
```

Notes:
- You can connect to a Memorystore (redis) instance from GKE clusters that are in the same region and use the same network as your instance.
- You cannot connect to a Memorystore (redis) instance from a GKE cluster without VPC-native/IP aliasing enabled.
- In-transit encryption is only available at creation time of your Memorystore (redis) instance. There is a [connections limit](https://cloud.google.com/memorystore/docs/redis/in-transit-encryption#connection_limits_for_in-transit_encryption) when using it. The Certificate Authority is valid for 10 years, [rotation every 5 years](https://cloud.google.com/memorystore/docs/redis/in-transit-encryption#certificate_authority_rotation).

Create the dedicated `Namespace` with Istio/ASM sidecar injection enabled:
```
NAMESPACE=redis-tls
ISTIO_REV=FIXME
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Namespace
metadata:
  name: ${NAMESPACE}
  labels:
    istio.io/rev: ${ISTIO_REV}
EOF
```

Create a `Secret` with the Certificate Authority generated previously:
```
kubectl create secret generic redis-cert --from-file=redis-cert.pem -n $NAMESPACE
```

From there we could create `ServiceEntry` and `DestinationRule` allowing to expose this external endpoint in the mesh with a TLS origination setup:
```
INTERNAL_HOST=redis.memorystore-redis
cat <<EOF | kubectl apply -n $NAMESPACE -f -
apiVersion: networking.istio.io/v1beta1
kind: ServiceEntry
metadata:
  name: external-redis
spec:
  hosts:
  - ${INTERNAL_HOST}
  addresses:
  - ${REDIS_IP}/32
  endpoints:
  - address: ${REDIS_IP}
  location: MESH_EXTERNAL
  resolution: STATIC
  ports:
  - number: ${REDIS_PORT}
    name: tcp-redis
    protocol: TCP
EOF
cat <<EOF | kubectl apply -n $NAMESPACE -f -
apiVersion: networking.istio.io/v1beta1
kind: DestinationRule
metadata:
  name: external-redis
spec:
  exportTo:
  - '.'
  host: ${INTERNAL_HOST}
  trafficPolicy:
    tls:
      mode: SIMPLE
      caCertificates: /etc/certs/redis-cert.pem
EOF
```

Now, let's actually deploy a client which will be able to mount the `redis-cert` secret via its `istio-proxy` sidecar:
```
cat << EOF | kubectl apply -n $NAMESPACE -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: redis-client
  labels:
    app: redis-client
spec:
  selector:
    matchLabels:
      app: redis-client
  template:
    metadata:
      labels:
        app: redis-client
      annotations:
        sidecar.istio.io/userVolumeMount: '[{"name":"redis-cert", "mountPath":"/etc/certs", "readonly":true}]'
        sidecar.istio.io/userVolume: '[{"name":"redis-cert", "secret":{"secretName":"redis-cert"}}]'
    spec:
      containers:
        - image: redis
          name: redis-client
          command: [ "/bin/bash", "-c", "--" ]
          args: [ "while true; do sleep 30; done;" ]
EOF
```

If you want to leverage the [`Sidecar` resource]({{< ref "/posts/2021/12/istio-sidecar.md" >}}), you will need to update it accordingly to have the `redis-client` pod able to talk to this new defined endpoint:
```
cat << EOF | kubectl apply -n $NAMESPACE -f -
apiVersion: networking.istio.io/v1beta1
kind: Sidecar
metadata:
  name: redis-client
spec:
  workloadSelector:
    labels:
      app: redis-client
  egress:
  - hosts:
    - "istio-system/*"
    - "./${INTERNAL_HOST}"
EOF
```

We could verify that we could see this endpoint now configured like this: `redis.memorystore-redis - 6378 - outbound - EDS - external-redis.redis-tls` by running this command:
```
istioctl proxy-config clusters $(kubectl -n $NAMESPACE get pod -l app=redis-client -o jsonpath={.items..metadata.name}) -n $NAMESPACE
```

Let's now connect to this `redis` client in order to test our setup:
```
kubectl exec -ti deploy/redis-client -c redis-client -n $NAMESPACE -- bash -c "redis-cli -h $redisIp -p $redisPort"
```
From within that shell, you could type `ping` and you should receive `pong`.

That's it! That's a wrap!

_Note: There might have some [performance impacts of enabling in-transit encryption](https://cloud.google.com/memorystore/docs/redis/in-transit-encryption#performance_impact_of_enabling_in-transit_encryption). You may want to do your own [benchmarks tests](https://redis.io/topics/benchmarks) with your own applications and context._

Further and complementary resources:
- [Securing Redis with Istio TLS origination](https://samos-it.com/posts/securing-redis-istio-tls-origniation-termination.html)
- [Consuming External MongoDB Services](https://istio.io/latest/blog/2018/egress-mongo/)
- [Istio Traffic with Firestore Database](https://istiobyexample.dev/databases/)
- [Connecting to Memorystore for Redis with TLS & AUTH](https://medium.com/@kellydodson/e51f4535871d)

Hope you enjoyed this post and that you will be able to leverage it for your own context.

Sail safe out there, cheers!