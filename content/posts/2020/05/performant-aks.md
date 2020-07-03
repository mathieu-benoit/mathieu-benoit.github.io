---
title: setup a performant aks cluster
date: 2020-05-31
tags: [azure, kubernetes]
description: let's highlight tips & tricks about the setup of an aks cluster to make it more performant as its getting more and more containers at scale.
aliases:
    - /performant-aks/
---
The intent of this blog article is to highlight advanced setups for advanced scenarios on Azure Kubernetes Service (AKS) as the AKS cluster hosts a consequent number of containers with a lot of communication in and out, at scale. So it may or may not apply to your own workload but at least we will mention concepts and settings which could improve performance and avoid overhead or throttling.

Topics covered in the blog article:
- [K8s version]({{< ref "#k8s-version" >}})
- [System Nodepool]({{< ref "#system-nodepool" >}})
- [Autoscaling]({{< ref "#autoscaling" >}})
- [VM Size]({{< ref "#vm-size" >}})
- [Accelerated Networking]({{< ref "#accelerated-networking" >}})
- [Premium OS Disk]({{< ref "#premium-os-disk" >}})
- [IOPS]({{< ref "#iops" >}})
- [Azure CNI]({{< ref "#azure-cni" >}})
- [Allocated outbound ports]({{< ref "#allocated-outbound-ports" >}})
- [Further considerations]({{< ref "#further-considerations" >}})

# K8s version

**Goal: Get latest features, bug fixes and optimizations from K8s**

> The Kubernetes community releases minor versions roughly every three months. These releases include new features and improvements. Patch releases are more frequent (sometimes weekly) and are only intended for critical bug fixes in a minor version. These patch releases include fixes for security vulnerabilities or major bugs impacting a large number of customers and products running in production based on Kubernetes. It's recommended as a best-practice to [keep up-to-date with the K8S version of your cluster](https://docs.microsoft.com/azure/aks/supported-kubernetes-versions).

You could upgrade either your entire cluster or per nodepool by leveraging those commands below:
```
az aks upgrade
az aks nodepool upgrade
```

