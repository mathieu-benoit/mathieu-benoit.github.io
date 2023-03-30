---
title: sail sharp, 8 tips to optimize and secure dotnet containers
date: 2023-01-23
tags: [kubernetes, containers, dotnet]
description: FIXME
draft: true
aliases:
    - /sail-sharp/
---
https://github.com/mathieu-benoit/sail-sharp
https://github.com/GoogleCloudPlatform/microservices-demo/blob/main/src/cartservice/src/Dockerfile
https://developers.redhat.com/articles/2023/03/23/10-tips-writing-secure-maintainable-dockerfiles
https://medium.com/@didourebai/best-practices-to-prepare-net-docker-images-26ce72d5cf7d

I have been [one of the top contributors to the Online Boutique repository so far](https://github.com/GoogleCloudPlatform/microservices-demo/pulls?q=is%3Apr+author%3Amathieu-benoit+is%3Aclosed). I learned a lot from these contributions to the `golang`, `python`, `dotnet`, `java` and `nodejs` apps. Some of my contributions, among others, were about optimizing and securing the container images for all these apps. Today, in this blog post, I will highlight 8 tips to optimize and secure dotnet containers based on what I have brought to the [`cartservice` app](https://github.com/GoogleCloudPlatform/microservices-demo/tree/main/src/cartservice):
1. Multi-stage build
1. Optimized bundled application
1. Small base image
1. Immutable base image
1. Update dependencies
1. `.dockerignore`
1. Unprivilege container
1. Read-only container filesystem

_Important notes: meanwhile some of the concepts could be applicable to Windows containers, this blog post is only covering Linux containers. Furthermore, Im not taking into account the [multi-platform container support](https://devblogs.microsoft.com/dotnet/improving-multiplatform-container-support/), just supporting `amd64` and nor `arm64` as an example._

Create a folder where we will drop all the files needed for this blog post:
```bash
mkdir my-sample-app
```

Create a minimal ASP.NET app from scratch:
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

Create our first `Dockerfile` with a multi-stage build:
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
We can see that the size of the container image is 288MB on disk locally.

You can 
```bash
docker run -d -p 80:80 my-sample-app
curl localhost:80
```

## Optimized bundled application

When using `dotnet publish`, we will use different features to optimized the size of the bundled application:
- 
  - Update the Dockerfile with `dotnet publish --self-contained true` + `mcr.microsoft.com/dotnet/runtime-deps:7.0`
  - We can see that the size of the container image is 215MB on disk locally.
- `-p:PublishSingleFile=true`
  - We can see that the size of the container image is 207MB on disk locally.
- `-p:PublishTrimmed=True -p:TrimMode=partial`
  - We can see that the size of the container image is 148MB on disk locally.

With `-p:TrimMode=full`, getting 136MB, but not working in my case because of this warning when doing `dotnet publish`:
```
warning IL2026: Using member 'Microsoft.AspNetCore.Builder.EndpointRouteBuilderExtensions.MapGet(IEndpointRouteBuilder, String, Delegate)' which has 'RequiresUnreferencedCodeAttribute' can break functionality when trimming application code. This API may perform reflection on the supplied delegate and its parameters. These types may be trimmed if not directly referenced.
```

## Small base image

-r linux-musl-x64 for restore and publish
mcr.microsoft.com/dotnet/runtime-deps:7.0-alpine3.17-amd64

We can see that the size of the container image is 43.2MB on disk locally.

_Note: if this app was compatible with `-p:TrimMode=full`, the size of the container image would have been 31.5MB on disk locally._

## Immutable base image

mcr.microsoft.com/dotnet/sdk:7.0@sha256:f712881bafadf0e56250ece1da28ba2baedd03fb3dd49a67f209f9d0cf928e81

mcr.microsoft.com/dotnet/runtime-deps:7.0-alpine3.17-amd64@sha256:941c0748b773dd13f2930cded91d01f62d357a785550c25eabe3d53d7997ae4b

_Note: it s also highly encouraged that you store these two base images in your own private container registry. You will guarantee their provenance, you will be able to scan them, etc._

## Update dependencies

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

```dockerfile
ENV DOTNET_EnableDiagnostics=0
```

You can now run this container with `--read-only`:
```bash
docker run -d -p 80:7070 -u 1000 --read-only my-sample-app
curl localhost:80
```

## Thats a wrap!

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

FIXME - remove wget