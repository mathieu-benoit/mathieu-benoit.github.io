---
title: podman, a daemonless container engine
date: 2020-01-24
tags: [azure, containers, kubernetes]
description: let's have a look at podman, a daemonless container engine
aliases:
    - /podman/
---
I took the opportunity to play with [podman](https://podman.io/), an interesting project started by RedHat:  

> _What is Podman? Podman is a daemonless container engine for developing, managing, and running OCI Containers on your Linux System. Containers can either be run as root or in rootless mode. Simply put: `alias docker=podman`._

If you would like to have a detailed description of podman and buildah in comparison of Docker, I highly encourage you to read this great blog article on the RedHat Developers blog: [Podman and Buildah for Docker users](https://developers.redhat.com/blog/2019/02/21/podman-and-buildah-for-docker-users/).

[![](https://developers.redhat.com/blog/wp-content/uploads/2019/02/fig2.png)](https://developers.redhat.com/blog/wp-content/uploads/2019/02/fig2.png)

_Image reused [from this blog article](https://developers.redhat.com/blog/2019/02/21/podman-and-buildah-for-docker-users/)_

# Installing podman

You could follow [those instructions](https://podman.io/getting-started/installation) to see how to install podman. In my case below I will install podman on Ubuntu 18.04:
```
. /etc/os-release
sudo sh -c "echo 'deb http://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/x${NAME}\_${VERSION\_ID}/ /' > /etc/apt/sources.list.d/devel:kubic:libcontainers:stable.list"
wget -nv https://download.opensuse.org/repositories/devel:kubic:libcontainers:stable/x${NAME}\_${VERSION\_ID}/Release.key -O Release.key
sudo apt-key add - < Release.key
sudo apt-get update -qq
sudo apt-get -qq -y install podman
sudo mkdir -p /etc/containers
sudo curl https://raw.githubusercontent.com/projectatomic/registries/master/registries.fedora -o /etc/containers/registries.conf
sudo curl https://raw.githubusercontent.com/containers/skopeo/master/default-policy.json -o /etc/containers/policy.json
```

# Playing with podman

```
podman info
podman pull alpine
# Note: What! it's working?! Yes it does! Without any Docker Host/Machine/Daemon ;)
podman images
podman run -it --rm docker.io/library/alpine /bin/sh
# Note: If you are trying to execute this command with [WSL 1](https://docs.microsoft.com/windows/wsl), [you will get that issue](https://github.com/containers/libpod/issues/4325#issuecomment-577944685). You need to run this with WSL 2.
podman ps
```

You could run the command podman help to see what else you could do.

Now let's interact with a Container Registry and pushing an image there:
```
crName=<your-container-registry-name>
crLogin=<your-container-registry-login>
crPassword=<your-container-registry-password>
podman tag docker.io/library/alpine $crName/alpine
echo $crPassword | podman login $crName -u $crLogin --password-stdin
podman push $crName/alpine
```

Actually with podman you could easily do this in your bash environment: `alias docker=podman`, that's the goal!

I now invite you to see how you could build our own OCI Container (not Docker ;)) Images, with my other blog article: [buildah, a tool to facilitate building OCI container images]({{< ref "/posts/2020/02/buildah.md" >}}).

# Further readings

- [Reintroduction of Podman](https://www.projectatomic.io/blog/2018/02/reintroduction-podman/)
- [Container Security and new container technologies](https://events.redhat.com/accounts/register123/redhat/events/7013a000002d2jvaas/Quebec_Container_Security_and_New_Container_Technologies.pdf)
- [Demystifying Containers – Part II: Container Runtimes](https://www.cncf.io/blog/2019/07/15/demystifying-containers-part-ii-container-runtimes/)
- [Check Out Podman, Red Hat’s daemon-less Docker Alternative](https://thenewstack.io/check-out-podman-red-hats-daemon-less-docker-alternative/)
- [CNCF to host CRI-O](https://www.cncf.io/blog/2019/04/08/cncf-to-host-cri-o/)
- [Why Red Hat is investing in CRI-O and Podman](https://www.redhat.com/en/blog/why-red-hat-investing-cri-o-and-podman)
- [Coloringbook Container Commandos](https://github.com/mairin/coloringbook-container-commandos)

Hope you enjoyed this blog article and see how promising podman and others (actually the concept of the daemon-less container engine) are, cheers!