## Deploy on Kubernetes

```
imageNameInRegistry=myblog
namespace=myblog
kubectl create deployment myblog --image=$imageNameInRegistry --port=8080 -n $namespace
kubectl expose deployment myblog --port=80 --target-port=8080 --type LoadBalancer -n $namespace
```

The associated Helm chart under the `chart/` folder could be leveraged too.
