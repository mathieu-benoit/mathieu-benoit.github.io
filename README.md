Build and run locally:

```
# Build the container
git clone https://github.com/mathieu-benoit/myblog
git submodule init
git submodule update
docker build -t blog .

# Run locally the container
docker run -d -p 8080:8080 blog

# Deploy on Kubernetes
kubectl create ns myblog
kubectl config set-context --current --namespace myblog
kubectl apply -f k8s/deployment.yaml # you need to change the container image reference accordingly.
kubectl apply -f k8s/service.yaml # you need to change the type of the service accordingly.
```
