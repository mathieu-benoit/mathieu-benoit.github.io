---
title: buildah, a tool to facilitate building oci container images
date: 2020-02-01
tags: [azure, containers, kubernetes]
description: let's build your own oci container images with buildah
aliases:
    - /buildah/
---
My previous blog article was about some [findings and learnings I got with podman, a daemonless container engine]({{< ref "/posts/2020/01/podman.md" >}}). With podman we are able to run commands like: `podman pull|push|tag|run|images|ps` and many others (`podman help`) without any Docker Daemon installed. And again, at the end of the day, if you are comfortable with that, you could uninstall Docker and do this: `alias docker=podman`.

Now what about building your own OCI Container images? If you would like to successfully run the command podman build, you will need to install [buildah](https://buildah.io/) too.

[![](https://camo.githubusercontent.com/843f7639202a27bf5b6abc2afcc405e82804156a/68747470733a2f2f63646e2e7261776769742e636f6d2f636f6e7461696e6572732f6275696c6461682f6d61737465722f6c6f676f732f6275696c6461682d6c6f676f5f6c617267652e706e67)](https://camo.githubusercontent.com/843f7639202a27bf5b6abc2afcc405e82804156a/68747470733a2f2f63646e2e7261776769742e636f6d2f636f6e7461696e6572732f6275696c6461682f6d61737465722f6c6f676f732f6275696c6461682d6c6f676f5f6c617267652e706e67)

_Image taken from [here](https://github.com/containers/buildah)_

# Installing buildah

You could follow [those instructions](https://github.com/containers/buildah/blob/master/install.md) to see how to install buildah. In my case below I will install buildah on Ubuntu 18.04. Since I already setup the `Release.key` part by previously installing podman, I just need to run:
```
sudo apt-get update -qq 
sudo apt-get -qq -y install buildah
```

_Note: if you are using the `RUN` command in your `Dockerfile`, you will need to install runc too: `sudo apt-get -qq -y install runc`._

# Building and running an OCI Container Image with buildah

Now let's build our first OCI container image, first of all we need a Containerfile (we will keep the notion of Dockerfile since it works with buildah/podman too):

Let's have this Dockerfile:
```
FROM busybox:latest
CMD ["date"]
```

And then run this command:
```
podman build -t date .
```

If you run podman images, you should see:
```
REPOSITORY     TAG    IMAGE ID     CREATED     SIZE
localhost/date latest 022bdd32ce0e 8 hours ago 1.44 MB
```

Now let's run this Container Image by running this command: podman run date, you should get this kind of output:
```
Sun Feb  2 02:01:34 UTC 2020
```

Reminder: if you are running this in WSL2, you should use:
- `podman --cgroup-manager=cgroupfs --events-backend=file build` instead of `podman build`
- `podman --cgroup-manager=cgroupfs --events-backend=file run` instead of `podman run`

To go further, I also gave a try to building "more complex" Container images with NodeJS, PHP, Golang and .NET Core containerized app, for this I leveraged this [Azure/phippyandfriends](https://github.com/Azure/phippyandfriends) repository. The command podman build has worked like a charm with them! ;)

Note: when I built the .NET Core app (parrot), I got these warnings:
```
STEP 6: RUN dotnet publish -c Release -o out
ERRO\[0234\] Can't add file /var/lib/containers/storage/overlay/5dba96836efb5e2cfe45ae7c9a711a8db5e0805bd88ba7af5b83b044fe184d65/diff/tmp/CoreFxPipe\_root.b5he0\_wwfcD\_lH7g471Brpw4X to tar: archive/tar: sockets not supported
ERRO\[0235\] Can't add file /var/lib/containers/storage/overlay/5dba96836efb5e2cfe45ae7c9a711a8db5e0805bd88ba7af5b83b044fe184d65/diff/tmp/dotnet-diagnostic-52-766545-socket to tar: archive/tar: sockets not supported
ERRO\[0235\] Can't add file /var/lib/containers/storage/overlay/5dba96836efb5e2cfe45ae7c9a711a8db5e0805bd88ba7af5b83b044fe184d65/diff/tmp/dotnet-diagnostic-76-766850-socket to tar: archive/tar: sockets not supported
ERRO\[0235\] Can't add file /var/lib/containers/storage/overlay/5dba96836efb5e2cfe45ae7c9a711a8db5e0805bd88ba7af5b83b044fe184d65/diff/tmp/hn2K8eq8bHUcTVSgvuckPlSK9tw9\_ORiMDm\_Vn4ylfI to tar: archive/tar: sockets not supported
```
The Container image is built successfully and we are even able to successfully run this Container. So not sure what's the impact of this. Maybe that's related to this [open buildah's issue](https://github.com/containers/buildah/issues/1888).

With that said, here are some differences in term of Container Images size:
- `parrot` (.NET Core)
    - With Docker: 117 MB
    - With podman/buildah: 117 MB (same size)
- `captainkube` (Golang)
    - With Docker: 43.7 MB
    - With podman/buildah: 43.6 MB (-0.1 MB)
- `phippy` (PHP)
    - With Docker: 427 MB
    - With podman/buildah: 388 MB (-39 MB)
- `nodebrady` (NodeJS)
    - With Docker: 92.8 MB
    - With podman/buildah: 101 MB (+8.2 MB)

Interesting...

# Pushing an OCI Container Image in Container Registry

I won't go through the commands `pull|push` I presented in [my previous blog article with podman]({{< ref "/posts/2020/01/podman.md" >}}), but I was able to successfully push the date image in my DockerHub as well as in an Azure Container Registry (ACR).

In ACR, the icon of your Container image type will differ like you could see on the image below, on your left an image built with Docker and on your right an image built with podman/buildah:

[![](https://1.bp.blogspot.com/-5bTcYqKRE6o/XjYWEynYptI/AAAAAAAAUuM/qAiBX7Ri6O0qEN4wj9LD3SVud2We_rXSgCLcBGAsYHQ/s1600/Capture.PNG)](https://1.bp.blogspot.com/-5bTcYqKRE6o/XjYWEynYptI/AAAAAAAAUuM/qAiBX7Ri6O0qEN4wj9LD3SVud2We_rXSgCLcBGAsYHQ/s1600/Capture.PNG)

Since [I'm using Azure Security Center (ASC) to scan my Container images in ACR]({{< ref "/posts/2019/11/scanning-containers-with-asc.md" >}}), I found out that for now there is an issue ("Scan error" without any details information) meaning that is not yet supported (I reached out to the Product Group Team, will see what they'll say):

[![](https://1.bp.blogspot.com/-2VprSVf_nEw/XjYXqBqOmvI/AAAAAAAAUuY/U1xyUXN6fqcu753npuNnn_b5it04XPwNQCLcBGAsYHQ/s1600/Capture.PNG)](https://1.bp.blogspot.com/-2VprSVf_nEw/XjYXqBqOmvI/AAAAAAAAUuY/U1xyUXN6fqcu753npuNnn_b5it04XPwNQCLcBGAsYHQ/s1600/Capture.PNG)

# Deploying an OCI Container Image on AKS

Now what about running an OCI Container Image on Kubernetes, let's try this out on Azure Kubernetes Service (AKS).
Let's run `kubectl run date --image mabenoit/date`.
If you do `kubectl get pod` then, you will see that your pod has the status `ImagePullBackoff`.
By doing a kubectl describe of this pod, you will find in the Events section this error:
```
Failed to pull image "mabenoit/date": rpc error: code = Unknown desc = Error response from daemon: mediaType in manifest should be 'application/vnd.docker.distribution.manifest.v2+json' not ''.
```
Depending on which version of Docker/Moby your are running as the CRI of your Kubernetes cluster you may get [this issue](https://github.com/moby/moby/issues/39727). AKS is using its own Moby version based on the upstream version, currently the Azure Moby version is 3.0.8 corresponding to [Docker 19.03.4](https://github.com/docker/docker-ce/blob/v19.03.5/CHANGELOG.md#19034-2019-10-17). You could find out with the mentioned issue that's fixed in [Docker 19.03.5](https://github.com/docker/docker-ce/blob/v19.03.5/CHANGELOG.md#19035-2019-11-13), which corresponds to Azure Moby version 3.0.9. Before getting this version in AKS, we will need to have [this recent AKS-Engine's PR](https://github.com/Azure/aks-engine/pull/2613) packaged in a new version/release of AKS-Engine, which then will be integrated in AKS. Looking forward to it!

# Further considerations and resources

- [podman, a daemonless container engine]({{< ref "/posts/2020/01/podman.md" >}})
- [How to run Podman on Windows with WSL2](https://www.redhat.com/sysadmin/podman-windows-wsl2)
- [Podman and Buildah for Docker users](https://developers.redhat.com/blog/2019/02/21/podman-and-buildah-for-docker-users/)
- [Best practices for running Buildah in a container](https://developers.redhat.com/blog/2019/02/21/podman-and-buildah-for-docker-users/)
    - Yep! That's will be a future blog article on my blog, my use case will be to leverage this within Azure DevOps Pipelines, stay tuned! ;)

Hope you enjoyed those findings and learnings about podman and buildah, really promising!  

Cheers!