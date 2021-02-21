---
title: sail sharp, .net core & kubernetes
date: 2021-02-18
tags: [containers, security, gcp, kubernetes, dotnet, presentations, service-mesh, sre]
description: let's see how to secure and optimize your .net core app to be ready, optimized and secure for kubernetes
draft: true
aliases:
    - /sail-sharp/
---
I recently delivered a 1h-session named [Sail Sharp, .NET Core & Kubernetes](https://www.meetup.com/DotNet-Quebec/events/275866695/). Great experience and great learnings for me during the preparation as well as the delivery of that one.

The intent of this session was to show new great features with .NET 5 with a containerized gRPC API. And the goal was to show best practices to build containers and deploy them on Kubernetes by making sure governance and security checkpoints are in place as early as possible in the supply chain (i.e. CI/CD).

First, it's all about Personas and Stakeholders involved while dealing with Kubernetes. The exercise here is to say that Developers shouldn't do/touch Kubernetes in their day-to-day job (if possible). We are making a distinction and kind of contract of collaboration between the different personas involved: Apps developer, Apps operator, Security operator, Platform operator, Services operator and Organisation admin. Don't make me wrong, no silos at all, but streamlined collaboration with a lot of automation.

![Workflow and Personas from code to monitoring by going through CI/CD.](https://github.com/mathieu-benoit/sail-sharp/raw/main/personas.png)

Yes for sure those personas should know each others, collaborate, exchange roles, etc. and could even be the same person (depending on the size of the team or its maturity). But the idea here is that at the end of the day, developers should focus on what they do best, shiping code with value to the end users. And not doing Kubernetes, Terraform, etc. The latters should be for other personas like Apps, Security, Platform and Service operators.

The demo itself to show all that goodies, is the [`cartservice` I have updated](https://github.com/mathieu-benoit/cartservice) from the `OnlineBoutique` (aka `microservices-demo`) solution.

![Architecture diagram of the OnlineBoutique demo updated with my custom cartservice.](https://github.com/mathieu-benoit/sail-sharp/raw/main/architecture.png)

## .NET - Apps developer

- Local
- .NET 5
- gRPC
- Healthchecks
- Unittests
- Being up-to-date with new `Nuget` packages versions could be tough, I'm using [`dependabot`](https://github.com/mathieu-benoit/cartservice/blob/main/.github/dependabot.yml) to help me with this.

## Docker - Apps operator

In the [`Dockerfile`](https://github.com/mathieu-benoit/cartservice/blob/main/Dockerfile) you will see best practices to optimize the size of your images, the time of build, and make the final image more secure. Here are some examples:
- Multi-stage build to distinguish intermediary build images versus the final image
- `alpine`-based image to reduce the size, surface of attack, etc. of the final image
- Unit tests run during the `docker build` command to make sure we have rapid feedback on them
- `dotnet restore` is in a different step/layer than `dotnet publish` to optimize build time by reusing cache when possible
- The size of the .NET package is reduce at the bare minimu with those options `-p:PublishSingleFile=true -r linux-musl-x64 --self-contained true -p:PublishTrimmed=True -p:TrimMode=Link -c release`
- `grpc-health-probe` binary should be embedded into your image, that will allow to implement `livenessProbe` and `readinessProbe` properly in your Kubernetes manifest later.
- The final container image built is unprivilege thanks to few features enabled in the `Dockerfile`: `EXPOSE 7070`, `ENV ASPNETCORE_URLS=http://*:7070`, `USER 1000` and `ENV COMPlus_EnableDiagnostics=0`.
- Being up-to-date with new container base images versions could be tough but very important, so I'm using [`dependabot`](https://github.com/mathieu-benoit/cartservice/blob/main/.github/dependabot.yml) to help me with this.

As early as possible, you could run `docker build` and `docker run` to make sure the containerized app is still working accordingly. Tips, you could even (always) run your container with least privileges like this:
```
docker run -d -p 7070:7070 --read-only --cap-drop=ALL --user=1000 cartservice
```

## CI - Apps/Security operators

In the [GitHub actions definition](https://github.com/mathieu-benoit/cartservice/blob/main/.github/workflows/ci.yml) I'm using it to define the Continuous Integration (CI) of this app, you will find best practices to build a secure container image as artifact. Here are the steps I'm defining for this:
- Replace the base images's registry from the public one to the private container registry. Assuming, that someone put them in there as approved base images I could use for my own application. So here I'm just doing a `sed` to replace `mcr.microsoft.com` by my own container registry name.
- Once authenticated (`docker login`), build the container image (`docker build`). Like described in the previous section, we will run the unit tests during this step as well. Note: the size of the container image is captured to be able to track it in case we could see an unexpected increase with the image size.
- Run `dockle` on the container image to get insights about security and best practices on it.
- Scan this image with `trivy` to watch for security vulnerabilities.
- Run the container image as a smoke test as non-root and least privileges: `docker run -d -p 8080:8080 --read-only --cap-drop=ALL --user=1000`.
- Deploy a small `KinD` cluster to run the container image on it as a smoke test `kubectl create deployment cartservice --image=${IMAGE_NAME}`.
- Finally, if we are on the `main` branch and all the previous steps were successfull, we could push the container image into Google Artifact Registry.

The intent is to have a very generic approach in the tool you use (Jenkins, Azure Devops, etc.), here I'm using GitHub actions but at the end of the day, most of the steps are just bash scripts. Flexibility in the tools you leverage in the steps is key too, pick and choose the ones work best for you to make sure you have a robust CI pipeline able to raise issues as soon as possible.

To be able to push the container image in my private Google Artifact Registry, I needed to create a Service Account with least privileges (write in that registry only), grab the associated limited-in-time key and store it as a secret in my GitHub repository ([more info here](https://github.com/mathieu-benoit/cartservice#ci-setup-with-google-artifact-registry-and-github-actions)).

## CD - Security/Platform/Service operators

Now we have a container image ready to deploy, let's see the delivery and deployment part. Here we are taking a GitOps approach, where commits, branches, pull requests, etc. will act as the triggers for any deployment on any environment.
ACM / GitOps
Kubernetes manifest
-Unprivilege
-Calico
-Istio
-Liveness/Readiness
-VPA
Kubeval
OPA

If you are interested in seeing this in action, [here is the recording of this session in French](https://youtu.be/FqwjSZqpJs8), I walked the talk by releasing a new version by pointing the `cartservice` to Google Memorystore (redis) instead of having `redis` as container on Kubernetes, fix a bug with `cartservice` regarding the increment of the quantity in the cart and finally increase traffic from 10% to 50% on the `preview` route of the `frontend` app.

And that's it! I have put together [few resources as pointers and references there](https://github.com/mathieu-benoit/sail-sharp#resources) and I'm also thinking about [few more stuffs to improve the content of this demo](https://github.com/mathieu-benoit/sail-sharp/projects/1).

If you have any issue, feedback, improvement to share with me regarding all of this, please feel free to drop me a note [here](https://github.com/mathieu-benoit/cartservice/issues) or [here](https://github.com/mathieu-benoit/my-kubernetes-deployments/issues), thanks!

Hope you enjoyed that one, happy sailing, and don't forget, [stay sharp](https://youtu.be/x_IGNq4snx8)! ;)