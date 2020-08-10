Build the container:
```
git clone --recurse-submodules https://github.com/mathieu-benoit/myblog
docker build -t blog .
```

Run locally:
```
docker run -d -p 8080:8080 blog
```

Deploy on Kubernetes:
```
kubectl create ns myblog
kubectl config set-context --current --namespace myblog
kubectl apply -f k8s/deployment.yaml # you need to change the container image reference accordingly.
kubectl apply -f k8s/service.yaml # you need to change the type of the service accordingly.
```
