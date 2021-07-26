---
title: mix both internal and external load balancers to expose your crfa services
date: 2021-07-25
tags: [gcp, containers, kubernetes]
description: let's see how to setup both external and internal load balancers to expose your services in the same crfa cluster
aliases:
    - /crfa/
---
[Cloud Run for Anthos (CRfA)](https://cloud.google.com/anthos/run) is here to simplify the experience of developers and operators. [Knative](https://knative.dev/) on top of Kubernetes is how it accomplishes this.

Create a CRfA cluster is very easy, it's just an option when you create your GKE cluster:
```
clusterName=crfa
zone=us-east4-a
projectId=mycrfa
gcloud container clusters create $clusterName \
    --project $projectId \
    --zone=$zone \
    --addons=HttpLoadBalancing,CloudRun
```
When provisioned, CRfA will have its own Istio flavor and will provision by default a public load balancer and IP address on top of its ingress gateway.

_Note: If you want to [restrict the access of this ingress gateway](https://cloud.google.com/anthos/run/docs/setup#setting_up_a_private_internal_network) and all your CRfA services you could leverage this parameter at cluster creation `--cloud-run-config=load-balancer-type=INTERNAL` to set its load balancer as internal with a private IP address._

And from there, you could deploy two kind of service:
- Internal - `gcloud run deploy --ingress internal`. These services will only be accessible from within the cluster, not from outside.
- External - `gcloud run deploy --ingress all`. These services will be accessible based on the `--cloud-run-config=load-balancer-type=` value we dicussed earlier at the cluster creation. So these services will be accessible either publicly or privately in the same cluster's network.

For example in our case, let's deploy two sample service illustrating both scenario:
```
gcloud run deploy internal \
    --image gcr.io/knative-samples/helloworld-go \
    --cluster=$clusterName \
    --cluster-location=$zone \
    --platform gke \
    --project $projectId \
    --set-env-vars TARGET=internal \
    --ingress internal
gcloud run deploy external \
    --image gcr.io/knative-samples/helloworld-go \
    --cluster=$clusterName \
    --cluster-location=$zone \
    --platform gke \
    --project $projectId \
    --set-env-vars TARGET=external \
    --ingress all
```

From there the `internal` service will only be accessible from within the cluster like explained above. In order to get the `external` service publicly reachable we need to [configure a domain](https://cloud.google.com/anthos/run/docs/default-domain). In our case we will leverage a temporary DNS with `nip.io`:
```
publicIp=$(kubectl get svc istio-ingress -n gke-system -o jsonpath="{.status.loadBalancer.ingress[*].ip}")
# Replace the FIXME below by the IP address you just got above:
kubectl patch configmap config-domain --namespace knative-serving --patch \
  '{"data": {"example.com": null, "FIXME.nip.io": ""}}'
```

Then we are now able to ping the `external` service:
```
curl http://external.default.$publicIp.nip.io
```

Now what we would like to do is also expose services via an internal load balancer even if the CRfA cluster we provisioned exposes by default the services via a public load balancer. What we need to do is simply create this new `Service` as internal load balancer to expose all the services managed with CRfA:
```
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: internal-lb
  namespace: gke-system
  annotations:
    cloud.google.com/load-balancer-type: "Internal"
spec:
  type: LoadBalancer
  selector:
    istio: ingress-gke-system
  ports:
  - name: http2
    port: 80
    targetPort: 8081
EOF
```

Once deployed we could successfuly reach any `internal` services from a machine under the same VPC than the CRfA cluster:
```
ilbIp=$(kubectl get svc internal-lb -n gke-system -o jsonpath="{.status.loadBalancer.ingress[*].ip}")
curl $ilbIp -H "Host: internal.default.svc.cluster.local"
```

In addition to that, we could also configure a custom domain on those internal services. Here is the manifest that you could build and deploy to accomplish this:
```
export CUSTOM_DOMAIN=custom-domain.example.com
cat <<EOF | kubectl apply -f -
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: ${CUSTOM_DOMAIN}
  namespace: default
spec:
  # This is the gateway shared in knative service mesh.
  gateways:
  - knative-serving/knative-local-gateway
  # Set host to the domain name that you own.
  hosts:
  - ${CUSTOM_DOMAIN}
  http:
  - headers:
      request:
        add:
          K-Original-Host: ${CUSTOM_DOMAIN}
    rewrite:
      authority: internal.default.svc.cluster.local
    route:
    - destination:
        host: knative-local-gateway.gke-system.svc.cluster.local
        port:
          number: 80
      weight: 100
EOF
```

With that, we could successfully reach this specific `internal` service from a machine under the same VPC than the CRfA cluster:
```
curl $ilbIp -H "Host:${CUSTOM_DOMAIN}"
```

That's it, we demonstrated how to combine and leverage both public load balancer and internal load balancer with the same CRfA cluster.

Hope you enjoyed that one, cheers!