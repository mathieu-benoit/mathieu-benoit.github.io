---
title: secure nginx ingress controller behind cloud armor
date: 2023-05-09
tags: [kubernetes, containers, security, gcp]
description: let's see how we can secure our nginx ingress controller behind an l7 https load balancer and cloud armor
aliases:
    - /nginx-ingress-cloud-armor/
---
As one of the main maintainers of the [Edge to Mesh tutorial](https://cloud.google.com/architecture/exposing-service-mesh-apps-through-gke-ingress) for the last 2-3 years, I have been a huge fan of the managed GCE ingress controller. From GKE, you could use [`Ingress`, `Service`, `BackendConfig` manifests](https://cloud.google.com/armor/docs/integrating-cloud-armor#with_ingress) in order to generate all the Google Cloud Infrastructure to expose your public endpoint behind an HTTPS L7 Load Balancer and leverage advanced features like CDN, Cloud Armor, etc.

> _Deploying external L7 load balancing outside of the mesh along with a mesh ingress layer offers significant advantages, especially for internet traffic. Even though Anthos Service Mesh and Istio ingress gateways provide advanced routing and traffic management in the mesh, some functions are better served at the edge of the network. Taking advantage of internet-edge networking through Google Cloud's external HTTP(S) load balancer might provide significant performance, reliability, or security-related benefits over mesh-based ingress._

I was recently involved in a project where the Nginx Ingress controller (from the [Kubernetes community](https://github.com/kubernetes/ingress-nginx) but same applies to the one maintained by [NGINX Inc.](https://github.com/nginxinc/kubernetes-ingress)) was used. It was for different reasons, one of them for example is that the [GCE ingress controller doesn't support multiple `Ingresses` on the same public IP address](https://stackoverflow.com/questions/50294272/how-come-gke-gives-me-different-ips-for-each-ingress-that-i-create).

Now let's say you want to secure your Nginx Ingress controller behind an HTTPS L7 Load Balancer and Cloud Armor. Sounds appealing, right? But actually it's [not supported like you can easily do it with the GCE ingress controller](https://stackoverflow.com/questions/67285351/how-can-i-use-cloud-armor-on-nginx-ingress-controller).

Fortunately, after some research I found out that we can set this up by ourself, manually. [Here](https://cloud.google.com/kubernetes-engine/docs/how-to/custom-ingress-controller), [here](https://hodo.dev/posts/post-27-gcp-using-neg/), [here](https://stackoverflow.com/questions/72476714/global-load-balancer-https-loadbalancer-in-front-of-gke-nginx-ingress-controll/72940666#72940666) or [here](https://stackoverflow.com/questions/72950423/gcp-external-http-cloud-load-balancer-with-nginx-ingress-on-gke) are good pointers I found.

But to be honest, after giving them a shot, I found out that they were not complete for my own needs with more security as requirements. Here is what I needed in addition to what was shared:
- Expose an [HTTPS endpoint](https://cloud.google.com/load-balancing/docs/https) (not just HTTP)
- Support an [HTTP-to-HTTPS redirect](https://cloud.google.com/load-balancing/docs/https/setting-up-global-http-https-redirect)
- Set [HTTPS between the GCLB and the Nginx ingress controller](https://cloud.google.com/load-balancing/docs/ssl-certificates/encryption-to-the-backends)
- Use [Custom Header to keep the source IP address from the L7 Load Balancer](https://kubernetes.github.io/ingress-nginx/user-guide/nginx-configuration/configmap/#use-forwarded-headers)
- Use the new [next generation Global External Load Balancer](https://cloud.google.com/blog/products/networking/increasing-resiliency-load-balancers)
- Use a private GKE cluster

That's what I will cover throughout this blog post by sharing my learnings and showing you this end-to-end setup, please bear with me! :)

![](https://github.com/mathieu-benoit/my-images/raw/main/nginx-ingress-cloud-armor.png)

_Note: I'm doing this via `gcloud` commands, but everything can be done via Terraform too._

Define common variables:
```bash
PROJECT_ID=FIXME
gcloud config set project ${PROJECT_ID}

CLUSTER_NAME=FIXME
CLUSTER_ZONE=FIXME
```

Get some information from your existing GKE cluster:
```bash
gcloud container clusters get-credentials ${CLUSTER_NAME} \
    --zone ${CLUSTER_ZONE}

CLUSTER_FIREWALL_RULE_TAG=$(gcloud compute instances describe \
    $(kubectl get nodes -o jsonpath='{.items[0].metadata.name}') \
	--zone ${CLUSTER_ZONE} \
    --format "value(tags.items[0])")
CLUSTER_MASTER_IP_CIDR=$(gcloud container clusters describe ${CLUSTER_NAME} \
    --zone ${CLUSTER_ZONE} \
    --format "value(privateClusterConfig.masterIpv4CidrBlock)")
NETWORK=$(gcloud container clusters describe ${CLUSTER_NAME} \
    --zone ${CLUSTER_ZONE} \
    --format "value(network)")
```

Deploy the Nginx Ingress Controller not exposed as public endpoint, supporting HTTPS only, keeping the source IP address coming from the L7 load balancer and attached to the associated Network Endpoint Group:
```bash
NGINX_NEG_PORT=443
NGINX_NEG_NAME=${CLUSTER_NAME}-ingress-nginx-${NGINX_NEG_PORT}-neg
cat <<EOF > ${CLUSTER_NAME}-nginx-ingress-controller-values.yaml
controller:
  service:
    enableHttp: false
    type: ClusterIP
    annotations:
      cloud.google.com/neg: '{"exposed_ports": {"${NGINX_NEG_PORT}":{"name": "${NGINX_NEG_NAME}"}}}'
  config:
    use-forwarded-headers: true
EOF
helm upgrade \
    --install ingress-nginx ingress-nginx \
    --repo https://kubernetes.github.io/ingress-nginx \
    --namespace ingress-nginx \
    --create-namespace \
    -f ${CLUSTER_NAME}-nginx-ingress-controller-values.yaml
```

This will create for you the associated Network Endpoint Group (NEG) that we will attach later to our Global Load Balancer:
```bash
gcloud compute network-endpoint-groups list
```

If you are using a GKE cluster with private nodes, you need to allow the Kubernetes master nodes to talk to the node pool on port `8443` for Nginx Ingress controller:
```bash
gcloud compute firewall-rules create k8s-masters-to-nodes-on-8443 \
    --network ${NETWORK} \
    --direction INGRESS \
    --source-ranges ${CLUSTER_MASTER_IP_CIDR} \
    --target-tags ${CLUSTER_FIREWALL_RULE_TAG} \
    --allow tcp:8443
```

## Configure the backend

Now, let’s create the Load Balancer and all the required components.

Let's define the type of HTTPS Load Balancer we want. `EXTERNAL_MANAGED` means that we will use the [next generation Global External Load Balancer](https://cloud.google.com/blog/products/networking/increasing-resiliency-load-balancers):
```bash
LOAD_BALANCING_SCHEME=EXTERNAL_MANAGED
```
_Note: You can use `EXTERNAL` if you want to still use the Global External Load Balancer (Classic) instead. You can see the differences and the limitations between both [here](https://cloud.google.com/load-balancing/docs/https/migrate-to-global)._

Allow traffic from the Load Balancer to the node pool on port `443` for Nginx Ingress controller:
```bash
gcloud compute firewall-rules create ${CLUSTER_NAME}-allow-tcp-loadbalancer \
    --network ${NETWORK} \
    --allow tcp:${NGINX_NEG_PORT} \
    --source-ranges 130.211.0.0/22,35.191.0.0/16 \
    --target-tags ${CLUSTER_FIREWALL_RULE_TAG}
```
_Note: these IP ranges correspond to the Google Cloud probers to connect to your backend, more information [here](https://cloud.google.com/load-balancing/docs/health-check-concepts#ip-ranges)._

Add an HTTPS Health Check configuration:
```bash
gcloud compute health-checks create https ${CLUSTER_NAME}-ingress-nginx-health-check \
    --port ${NGINX_NEG_PORT} \
    --check-interval 60 \
    --unhealthy-threshold 3 \
    --healthy-threshold 1 \
    --timeout 5 \
    --request-path /healthz
```

Create a backend service:
```bash
gcloud compute backend-services create ${CLUSTER_NAME}-ingress-nginx-backend-service \
    --load-balancing-scheme ${LOAD_BALANCING_SCHEME} \
    --protocol HTTPS \
    --port-name https \
    --health-checks ${CLUSTER_NAME}-ingress-nginx-health-check \
    --enable-logging \
    --global
```

Add the NEG to the backend service:
```bash
gcloud compute backend-services add-backend ${CLUSTER_NAME}-ingress-nginx-backend-service \
    --network-endpoint-group ${NGINX_NEG_NAME} \
    --network-endpoint-group-zone ${CLUSTER_ZONE} \
    --balancing-mode RATE \
    --capacity-scaler 1.0 \
    --max-rate-per-endpoint 100 \
    --global
```

## Configure the frontend

That was for the backend part, let's now do the frontend part.

Create an url map:
```bash
gcloud compute url-maps create ${CLUSTER_NAME}-ingress-nginx-loadbalancer \
    --default-service ${CLUSTER_NAME}-ingress-nginx-backend-service
```

Create an HTTP proxy:
```bash
gcloud compute target-http-proxies create ${CLUSTER_NAME}-ingress-nginx-http-proxy \
    --url-map ${CLUSTER_NAME}-ingress-nginx-loadbalancer
```

Create a public static IP address:
```bash
gcloud compute addresses create ${CLUSTER_NAME}-public-static-ip \
    --global
INGRESS_IP=$(gcloud compute addresses describe ${CLUSTER_NAME}-public-static-ip --global --format "value(address)")
echo ${INGRESS_IP}
```

Here you can bring your own DNS, I'm creating one to illustrate the scenario with an example:
```bash
DNS=my-dns.endpoints.${PROJECT_ID}.cloud.goog
cat <<EOF > my-dns-spec.yaml
swagger: "2.0"
info:
  description: "Cloud Endpoints DNS"
  title: "Cloud Endpoints DNS"
  version: "1.0.0"
paths: {}
host: "${DNS}"
x-google-endpoints:
- name: "${DNS}"
  target: "${INGRESS_IP}"
EOF
gcloud endpoints services deploy my-dns-spec.yaml
```

Generate the SSL certificate for this DNS:
```bash
openssl genrsa -out my-dns-ca.key 2048
openssl req -x509 \
    -new \
    -nodes \
    -days 365 \
    -key my-dns-ca.key \
    -out my-dns-ca.crt \
    -subj "/CN=${DNS}"
```

Upload this SSL certificate in Google Cloud:
```bash
gcloud compute ssl-certificates create my-dns-ssl-certificate \
    --certificate my-dns-ca.crt \
    --private-key my-dns-ca.key \
    --global
gcloud compute target-https-proxies create ${CLUSTER_NAME}-ingress-nginx-http-proxy \
    --url-map ${CLUSTER_NAME}-ingress-nginx-loadbalancer \
    --ssl-certificates my-dns-ssl-certificate
```
_Note: If you have multiple SSL certificates, that's where you will provide them._

Create a global forwarding rule on port `443`:
```bash
gcloud compute forwarding-rules create ${CLUSTER_NAME}-https-forwarding-rule \
    --load-balancing-scheme ${LOAD_BALANCING_SCHEME} \
    --network-tier PREMIUM \
    --global \
    --ports 443 \
    --target-https-proxy ${CLUSTER_NAME}-ingress-nginx-http-proxy \
    --address ${CLUSTER_NAME}-public-static-ip
```

## Configure HTTPS redirect

Configure an HTTP to HTTPS redirect on the load balancer:
```bash
cat <<EOF > ${CLUSTER_NAME}-http-to-https-redirect.yaml
kind: compute#urlMap
name: ${CLUSTER_NAME}-http-to-https-redirect
defaultUrlRedirect:
  redirectResponseCode: MOVED_PERMANENTLY_DEFAULT
  httpsRedirect: True
EOF
gcloud compute url-maps import ${CLUSTER_NAME}-http-to-https-redirect \
    --source ${CLUSTER_NAME}-http-to-https-redirect.yaml \
    --global
gcloud compute target-http-proxies create ${CLUSTER_NAME}-http-to-https-redirect-proxy \
    --url-map ${CLUSTER_NAME}-http-to-https-redirect \
    --global
gcloud compute forwarding-rules create ${CLUSTER_NAME}-http-to-https-redirect-rule \
    --load-balancing-scheme ${LOAD_BALANCING_SCHEME} \
    --network-tier PREMIUM \
    --address ${CLUSTER_NAME}-public-static-ip \
    --global \
    --target-http-proxy ${CLUSTER_NAME}-http-to-https-redirect-proxy \
    --ports 80
```

## Configure Cloud Armor

Create Cloud Armor and attach it to the public endpoint:
```bash
gcloud compute security-policies create ${CLUSTER_NAME}-security-policy
gcloud compute security-policies update ${CLUSTER_NAME}-security-policy \
    --enable-layer7-ddos-defense
gcloud compute backend-services update ${CLUSTER_NAME}-ingress-nginx-backend-service \
    --global \
    --security-policy ${CLUSTER_NAME}-security-policy
```
_Note: From here, you could use any [additional features from Cloud Armor](https://cloud.google.com/armor/docs/cloud-armor-overview) you want. In this example, we are just using the default DDoS protection_

That's it for the setup, we made it!

## Deploy a sample app

Let's now deploy a sample app.

Deploy the app:
```bash
kubectl create deployment whereami \
    --image us-docker.pkg.dev/google-samples/containers/gke/whereami \
    --port 8080
kubectl expose deployment whereami \
    --port 80 \
    --target-port 8080 \
    --type ClusterIP
```

Bind the app to the Nginx Ingress controller:
```bash
cat << EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: whereami
spec:
  ingressClassName: nginx
  rules:
  - host: ${DNS}
    http:
      paths:
      - backend:
          service:
            name: whereami
            port:
              number: 80
        path: /
        pathType: Prefix
EOF
```
_Note: You will notice that we don't set the TLS configuration here since it is managed on the Load Balancer directly thanks to the setup we did earlier._

Now if you hit the link displayed below you will be redirected to an HTTPS link and to eventually a working (and very secure) app:
```bash
echo -E "http:://${DNS}"
```

## Conclusion

Wow! Quite a long ride to make it, right? Yup! But that's what it takes to actually secure your Nginx Ingress controller (or any 3rd party reverse proxy you may use in GKE). Hope you liked it and that you will be able to use this for your own context.

Cheers! Stay safe out there! Happy sailing!