Complementary to this, you may want to [process node OS updates](https://docs.microsoft.com/azure/aks/node-updates-kured) as well to keep your OS updated.

# System Nodepool

**Goal: Minimize impact on system pods like CoreDNS and tunnelfront**

> [System node pools](https://docs.microsoft.com/azure/aks/use-system-pools) serve the primary purpose of hosting critical system pods such as CoreDNS and tunnelfront. User node pools serve the primary purpose of hosting your application pods. However, application pods can be scheduled on system node pools if you wish to only have one pool in your AKS cluster.

You could add a User nodepool by leveraging this command below:
```
az aks nodepool add \
    --mode User
```

_Note: for better resiliency, it's also recommended to have at least 3 Nodes per Nodepool._

# Autoscaling

**Goal: Horizontally increase amount of compute resources.**

> As you run applications in Azure Kubernetes Service (AKS), you may need to increase or decrease the amount of compute resources. As the number of application instances you need change, the number of underlying Kubernetes nodes may also need to change. You also might need to quickly provision a large number of additional application instances. [Your scaling options](https://docs.microsoft.com/azure/aks/concepts-scale) could be manual scale of your pod, horizontal pod autoscaler, manual scale of your nodes or cluster autoscaler.

For example, you could scale the number of your nodes by leveraging the command below:
```
az aks scale
az aks nodepool scale
```

# VM Size

**Goal: Choose the right vCPUs versus RAM versus IOPS depending on your workload**

> [This article](https://docs.microsoft.com/azure/virtual-machines/linux/sizes) describes the available sizes and options for the Azure virtual machines you can use to run your apps and workloads. It also provides deployment considerations to be aware of when you're planning to use these resources. You will find options for General purpose, Compute optimized, Memory optimized, GPU or even Hig performance compute scenarios.

You could look at the specs of the VM size you selected and then create an AKS cluster or a Nodepool by running the command below:
```
NODE_VM_SIZE=FIXME
LOCATION=FIXME
az vm list-skus \
    -l $LOCATION \
    --size $NODE_VM_SIZE
az aks create \
    --node-vm-size $NODE_VM_SIZE
az aks nodepool add \
    --node-vm-size $NODE_VM_SIZE
```

_Note: as a best practice, you may want to have different Nodepools with different VM sizes._

# Accelerated Networking

**Goal: Reduce networking overhead and CPU utilization during traffic in and out of the VM/Node**

> When [accelerated networking is enabled on a VM](https://docs.microsoft.com/azure/virtual-network/create-vm-accelerated-networking-cli#benefits), there is lower latency, reduced jitter, and decreased CPU utilization on the VM. With accelerated networking, network traffic arrives at the virtual machine's network interface (NIC), and is then forwarded to the VM. All network policies that the virtual switch applies are now offloaded and applied in hardware. Applying policy in hardware enables the NIC to forward network traffic directly to the VM, bypassing the host and the virtual switch, while maintaining all the policy it applied in the host.

_Note: as an illustration of this, you could find an explicit documentation and recommendation [when using Azure Database for PostgreSQL from AKS](https://docs.microsoft.com/azure/postgresql/concepts-aks#accelerated-networking)._

Some VM sizes do or do not support Accelerated Networking, you should check if the size you selected supports it or not by running the command below. Furthermore, the default VM size for the AKS Nodes is `Standard_DS2_v2` (which has Accelerated Networking enabled) with Terraform but with the [new recent Azure CLI version](https://github.com/Azure/azure-cli/pull/13541) it's now `Standard_D2s_v3` (which doesn't have Accelerated Networking enabled), you may want to change this size according to your needs:
```
NODE_VM_SIZE=FIXME
LOCATION=FIXME
az vm list-skus \
    -l $LOCATION \
    --size $NODE_VM_SIZE \
    --query "[0].capabilities | [?name=='AcceleratedNetworkingEnabled'].value"
az aks create \
    --node-vm-size $NODE_VM_SIZE
az aks nodepool add \
    --node-vm-size $NODE_VM_SIZE
```

# Premium OS Disk

**Goal: Get high-performance and low-latency OS disk support**

> [Azure premium SSDs](https://docs.microsoft.com/azure/virtual-machines/linux/premium-storage-performance) deliver high-performance and low-latency disk support for virtual machines (VMs) with input/output (IO)-intensive workloads. Premium SSDs are suitable for mission-critical production applications. Premium SSDs can only be used with VM series that are premium storage-compatible.

Some VM sizes do or do not support Premium storage, you should check if the size you selected supports it or not by running the command below. Furthermore, the default OS Disk size for the AKS Nodes is 100GB, you may want to change this size according to your needs:
```
NODE_VM_SIZE=FIXME
LOCATION=FIXME
az vm list-skus \
    -l $LOCATION \
    --size $NODE_VM_SIZE \
    --query "[0].capabilities | [?name=='PremiumIO'].value"
az aks create \
    --node-vm-size $NODE_VM_SIZE \
    --node-osdisk-size
az aks nodepool add \
    --node-vm-size $NODE_VM_SIZE \
    --node-osdisk-size
```

_Note: [Azure Premium Storage offers a variety of sizes](https://docs.microsoft.com/azure/virtual-machines/linux/premium-storage-performance#premium-storage-disk-sizes) so you can choose one that best suits your needs. Each disk size has a different scale limit for IOPS, bandwidth, and storage. Choose the right Premium Storage Disk size depending on the application requirements and the high scale VM size._

# IOPS

**Goal: Avoid application performance throttling**

> [The IOPS and Throughput limits of each Premium disk](https://docs.microsoft.com/azure/virtual-machines/linux/premium-storage-performance#high-scale-vm-sizes) size is different and independent from the VM scale limits. Make sure that the total IOPS and Throughput from the disks are within scale limits of the chosen VM size. As an example, suppose an application requirement is a maximum of 4,000 IOPS. To achieve this, you provision a P30 disk on a DS1 VM. The P30 disk can deliver up to 5,000 IOPS. However, the DS1 VM is limited to 3,200 IOPS. Consequently, the application performance will be constrained by the VM limit at 3,200 IOPS and there will be degraded performance. To prevent this situation, choose a VM and disk size that will both meet application requirements.

Each VM size has its own IOPS, you should check this value by running the command below. Furthermore, like discussed above the size of the OS disk will determine its own IOPS too, you may want to change this size according to your needs. For example: P10 (128GB) has 500 IOPS, P15 (256GB) has 1,100 IOPS, P20 (512GB) has 2,300 IOPS, P30 (1TB) has 5,000 IOPS and P40 (2TB) has 7,500 IOPS.
```
NODE_VM_SIZE=FIXME
LOCATION=FIXME
az vm list-skus \
    -l $LOCATION \
    --size $NODE_SIZE \
    --query "[0].capabilities | [?name=='UncachedDiskIOPS'].value" -o tsv
NODE_OSDISK_SIZE=FIXME
az aks create \
    --node-vm-size $NODE_VM_SIZE \
    --node-osdisk-size $NODE_OSDISK_SIZE
az aks nodepool add \
    --node-vm-size $NODE_VM_SIZE \
    --node-osdisk-size $NODE_OSDISK_SIZE
```

# Azure CNI

**Goal: Reduce networking overhead and CPU utilization during Pod communications**

> With [Azure CNI](https://docs.microsoft.com/azure/aks/concepts-network#azure-cni-advanced-networking) (as opposed to Kubenet), every pod will have their own IP address and they could be accessible from the other pods regardless of which host the pod is on and there won’t be any Network Address Translations (NAT) in pod-to-pod or node-to-pod or pod-to-node communications. Knowing that NAT translations are done in Linux using IPTables which brings in a performance overhead.

_Note: even if it's related to Calico, [this video](https://www.projectcalico.org/everything-you-need-to-know-about-kubernetes-networking-on-azure) really well explains the difference between Azure CNI versus Kubenet CNI. I also found this article [Networking with Kubernetes](https://medium.com/practo-engineering/networking-with-kubernetes-1-3db116ad3c98) very insightful about the differences between the networking modes._

You could define the Network Plugin of an AKS cluster at the creation time only:
```
az aks create \
    --network-plugin azure
```

# Allocated outbound ports

**Goal: Avoid SNAT port exhaustion when having a lot of egress communications**

https://docs.microsoft.com/azure/aks/load-balancer-standard#required-quota-for-customizing-allocatedoutboundports

> With [Standard Load Balancer with AKS](https://docs.microsoft.com/azure/aks/load-balancer-standard), at least one public IP or IP prefix is required for allowing egress traffic from the AKS cluster. The public IP or IP prefix is also required to maintain connectivity between the control plane and agent nodes as well as to maintain compatibility with previous versions of AKS. Furthermore, outbound allocated ports and their idle timeouts are used for [SNAT](https://docs.microsoft.com/azure/load-balancer/load-balancer-outbound-connections#snat). Consider changing the setting of `AllocatedOutboundPorts` or `IdleTimeoutInMinutes` if you expect to face SNAT exhaustion based on the above default configuration. Each additional IP address enables 64,000 additional ports for allocation, however the Azure Standard Load Balancer does not automatically increase the ports per node when more IP addresses are added. You can change these values by setting the load-balancer-outbound-ports and load-balancer-idle-timeout parameters.

> If you have applications on your cluster which are expected to establish a large number of connection to small set of destinations, eg. many frontend instances connecting to an SQL DB, you have a scenario [very susceptible to encounter SNAT Port exhaustion](https://docs.microsoft.com/azure/load-balancer/troubleshoot-outbound-connection#snatexhaust) (run out of ports to connect from). For these scenarios it's highly recommended to [increase the allocated outbound ports and outbound frontend IPs on the load balancer](https://docs.microsoft.com/azure/aks/load-balancer-standard#configure-the-allocated-outbound-ports). The increase should consider that one (1) additional IP address adds 64k additional ports to distribute across all cluster nodes.

You could scale the number of outbound IPs and Ports at the creation of the cluster or you could also update an existing cluster:
```
az aks create \
    --load-balancer-managed-outbound-ip-count \
    --load-balancer-outbound-ports \
    --load-balancer-idle-timeout
az aks update \
    --load-balancer-managed-outbound-ip-count \
    --load-balancer-outbound-ports \
    --load-balancer-idle-timeout
```

# Further considerations

Here are complementary and further considerations you may want to watch out:
- [Node Local DNS](https://github.com/Azure/AKS/issues/1492) - In Development
- [Proximity Placement Groups](https://azure.microsoft.com/updates/azure-kubernetes-service-aks-support-for-proximity-placement-groups-is-now-available/) - Public Preview
- [Node Image Upgrade](https://docs.microsoft.com/azure/aks/node-image-upgrade) - Public Preview



Here we are! Hope you enjoyed those tips and tricks. The advice is not to apply all of this to your workload but more having monitoring tools in place to track and watch the behavior and get insights of your cluster, your nodes, your containers and your applications. And then apply the most relevant recommendation(s) above accordingly. You may also want to leverage those resources below to help you with this:
- [AKS Diagnostics](https://docs.microsoft.com/azure/aks/concepts-diagnostics)
- [Azure Advisor integration with AKS](https://azure.microsoft.com/updates/azure-advisor-integration-with-aks-now-generally-available/)
- [Azure Monitor for containers](https://docs.microsoft.com/azure/azure-monitor/insights/container-insights-overview)
- [Linux Performance Troubleshooting](https://docs.microsoft.com/azure/aks/troubleshoot-linux)
- [kubernaughty - IO, resources contention notes, docs and tools](https://github.com/jnoller/kubernaughty)

Happy performant sailing, cheers! ;)
