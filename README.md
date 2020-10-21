![CloudBuild](https://badger-dydtquwp2q-ue.a.run.app/build/status?project=mabenoit-myblog&id=2d99471b-c068-4452-a670-9763a89c6e8e)

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

# Simple way with just a deployment and service:
imageName=FIXME
sed -i "s,CONTAINER_IMAGE_NAME,$imageName," k8s/deployment.yaml
kubectl apply -f k8s/deployment.yaml
sed -i "s,NodePort,LoadBalancer," k8s/service.yaml
kubectl apply -f k8s/service.yaml

# Complete way:
kubectl apply -f k8s/
```

Define the Cloud Build trigger:
```
gcloud beta builds triggers create github \
    --repo-name=myblog \
    --repo-owner=mathieu-benoit \
    --branch-pattern="master" \
    --build-config=cloudbuild.yaml
```
