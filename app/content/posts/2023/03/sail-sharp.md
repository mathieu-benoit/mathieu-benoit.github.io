---
title: sail sharp, 8 tips to optimize and secure your .net containers
date: 2023-03-31
tags: [kubernetes, containers, dotnet, security]
description: let s go through 8 tips to optimize and secure your .net containers, based on my contributions to the online boutique sample apps
draft: true
aliases:
    - /sail-sharp/
---
https://developers.redhat.com/articles/2023/03/23/10-tips-writing-secure-maintainable-dockerfiles
https://medium.com/@didourebai/best-practices-to-prepare-net-docker-images-26ce72d5cf7d

![Sail Sharp: .NET on Kubernetes](https://github.com/mathieu-benoit/my-images/raw/main/sail-sharp.png)

In February 2021, I got this opportunity to deliver this talk [Sail Sharp, .NET Core & Kubernetes](https://www.youtube.com/watch?v=FqwjSZqpJs8) for the .NET Meetup in Quebec city (it was in French). I illustrated the best practices to prepare any .NET applications for Kubernetes. I was using the `cartservice` app (in `dotnet`) from the very popular [Online Boutique sample apps](https://github.com/GoogleCloudPlatform/microservices-demo).

Since then, I have been [one of the top contributors to the Online Boutique repository](https://github.com/GoogleCloudPlatform/microservices-demo/pulls?q=is%3Apr+author%3Amathieu-benoit+is%3Aclosed). I contributed to the `golang`, `python`, `dotnet`, `java` and `nodejs` apps. I learned a lot. Some of my contributions, among others, were about optimizing and securing the container images for all these apps.

Here is the high-level timeline of my contributions related to the [`cartservice` app](https://github.com/GoogleCloudPlatform/microservices-demo/tree/main/src/cartservice):
- 2020-11 - [.NET 2 --> .NET 3](https://github.com/GoogleCloudPlatform/microservices-demo/pull/435) --> [.NET 5](https://github.com/GoogleCloudPlatform/microservices-demo/pull/445)
- 2020-12 - [Managed gRPC](https://github.com/GoogleCloudPlatform/microservices-demo/pull/454)
- 2021-01 - [Memorystore Redis](https://github.com/GoogleCloudPlatform/microservices-demo/pull/505) (doc)
- 2021-11 - [.NET 6](https://github.com/GoogleCloudPlatform/microservices-demo/pull/629)
- 2022-03 - [`NetworkPolicies`](https://github.com/GoogleCloudPlatform/microservices-demo/pull/778)
- 2022-05 - [Better `IDistributedCache` implementation](https://github.com/GoogleCloudPlatform/microservices-demo/pull/838)
- 2022-06 - [Unprivilege container](https://github.com/GoogleCloudPlatform/microservices-demo/pull/848)
- 2022-09 - [.NET 7](https://github.com/GoogleCloudPlatform/microservices-demo/pull/1008)
- 2022-09 - [Native gRPC Healthcheck for `livenessProbe` and `readinessProbe`](https://github.com/GoogleCloudPlatform/microservices-demo/pull/1102)
- 2022-09 - [Spanner as database option](https://github.com/GoogleCloudPlatform/microservices-demo/pull/1109) (reviewer and contributor)
- 2022-12 - [IPv6](https://github.com/GoogleCloudPlatform/microservices-demo/pull/1340)
- 2022-12 - [Helm chart with the addition of the `AuthorizationPolicies`](https://github.com/GoogleCloudPlatform/microservices-demo/pull/1353)

_As a side note, I started my journey with the [.NET Framework version 3.0](https://en.wikipedia.org/wiki/.NET_Framework_version_history#.NET_Framework_3.0) (only on Windows at that time) in 2006! Since then, I have been amazed about the evolution of the [.NET ecosystem](https://dotnetfoundation.org/). And to be honest all these contributions helped me to stay up-to-date and have a lot of fun while learning! :)_

Wow! Quite a ride, isn’t it?

Today, in this blog post, I will highlight 8 tips to optimize and secure your .NET containers based on what I have learned based on all of that:
1. [Multi-stage build](#multi-stage-build)
1. [Optimized bundled application](#optimized-bundled-application)
1. [Small base image](#small-base-image)
1. [Immutable base image](#immutable-base-image)
1. [Update dependencies](#update-dependencies)
1. [`.dockerignore`](#dockerignore)
1. [Unprivilege container](#unprivilege-container)
1. [Read-only container filesystem](#read-only-container-filesystem)

If you want to see the final `Dockerfile` and the `Deployment` manifest to deploy a secure and optimized .NET application in Kubernetes, feel free to directly jump to the end of this blog post.

_Disclaimer: Whereas some of the concepts could be applicable to Windows containers, this blog post is only covering Linux containers. Furthermore, I’m not taking into account the [multi-platform container support](https://devblogs.microsoft.com/dotnet/improving-multiplatform-container-support/), I’m just supporting `amd64` and not `arm64` as an example._

Create a folder where we will drop all the files needed for this blog post:
```bash
mkdir my-sample-app
```

Create a minimal and simple ASP.NET app we will use for this blog post:
```bash
cat <<EOF > my-sample-app/Program.cs
using Microsoft.AspNetCore.Builder;
var builder = WebApplication.CreateBuilder(args);
var app = builder.Build();
app.MapGet("/", () => "Hello, World!");
app.Run();
EOF
cat <<EOF > my-sample-app/my-sample-app.csproj
<Project Sdk="Microsoft.NET.Sdk.Web">
  <PropertyGroup>
    <TargetFramework>net7.0</TargetFramework>
  </PropertyGroup>
</Project>
EOF
```

## Multi-stage build

Create our first `Dockerfile` with a multi-stage build. That’s not the final one, until then, please bear with me:
```bash
cat <<EOF > my-sample-app/Dockerfile
FROM mcr.microsoft.com/dotnet/sdk:7.0 as builder
WORKDIR /app
COPY my-sample-app.csproj .
RUN dotnet restore my-sample-app.csproj -r linux-x64
COPY . .
RUN dotnet publish my-sample-app.csproj -r linux-x64 -c release -o /my-sample-app --no-restore

FROM mcr.microsoft.com/dotnet/runtime:7.0
WORKDIR /app
COPY --from=builder /my-sample-app .
ENTRYPOINT ["/app/my-sample-app"]
EOF
```

[This `Dockerfile` uses multi-stage build](https://docs.docker.com/build/building/multi-stage/), which optimizes the final size of the image by layering the build and leaving only required artifacts.

Let’s build this container image locally:
```bash
docker build -t my-sample-app my-sample-app/
```

We can see that the size of the container image is **288MB** on disk locally.

You can locally run the container and test that it is working successfully:
```bash
docker run -d -p 80:80 my-sample-app
curl localhost:80
```

## Optimized bundled application

When using `dotnet publish`, we can use different features to optimize the size of the bundled application:
- [Self-contained deployment](https://learn.microsoft.com/en-us/dotnet/core/deploying/runtime-patch-selection)
  - Update the `Dockerfile` with `dotnet publish --self-contained true`.
  - Update the `Dockerfile` with `mcr.microsoft.com/dotnet/runtime-deps:7.0` as the final base image.
  - We can see that the size of the container image is now **215MB** on disk locally.
  - [Should you use self-contained or framework-dependent publishing in Docker images?](https://andrewlock.net/should-i-use-self-contained-or-framework-dependent-publishing-in-docker-images/)
- [Single-file deployment](https://learn.microsoft.com/en-us/dotnet/core/deploying/single-file/overview)
  - Update the `Dockerfile` with `dotnet publish -p:PublishSingleFile=true`.
  - We can see that the size of the container image is now **207MB** on disk locally.
- [Trim self-contained deployments and executables](https://learn.microsoft.com/en-us/dotnet/core/deploying/trimming/trim-self-contained)
  - Update the `Dockerfile` with `dotnet publish -p:PublishTrimmed=True -p:TrimMode=partial`.
  - We can see that the size of the container image is now **148MB** on disk locally.
  - If your application works with `-p:TrimMode=full` that’s even better. See note below.

With `-p:TrimMode=full`, the size of the container image is now **136MB** on disk locally, but the container is then not working in my case because of this warning when doing `dotnet publish`:
```
warning IL2026: Using member 'Microsoft.AspNetCore.Builder.EndpointRouteBuilderExtensions.MapGet(IEndpointRouteBuilder, String, Delegate)' which has 'RequiresUnreferencedCodeAttribute' can break functionality when trimming application code. This API may perform reflection on the supplied delegate and its parameters. These types may be trimmed if not directly referenced.
```

## Small base image

`mcr.microsoft.com/dotnet/runtime-deps:7.0-alpine3.17-amd64`
`-r linux-musl-x64` for `dotnet restore` and `dotnet publish`

We can see that the size of the container image is now **43.2MB** on disk locally. Impressive! Isn’t it? 

_Note: if this app was compatible with `-p:TrimMode=full`, the size of the container image would have been now **31.5MB** on disk locally._

## Immutable base image

mcr.microsoft.com/dotnet/sdk:7.0@sha256:f712881bafadf0e56250ece1da28ba2baedd03fb3dd49a67f209f9d0cf928e81

mcr.microsoft.com/dotnet/runtime-deps:7.0-alpine3.17-amd64@sha256:941c0748b773dd13f2930cded91d01f62d357a785550c25eabe3d53d7997ae4b

_Note: it s also highly encouraged that you store these two base images in your own private container registry. You will guarantee their provenance, you will be able to scan them, etc._

## Update dependencies

An important aspect is to keep your dependencies up-to-date in order to fix CVEs, catch new features, etc. One way to help you with that, in an automated way, is to leverage tools like [`Renovate`]() or [`Dependabot`](https://docs.github.com/en/code-security/dependabot/working-with-dependabot) if you are using GitHub.

Here is an example of 
```bash
cat <<EOF > .github/dependabot.yml
version: 2
updates:
  - package-ecosystem: "docker"
    directory: "/my-sample-app"
    schedule:
      interval: "daily"
  - package-ecosystem: "nuget"
    directory: "/my-sample-app"
    schedule:
      interval: "daily"
```

## .dockerignore

```bash
cat <<EOF > my-sample-app/.dockerignore
**/*.sh
**/*.bat
**/bin/
**/obj/
**/out/
Dockerfile*
EOF
```

## Unprivilege container

```dockerfile
EXPOSE 7070
ENV ASPNETCORE_URLS=http://*:7070
USER 1000
```

You can now run this container with `-u 1000` on port `7070`:
```bash
docker run -d -p 80:7070 -u 1000 my-sample-app
curl localhost:80
```

## Read-only container filesystem

To make the container in read-only mode on filesystem, `DOTNET_EnableDiagnostics` needs to be turned off. `DOTNET_EnableDiagnostics` allows is used for debugging, profiling, and other diagnostics.

```dockerfile
ENV DOTNET_EnableDiagnostics=0
```

You can now run this container with `--read-only`:
```bash
docker run -d -p 80:7070 -u 1000 --read-only my-sample-app
curl localhost:80
```

## That’s a wrap!

Congrats!

With these 8 tips illustrated throughout this blog post, we:
- Reduced the surface of attack of the container image
- Illustrated tips to improve the day-2 operations in order to keep our dependencies up-to-date
- Made the container running as unprivilege

Here is the final Dockerfile:
```dockerfile
FROM mcr.microsoft.com/dotnet/sdk:7.0@sha256:f712881bafadf0e56250ece1da28ba2baedd03fb3dd49a67f209f9d0cf928e81 as builder
WORKDIR /app
COPY my-sample-app.csproj .
RUN dotnet restore my-sample-app.csproj -r linux-musl-x64
COPY . .
RUN dotnet publish my-sample-app.csproj -r linux-musl-x64 -c release -o /my-sample-app --no-restore --self-contained true -p:PublishSingleFile=true -p:PublishTrimmed=true -p:TrimMode=partial

FROM mcr.microsoft.com/dotnet/runtime-deps:7.0-alpine3.17-amd64@sha256:941c0748b773dd13f2930cded91d01f62d357a785550c25eabe3d53d7997ae4b
WORKDIR /app
COPY --from=builder /my-sample-app .
EXPOSE 7070
ENV ASPNETCORE_URLS=http://*:7070
ENV DOTNET_EnableDiagnostics=0
USER 1000
ENTRYPOINT ["/app/my-sample-app"]
```

And if you want to deploy this container image in a secure manner in Kubernetes, here you are:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-sample-app
  labels:
    app: my-sample-app
spec:
  selector:
    matchLabels:
      app: my-sample-app
  template:
    metadata:
      labels:
        app: my-sample-app
    spec:
      securityContext:
        fsGroup: 1000
        runAsGroup: 1000
        runAsNonRoot: true
        runAsUser: 1000
        seccompProfile:
          type: RuntimeDefault
      containers:
        - name: my-sample-app
          securityContext:
            allowPrivilegeEscalation: false
            capabilities:
              drop:
                - ALL
            privileged: false
            readOnlyRootFilesystem: true
          image: my-sample-app:latest
          ports:
            - containerPort: 7070
```

We are now ready to Sail Sharp! Hope you enjoyed that one!

SIZE
REPOSITORY                              TAG                                     IMAGE ID       CREATED       SIZE
mcr.microsoft.com/dotnet/sdk            7.0.202                                 44f75b33d075   9 hours ago   775MB
mcr.microsoft.com/dotnet/runtime-deps   7.0.4                                   b53cbd54f8b3   9 hours ago   117MB
mcr.microsoft.com/dotnet/runtime-deps   7.0.4-cbl-mariner2.0-distroless-amd64   574233947e6b   8 days ago    26.4MB
mcr.microsoft.com/dotnet/runtime-deps   7.0.4-alpine3.17-amd64                  ada21ea6f003   8 days ago    12.1MB

TRIVY
mcr.microsoft.com/dotnet/runtime-deps:7.0.4-alpine3.17-amd64 (alpine 3.17.2)
Total: 2 (UNKNOWN: 0, LOW: 0, MEDIUM: 2, HIGH: 0, CRITICAL: 0)
mcr.microsoft.com/dotnet/runtime-deps:7.0.4-cbl-mariner2.0-distroless-amd64 (cbl-mariner 2.0.20230303)
Total: 6 (UNKNOWN: 0, LOW: 0, MEDIUM: 1, HIGH: 4, CRITICAL: 1)

SYFT
syft mcr.microsoft.com/dotnet/runtime-deps:7.0.4-cbl-mariner2.0-distroless-amd64
[13 packages]
NAME                         VERSION               TYPE 
distroless-packages-minimal  0.1-3.cm2             rpm   
e2fsprogs-libs               1.46.5-3.cm2          rpm   
filesystem                   1.1-12.cm2            rpm   
glibc                        2.35-3.cm2            rpm   
krb5                         1.19.4-1.cm2          rpm   
libgcc                       11.2.0-4.cm2          rpm   
libstdc++                    11.2.0-4.cm2          rpm   
mariner-release              2.0-35.cm2            rpm   
openssl                      1.1.1k-21.cm2         rpm   
openssl-libs                 1.1.1k-21.cm2         rpm   
prebuilt-ca-certificates     2547388:2.0.0-10.cm2  rpm   
tzdata                       2022g-1.cm2           rpm   
zlib                         1.2.12-2.cm2          rpm
syft mcr.microsoft.com/dotnet/runtime-deps:7.0.4-alpine3.17-amd64
[25 packages]
NAME                    VERSION                TYPE   
alpine-baselayout       3.4.0-r0               apk     
alpine-baselayout-data  3.4.0-r0               apk     
alpine-keys             2.4-r1                 apk     
apk-tools               2.12.10-r1             apk     
busybox                 1.35.0                 binary  
busybox                 1.35.0-r29             apk     
busybox-binsh           1.35.0-r29             apk     
ca-certificates         20220614-r4            apk     
ca-certificates-bundle  20220614-r4            apk     
keyutils-libs           1.6.3-r1               apk     
krb5-conf               1.0-r2                 apk     
krb5-libs               1.20.1-r0              apk     
libc-utils              0.7.2-r3               apk     
libcom_err              1.46.6-r0              apk     
libcrypto3              3.0.8-r0               apk     
libgcc                  12.2.1_git20220924-r4  apk     
libintl                 0.21.1-r1              apk     
libssl3                 3.0.8-r0               apk     
libstdc++               12.2.1_git20220924-r4  apk     
libverto                0.3.2-r1               apk     
musl                    1.2.3-r4               apk     
musl-utils              1.2.3-r4               apk     
scanelf                 1.3.5-r1               apk     
ssl_client              1.35.0-r29             apk     
zlib                    1.2.13-r0              apk