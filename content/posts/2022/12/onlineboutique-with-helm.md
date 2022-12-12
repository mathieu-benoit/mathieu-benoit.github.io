---
title: online boutique's helm chart, illustrate advanced scenarios with service mesh and gitops
date: 2022-12-11
tags: [gcp, kubernetes, helm]
description: let's see how we could deploy advanced scenarios of the online boutique sample via its helm chart with service mesh and gitops, in order to improve its security posture
aliases:
    - /onlineboutique-with-helm/
---
Since the version 0.4.2, Online Boutique has its own Helm chart, in the [GitHub repository](https://github.com/GoogleCloudPlatform/microservices-demo/tree/main/helm-chart) or in the public Artifact Registry repository: `us-docker.pkg.dev/online-boutique-ci/charts/onlineboutique`.

The intent is to simplify the way the Online Boutique users deploy it, especially when they want to deploy it in more advanced scenarios: with `NetworkPolicies`, with the Cymbal branding, without the `frontend` app exposed publicly, with `ServiceAccounts`, etc.

Let's see this in action throughout this blog article, from the default setup to more complex scenarios where we want a secure Online Boutique deployed in a Service Mesh. Finally, we will see how you can deploy this Helm chart via Config Sync, in a GitOps way.

## Deploy the default Online Boutique

Create a GKE cluster:
```bash
PROJECT_ID=FIXME-WITH-YOUR-PROJECT-ID
CLUSTER=onlineboutique-with-helm
ZONE=northamerica-northeast1-a
PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format='get(projectNumber)')
gcloud services enable container.googleapis.com
gcloud container clusters create ${CLUSTER} \
    --zone ${ZONE} \
    --machine-type=e2-standard-4 \
    --workload-pool ${PROJECT_ID}.svc.id.goog \
    --enable-dataplane-v2 \
    --labels mesh_id=proj-$PROJECT_NUMBER
```

Deploy the Online Boutique via its Helm chart:
```bash
ONLINEBOUTIQUE_NAMESPACE=onlineboutique
helm upgrade onlineboutique oci://us-docker.pkg.dev/online-boutique-ci/charts/onlineboutique \
    --install \
    --create-namespace \
    -n ${ONLINEBOUTIQUE_NAMESPACE}
```

If you wait a little bit, when the `Pods` are deployed, you can access the Online Boutique website by clicking on this URL:
```bash
echo -n "http://" && kubectl get svc frontend-external -n ${ONLINEBOUTIQUE_NAMESPACE} -o json | jq -r '.status.loadBalancer.ingress[0].ip'
```

Congrats! You just deployed the default setup of Online Boutique via its Helm chart!

## Secure Online Boutique with `NetworkPolicies`

Let's now add more security with this default Online Boutique setup, by adding predefined fine granular `NetworkPolicies`, one per app:
```bash
helm upgrade onlineboutique oci://us-docker.pkg.dev/online-boutique-ci/charts/onlineboutique \
    --install \
    --create-namespace \
    -n ${ONLINEBOUTIQUE_NAMESPACE} \
    --set networkPolicies.create=true
```

If you run the following command you could see the `NetworkPolicies` deployed:
```bash
kubectl get networkpolicies -n ${ONLINEBOUTIQUE_NAMESPACE}
```
Output similar to:
```plain
NAME                    POD-SELECTOR                AGE
adservice               app=adservice               4m42s
cartservice             app=cartservice             4m42s
checkoutservice         app=checkoutservice         4m42s
currencyservice         app=currencyservice         4m42s
deny-all                <none>                      4m42s
emailservice            app=emailservice            4m42s
frontend                app=frontend                4m42s
loadgenerator           app=loadgenerator           4m42s
paymentservice          app=paymentservice          4m42s
productcatalogservice   app=productcatalogservice   4m42s
recommendationservice   app=recommendationservice   4m42s
redis-cart              app=redis-cart              4m42s
shippingservice         app=shippingservice         4m42s
```

You can verify that you can still access the Online Boutique website by clicking on this URL:
```bash
echo -n "http://" && kubectl get svc frontend-external -n ${ONLINEBOUTIQUE_NAMESPACE} -o json | jq -r '.status.loadBalancer.ingress[0].ip'
```

By registering your GKE clsuter in a fleet, you can even see in the Google Cloud Console that your Security posture just got improved:
```bash
gcloud services enable gkehub.googleapis.com

gcloud container fleet memberships register ${CLUSTER} \
    --gke-cluster ${ZONE}/${CLUSTER} \
    --enable-workload-identity
```

Then, by navigating to the **Anthos > Security** page in your Google Cloud Console, you can see that **Kubernetes network policy** is enabled in the Online Boutique namespace:
![Online Boutique's Network Policies on Anthos Security page](https://github.com/mathieu-benoit/my-images/raw/main/onlineboutique-with-helm-networkpolicies.png)

## Deploy Online Boutique in a Service Mesh

Let's now deploy Online Boutique in an Anthos Service Mesh enabled on your GKE cluster.

First, let's enable Anthos Service Mesh on the GKE cluster:
```bash
gcloud services enable mesh.googleapis.com

gcloud container fleet mesh enable

gcloud container fleet mesh update \
    --management automatic \
    --memberships ${CLUSTER}
```

Wait for the managed Anthos Service Mesh to be successfully enabled on your GKE cluster (`code: REVISION_READY` and `state: ACTIVE`):
```bash
gcloud container fleet mesh describe
```

In order to have Online Boutique in this Service Mesh, we need to label its `Namespace`:
```bash
kubectl label namespace ${ONLINEBOUTIQUE_NAMESPACE} istio-injection=enabled
```

Let's force the injection of the Istio's sidecar proxies on the Online Boutique's `Deployments`:
```bash
kubectl rollout restart deployments \
    -n ${ONLINEBOUTIQUE_NAMESPACE}
```

If you wait a little bit, when the `Pods` are deployed, you can access the Online Boutique website by clicking on this URL:
```bash
echo -n "http://" && kubectl get svc frontend-external -n ${ONLINEBOUTIQUE_NAMESPACE} -o json | jq -r '.status.loadBalancer.ingress[0].ip'
```

Then, by navigating to the **Anthos > Service Mesh** page in your Google Cloud Console, you can see the associated **Topology**:
![Online Boutique on the ASM Topology page](https://github.com/mathieu-benoit/my-images/raw/main/onlineboutique-with-helm-asm-topology.png)

Congrats! You just deployed Online Boutique in your Service Mesh via its Helm chart!

To follow an Istio's best practice we could even deploy fine granular `Sidecars`, one per app, in order to optimize the resource utilization per app's sidecar proxy:
```bash
helm upgrade onlineboutique oci://us-docker.pkg.dev/online-boutique-ci/charts/onlineboutique \
    --install \
    --create-namespace \
    -n ${ONLINEBOUTIQUE_NAMESPACE} \
    --set networkPolicies.create=true \
    --set sidecars.create=true
```

If you run the following command you could see the `Sidecars` deployed:
```bash
kubectl get sidecars -n ${ONLINEBOUTIQUE_NAMESPACE}
```
Output similar to:
```plain
NAME                    AGE
adservice               36h
cartservice             36h
checkoutservice         36h
currencyservice         36h
emailservice            36h
frontend                36h
loadgenerator           36h
paymentservice          36h
productcatalogservice   36h
recommendationservice   36h
redis-cart              36h
shippingservice         36h
```

## Secure Online Boutique with `AuthorizationPolicies`

Let's now add more security to Online Boutique in the Service Mesh setup, by adding predefined fine granular `AuthorizationPolicies`, one per app:

```bash
helm upgrade onlineboutique oci://us-docker.pkg.dev/online-boutique-ci/charts/onlineboutique \
    --install \
    --create-namespace \
    -n ${ONLINEBOUTIQUE_NAMESPACE} \
    --set networkPolicies.create=true \
    --set sidecars.create=true \
    --set serviceAccounts.create=true \
    --set authorizationPolicies.create=true
```

If you run the following command you could see the `AuthorizationPolicies` deployed:
```bash
kubectl get authorizationpolicies -n ${ONLINEBOUTIQUE_NAMESPACE}
```
Output similar to:
```plain
NAME                    AGE
adservice               22m
cartservice             22m
checkoutservice         22m
currencyservice         22m
deny-all                12m
emailservice            22m
frontend                22m
paymentservice          22m
productcatalogservice   22m
recommendationservice   22m
redis-cart              22m
shippingservice         22m
```
_Note: in order to define these fine granular `AuthorizationPolicies` we needed to create one `ServiceAccount` per app too, instead of using the `default` `ServiceAccount` for all the apps._

You can verify that you can still access the Online Boutique website by clicking on this URL:
```bash
echo -n "http://" && kubectl get svc frontend-external -n ${ONLINEBOUTIQUE_NAMESPACE} -o json | jq -r '.status.loadBalancer.ingress[0].ip'
```

By navigating to the **Anthos > Security** page in your Google Cloud Console, you can see that **Service access control** is enabled in the Online Boutique namespace:
![Online Boutique's AuthorizationPolicies on Anthos Security page](https://github.com/mathieu-benoit/my-images/raw/main/onlineboutique-with-helm-authorizationpolicies.png)

## Deploy Online Boutique behind an Istio's ingress gateway

To follow Istio's best practice, let's protect our Online Boutique's apps behind and Istio's Ingress Gateway.

Let's deploy an Istio's Ingress Gateway:
```bash
INGRESS_NAMESPACE=asm-ingress
kubectl create namespace ${INGRESS_NAMESPACE}
kubectl label namespace ${INGRESS_NAMESPACE} istio-injection=enabled
kubectl label namespace ${INGRESS_NAMESPACE} name=${INGRESS_NAMESPACE}
kubectl apply -f https://github.com/GoogleCloudPlatform/anthos-service-mesh-samples/raw/main/docs/ingress-gateway-asm-manifests/base/deployment-service.yaml -n ${INGRESS_NAMESPACE}
kubectl apply -f https://github.com/GoogleCloudPlatform/anthos-service-mesh-samples/raw/main/docs/ingress-gateway-asm-manifests/base/gateway.yaml -n ${INGRESS_NAMESPACE}
kubectl apply -f https://github.com/GoogleCloudPlatform/anthos-service-mesh-samples/raw/main/docs/ingress-gateway-asm-manifests/with-authorization-policies/authorizationpolicy.yaml -n ${INGRESS_NAMESPACE}
```

Now, let's update the Online Boutique deployment in order to have the `frontend` app behind the Ingress Gateway:
```bash
helm upgrade onlineboutique oci://us-docker.pkg.dev/online-boutique-ci/charts/onlineboutique \
    --install \
    --create-namespace \
    -n ${ONLINEBOUTIQUE_NAMESPACE} \
    --set networkPolicies.create=true \
    --set sidecars.create=true \
    --set serviceAccounts.create=true \
    --set authorizationPolicies.create=true \
    --set frontend.externalService=false \
    --set frontend.virtualService.create=true \
    --set frontend.virtualService.gateway.name=asm-ingressgateway \
    --set frontend.virtualService.gateway.namespace=${INGRESS_NAMESPACE} \
    --set frontend.virtualService.gateway.labelKey=asm \
    --set frontend.virtualService.gateway.labelValue=ingressgateway
```

If you wait a little bit, when the `Pods` are deployed, you can access the Online Boutique website via the Ingress Gateway now, by clicking on this URL:
```bash
echo -n "http://" && kubectl get svc asm-ingressgateway -n ${INGRESS_NAMESPACE} -o json | jq -r '.status.loadBalancer.ingress[0].ip'
```

By navigating to the **Anthos > Service Mesh** page in your Google Cloud Console, you can see the associated **Topology** now containing the Ingress Gateway:
![Online Boutique on ASM Topology page with Ingress Gateway](https://github.com/mathieu-benoit/my-images/raw/main/onlineboutique-with-helm-asm-topology-ingressgateway.png)

By navigating to the **Anthos > Security** page in your Google Cloud Console, you can see that **Service access control** is enabled in the Ingress Gateway namespace too:
![Online Boutique AuthorizationPolicies with Ingress Gateway](https://github.com/mathieu-benoit/my-images/raw/main/onlineboutique-with-helm-authorizationpolicies-ingressgateway.png)

One last thing, not related to Online Boutique per say, but here is a quick win to add more security within your Service Mesh, by adding `STRICT` mTLS for the communication between your apps in the Servie Mesh:
```bash
cat << EOF | kubectl apply -f -
apiVersion: security.istio.io/v1beta1
kind: PeerAuthentication
metadata:
  name: default
  namespace: istio-system
spec:
  mtls:
    mode: STRICT
EOF
```

By navigating to the **Anthos > Security** page in your Google Cloud Console, you can see that **mTLS status** is enabled in your Service Mesh:
![Online Boutique with STRICT mTLS](https://github.com/mathieu-benoit/my-images/raw/main/onlineboutique-with-helm-strict-mtls.png)

## Deploy Online Boutique via Config Sync, in a GitOps way

Config Sync is a GitOps tool that you could leverage in your GKE cluster, which supports Helm chart to sync from an Helm registry to your GKE cluster, let's see how you can accomplish this.

First, enable Config Sync on your GKE cluster:
```bash
gcloud beta container fleet config-management enable

cat <<EOF > acm-config.yaml
applySpecVersion: 1
spec:
  configSync:
    enabled: true
EOF
gcloud beta container fleet config-management apply \
    --membership ${CLUSTER} \
    --config acm-config.yaml
```

Wait for Config Sync to be successfully enabled on your GKE cluster (`Status` as `NOT_CONFIGURED`):
```bash
gcloud beta container fleet config-management status
```

Then, deploy the `RootSync` configuration to sync this Helm chart in your GKE cluster:
```bash
cat << EOF | kubectl apply -f -
apiVersion: configsync.gke.io/v1beta1
kind: RootSync
metadata:
  name: root-sync-helm
  namespace: config-management-system
spec:
  spec:
  sourceFormat: unstructured
  sourceType: helm
  helm:
    repo: oci://us-docker.pkg.dev/online-boutique-ci/charts
    chart: onlineboutique
    releaseName: onlineboutique
    namespace: onlineboutique
    auth: none
    values:
      networkPolicies:
        create: true
      sidecars:
        create: true
      serviceAccounts:
        create: true
      authorizationPolicies:
        create: true
      frontend:
        externalService: false
        virtualService:
          create: true
          gateway:
            name: asm-ingressgateway
            namespace: ${INGRESS_NAMESPACE}
            labelKey: asm
            labelValue: ingressgateway
EOF
```

By navigating to the **Kubernetes Engine > Config & Policy > Config** page in your Google Cloud Console, you can see all the 73 resources synced from the Online Boutique Helm chart by Config Sync:
![Online Boutique synced by Config Sync](https://github.com/mathieu-benoit/my-images/raw/main/onlineboutique-with-helm-configsync.png)

## Conclusion

The Online Boutique's Helm chart allows to deploy either the default basic setup as well as more advanced, complex and secure setup with Service Mesh and Config Sync (GitOps).

We just saw how you can deploy Online Boutique with its fine granular `NetworkPolicies`, `Sidecars`, `ServiceAccounts` and `AuthorizationPolicies`. We also saw how you can expose the Online Boutique's `frontend` app via an Istio Ingress Gateway.

You can take inspiration of this to improve your own Security Posture with your own workloads.

## More examples

You could also find advanced scenarios leveraging this Helm chart with these blogs below:

- [gRPC health probes with Kubernetes 1.24+](https://medium.com/google-cloud/b5bd26253a4c)
- [Use Google Cloud Spanner with the Online Boutique sample](https://medium.com/google-cloud/f7248e077339)

Hope you enjoyed that one, happy sailing, cheers!