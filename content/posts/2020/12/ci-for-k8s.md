---
title: advanced continuous integration for containers
date: 2020-12-30
tags: [gcp, containers, security, kubernetes, dotnet]
description: let's setup an advanced continuous integration pipeline for containers
aliases:
    - /ci-for-k8s/
---
Today, I will document how to setup an advanced continuous integration (CI) for containers. All the concepts and tools mentioned in this blog article could be easily leveraged from within any CI tool like GitHub Actions, Jenkins, Azure DevOps, [Google Cloud Build]({{< ref "/posts/2020/08/cloud-build-with-gke.md" >}}), etc.

First, let's write a simple GitHub Actions definition to build and push a container into GitHub container registry:
```
name: simple-ci
on:
  push:
    branches:
      - main
  pull_request:
jobs:
  job:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Build container
        run: docker build --tag docker.pkg.github.com/${{ github.repository }}/container:${{ github.sha }} .
      - name: Log into container registry
        if: ${{ github.event_name == 'push' }}
        run: echo "${{ secrets.GITHUB_TOKEN }}" | docker login docker.pkg.github.com -u ${{ github.actor }} --password-stdin
      - name: Push image in container registry
        if: ${{ github.event_name == 'push' }}
        run: docker push docker.pkg.github.com/${{ github.repository }}/container:${{ github.sha }}
```

That's how simple it is. We are pushing the container in the container registry only if the trigger is a commit on the `main` branch. Otherwise we are just building the container on Pull requests.

Now let's have a more complex and complete continuous integration pipeline with different checks and tests. Here are the tools I will use below on that regard:
- `conftest` to check the compliance of the `Dockerfile` with OPA
- `Docker`, to run unit tests, build the container, run the container, push the container in a registry
- `Trivy`, to scan the container and see if there is any `CRITICAL` or `HIGH` vulnerabilities
- `KinD`, to run the container on a local Kubernetes cluster
- (_coming soon_) Google Artifact Registry (+ security scanning)
- (_coming soon_) [`Google Binary Authorization`]({{< ref "/posts/2020/11/binauthz.md" >}})

Here is now the advanced GitHub Actions definition:
```
name: advanced-ci
on:
  push:
    branches:
      - main
  pull_request:
jobs:
  job:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Run conftest for OPA rego on Dockerfile
        run: |
          cd web/src
          mkdir policy
          curl https://raw.githubusercontent.com/mathieu-benoit/mygkecluster/master/policy/docker.rego -o ./policy/docker.rego
          docker run --rm -v $(pwd):/project openpolicyagent/conftest test Dockerfile
      - name: Prepare environment variables
        run: |
          shortSha=`echo ${GITHUB_SHA} | cut -c1-7`
          echo "IMAGE_NAME=docker.pkg.github.com/${{ github.repository }}/web:$shortSha" >> $GITHUB_ENV
      - name: Build container
        run: |
          docker build --tag ${IMAGE_NAME} .
      - name: Run Trivy vulnerability scanner
        uses: aquasecurity/trivy-action@master
        with:
          image-ref: ${{ env.IMAGE_NAME }}
          format: 'template'
          template: '@/contrib/sarif.tpl'
          output: 'trivy-results.sarif'
          severity: 'CRITICAL,HIGH'
      - name: Upload Trivy scan results to GitHub Security tab
        uses: github/codeql-action/upload-sarif@v1
        with:
          sarif_file: 'trivy-results.sarif'
      - name: Run container locally as a test
        run: |
          docker run -d -p 8080:8080 --read-only --cap-drop=ALL --user=1000 ${IMAGE_NAME}
      - name: Installing KinD cluster
        uses: engineerd/setup-kind@v0.5.0
      - name: Configuring the KinD installation
        run: |
          kubectl cluster-info --context kind-kind
          kind get kubeconfig --internal >$HOME/.kube/config
          kubectl get nodes
      - name: Load image on the nodes of the KinD cluster
        run: |
          kind load docker-image ${IMAGE_NAME} --name=kind
      - name: Deploy and test Kubernetes manifests in KinD cluster
        run: |
          kubectl create deployment test --image=${IMAGE_NAME} -l app=test
          kubectl wait --for=condition=available --timeout=500s deployment/test
          kubectl get all
          status=$(kubectl get pods -l app=test -o 'jsonpath={.items[0].status.phase}')
          if [ $status != 'Running' ]; then echo "Pod not running!" 1>&2; fi
      - name: Log into container registry
        if: ${{ github.event_name == 'push' }}
        run: echo "${{ secrets.GITHUB_TOKEN }}" | docker login docker.pkg.github.com -u ${{ github.actor }} --password-stdin
      - name: Push image in container registry
        if: ${{ github.event_name == 'push' }}
        run: |
          docker push ${IMAGE_NAME}
```

Complementary to this, I also enabled [`dependabot`](https://help.github.com/github/administering-a-repository/configuration-options-for-dependency-updates) on my GitHub repository to frequently check if my `Nuget` packages or my container base images are up-to-date (really important on a security standpoint). [Here](https://github.com/mathieu-benoit/dotnet-on-kubernetes/blob/main/.github/dependabot.yml) is the file I have with that.

Notes:
- GitHub container registry [doesn't really support yet public images](https://github.community/t/docker-pull-from-public-github-package-registry-fail-with-no-basic-auth-credentials-error/16358/37), `docker pull` requires login/password.
- GitHub actions [doesn't support a short version of the `GITHUB_SHA` value](https://github.community/t/add-short-sha-to-github-context/16418), you need to build it manually in your pipeline as a reusable variable for the rest of your pipeline.
- Dependabot [doesn't support yet base image in the `FROM` instruction with `ARGS`](https://github.com/dependabot/dependabot-core/issues/2057).

Complementary resources:
- [Automating CI/CD pipelines with GitHub Actions and Google Cloud](https://resources.github.com/webcasts/Automating-CI-CD-Actions-Google-Cloud/)

Here we are, hope you enjoyed that one and that you learned different tips for your own CI pipelines. Like you could see, compliance and security checks are shifted left, in other words they are taking into account early in the development process thanks to this CI definition. From there, we have a container ready to be deploy in Kubernetes.

Cheers!