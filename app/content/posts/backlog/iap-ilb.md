---
title: iap in front of an ilb
date: 2021-07-25
tags: [gcp, containers, kubernetes, security]
description: let's see how to FIXME
draft: true
aliases:
    - /iap-ilb/
---
Intro already made [there]({{< ref "/posts/2020/10/beyondcorp.md" >}}) about IAP.

###############################
https://cloud.google.com/kubernetes-engine/docs/how-to/internal-load-balance-ingress
###############################

## Cluster setup

gcloud compute networks subnets create proxy-only-subnet \
  --purpose=INTERNAL_HTTPS_LOAD_BALANCER \
  --role=ACTIVE \
  --region=us-east4 \
  --network=default \
  --range=10.1.2.0/24

## Deploy the app

kubectl create ns iap-internal
kn iap-internal

cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: hostname
  name: hostname-server
spec:
  selector:
    matchLabels:
      app: hostname
  minReadySeconds: 60
  replicas: 1
  template:
    metadata:
      labels:
        app: hostname
    spec:
      containers:
      - image: k8s.gcr.io/serve_hostname:v1.4
        name: hostname-server
        ports:
        - containerPort: 9376
          protocol: TCP
      terminationGracePeriodSeconds: 90
EOF

cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: hostname
  annotations:
    cloud.google.com/neg: '{"ingress": true}'
spec:
  ports:
  - name: host1
    port: 80
    protocol: TCP
    targetPort: 9376
  selector:
    app: hostname
  type: NodePort
EOF

cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ilb-demo-ingress
  namespace: default
  annotations:
    kubernetes.io/ingress.class: "gce-internal"
spec:
  defaultBackend:
    service:
      name: hostname
      port:
        number: 80
EOF

From here, you could reach this endpoint (`kubectl get ing ilb-demo-ingress`) from anywhere who has internal access to the VPC where this GKE cluster sits.
Since the internal HTTP(S) load balancer is a regional load balancer, the virtual IP (VIP) is only accessible from a client within the same region and VPC. After retrieving the load balancer VIP, you can use tools (for example, curl) to issue HTTP GET calls against the VIP from inside the VPC.

## HTTPS

FIXME generate cert

We will use self-signed certificate as an experiment.
```
CUSTOM_DOMAIN=example.com
openssl req -x509 -sha256 -nodes -days 365 -newkey rsa:2048 -subj '/O=example Inc./CN=${CUSTOM_DOMAIN}' -keyout ${CUSTOM_DOMAIN}.key -out ${CUSTOM_DOMAIN}.crt
openssl req -out ${CUSTOM_DOMAIN}.csr -newkey rsa:2048 -nodes -keyout ${CUSTOM_DOMAIN}.key -subj "/CN=${CUSTOM_DOMAIN}/O=httpbin organization"
openssl x509 -req -days 365 -CA ${CUSTOM_DOMAIN}.crt -CAkey ${CUSTOM_DOMAIN}.key -set_serial 0 -in ${CUSTOM_DOMAIN}.csr -out ${CUSTOM_DOMAIN}.crt

gcloud compute ssl-certificates create ilb-cert \
    --certificate ${CUSTOM_DOMAIN}.crt \
    --private-key ${CUSTOM_DOMAIN}.key \
    --region REGION

cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ilb-demo-ingress
  annotations:
    ingress.gcp.kubernetes.io/pre-shared-cert: "ilb-cert"
    kubernetes.io/ingress.class: "gce-internal"
    kubernetes.io/ingress.allow-http: "false"
spec:
  defaultBackend:
    service:
      name: hostname
      port:
        number: 80
EOF
```

FIXME : test with curl

## IAP

Now, let's see how to setup IAP to get access to this ILB endpoint.

# FIXME


- IAP concepts - https://cloud.google.com/iap/docs/concepts-overview
- ASM - https://cloud.google.com/service-mesh/docs/iap-integration
- CRfA - https://cloud.google.com/architecture/integrating-https-load-balancing-with-istio-and-cloud-run-for-anthos-deployed-on-gke
