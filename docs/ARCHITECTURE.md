# Architecture Documentation

This document provides detailed information about the architecture, design decisions, and technical implementation of the Talos OS on Proxmox infrastructure.

---

## Table of Contents

- [System Overview](#system-overview)
- [Component Architecture](#component-architecture)
- [Network Architecture](#network-architecture)
- [Storage Architecture](#storage-architecture)
- [Security Architecture](#security-architecture)
- [High Availability](#high-availability)
- [Scalability](#scalability)
- [Design Decisions](#design-decisions)

---

## System Overview

### Architecture Layers

The infrastructure is organized in distinct layers, each with specific responsibilities:

```
┌─────────────────────────────────────────────────────────────┐
│                    Application Layer                        │
│  (Kubernetes Workloads, Services, Ingress)                  │
└─────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│                  Orchestration Layer                        │
│  (Kubernetes Control Plane, etcd, Schedulers)               │
└─────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│                   Networking Layer                          │
│  (Cilium CNI, Service Mesh, Load Balancing)                 │
└─────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│                  Operating System Layer                     │
│  (Talos OS - Immutable, API-driven)                         │
└─────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│                 Virtualization Layer                        │
│  (Proxmox VE - KVM/QEMU)                                    │
└─────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│                    Hardware Layer                           │
│  (Physical Servers, Storage, Network)                       │
└─────────────────────────────────────────────────────────────┘
```

### Technology Stack

| Layer | Technology | Purpose |
|-------|-----------|---------|
| **Infrastructure** | Proxmox VE | Virtualization platform |
| **OS** | Talos OS | Immutable Kubernetes OS |
| **Orchestration** | Kubernetes | Container orchestration |
| **Networking** | Cilium | Advanced CNI with eBPF |
| **IaC** | OpenTofu/Terraform | Infrastructure provisioning |
| **Configuration** | Talhelper | Talos config management |
| **Secrets** | SOPS + Age | Encrypted secrets |
| **Automation** | Packer, Ansible | Template creation, host config |

---

## Component Architecture

### 1. Proxmox VE Cluster

**Purpose**: Provides the virtualization platform for running Talos OS VMs.

**Architecture**:
```
┌─────────────────────────────────────────────────────────┐
│                  Proxmox Cluster                        │
│                                                         │
│  ┌──────────┐      ┌──────────┐      ┌──────────┐     │
│  │  PVE1    │      │  PVE2    │      │  PVE3    │     │
│  │          │      │          │      │          │     │
│  │ Corosync │◄────►│ Corosync │◄────►│ Corosync │     │
│  │          │      │          │      │          │     │
│  └────┬─────┘      └────┬─────┘      └────┬─────┘     │
│       │                 │                 │            │
│       └─────────────────┴─────────────────┘            │
│                  Shared Storage                        │
│              (ZFS / Ceph / NFS)                        │
└─────────────────────────────────────────────────────────┘
```

**Key Features**:
- **High Availability**: 3+ node cluster with Corosync
- **Shared Storage**: ZFS, Ceph, or NFS for VM migration
- **Live Migration**: Move VMs between nodes without downtime
- **Backup**: Automated backup capabilities
- **API**: RESTful API for automation

**Configuration**:
- Managed via `proxmox-ansible/` playbooks
- Hardened with security best practices
- Optimized for Kubernetes workloads

### 2. Talos OS

**Purpose**: Minimal, immutable operating system designed for Kubernetes.

**Architecture**:
```
┌─────────────────────────────────────────────────────────┐
│                    Talos OS Node                        │
│                                                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │              Kubernetes Components              │   │
│  │  (kubelet, kube-proxy, container runtime)       │   │
│  └─────────────────────────────────────────────────┘   │
│                         ↕                               │
│  ┌─────────────────────────────────────────────────┐   │
│  │              Talos Services                     │   │
│  │  • apid (API server)                            │   │
│  │  • machined (system management)                 │   │
│  │  • trustd (certificate management)              │   │
│  │  • networkd (network configuration)             │   │
│  └─────────────────────────────────────────────────┘   │
│                         ↕                               │
│  ┌─────────────────────────────────────────────────┐   │
│  │           Linux Kernel (Minimal)                │   │
│  └─────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────┘
```

**Key Features**:
- **Immutable**: Read-only root filesystem
- **API-Driven**: No SSH, all management via API
- **Secure**: Minimal attack surface
- **Atomic Updates**: All-or-nothing upgrades
- **Self-Healing**: Automatic recovery from failures

**Customization**:
- System extensions via Image Factory
- Custom kernel modules
- Hardware-specific drivers (Intel/AMD microcode, QEMU guest agent)

### 3. Kubernetes Cluster

**Purpose**: Container orchestration and workload management.

**Control Plane Architecture**:
```
┌─────────────────────────────────────────────────────────┐
│              Kubernetes Control Plane                   │
│                                                         │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐ │
│  │   Master 1   │  │   Master 2   │  │   Master 3   │ │
│  │              │  │              │  │              │ │
│  │ API Server   │  │ API Server   │  │ API Server   │ │
│  │ Controller   │  │ Controller   │  │ Controller   │ │
│  │ Scheduler    │  │ Scheduler    │  │ Scheduler    │ │
│  │              │  │              │  │              │ │
│  │    etcd      │◄─┼────etcd──────┼─►│    etcd      │ │
│  └──────────────┘  └──────────────┘  └──────────────┘ │
│         ▲                  ▲                  ▲         │
│         │                  │                  │         │
│         └──────────────────┴──────────────────┘         │
│                      VIP: 192.168.1.230                 │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│                   Worker Nodes                          │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐             │
│  │ Worker 1 │  │ Worker 2 │  │ Worker N │             │
│  │          │  │          │  │          │             │
│  │ kubelet  │  │ kubelet  │  │ kubelet  │             │
│  │ Pods     │  │ Pods     │  │ Pods     │             │
│  └──────────┘  └──────────┘  └──────────┘             │
└─────────────────────────────────────────────────────────┘
```

**Key Components**:
- **etcd**: Distributed key-value store (3-node cluster)
- **API Server**: Kubernetes API endpoint (HA via VIP)
- **Controller Manager**: Manages controllers
- **Scheduler**: Pod scheduling decisions
- **kubelet**: Node agent
- **Container Runtime**: containerd

**High Availability**:
- 3 control plane nodes (odd number for etcd quorum)
- Virtual IP (VIP) for API server access
- Automatic leader election
- Load balancing across API servers

### 4. Cilium Networking

**Purpose**: Advanced Kubernetes networking with eBPF.

**Architecture**:
```
┌─────────────────────────────────────────────────────────┐
│                  Cilium Architecture                    │
│                                                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │            Application Layer                    │   │
│  │  (Services, Ingress, Network Policies)          │   │
│  └─────────────────────────────────────────────────┘   │
│                         ↕                               │
│  ┌─────────────────────────────────────────────────┐   │
│  │         Cilium Control Plane                    │   │
│  │  • cilium-operator (cluster-wide operations)    │   │
│  │  • cilium-agent (per-node agent)                │   │
│  └─────────────────────────────────────────────────┘   │
│                         ↕                               │
│  ┌─────────────────────────────────────────────────┐   │
│  │              eBPF Data Plane                    │   │
│  │  • Fast packet processing in kernel             │   │
│  │  • L3/L4/L7 filtering                           │   │
│  │  • Load balancing                               │   │
│  └─────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────┘
```

**Key Features**:
- **eBPF-based**: High-performance packet processing
- **L2 Announcements**: LoadBalancer service support without external LB
- **ClusterMesh**: Multi-cluster networking
- **Network Policies**: Advanced security policies
- **Service Mesh**: Optional service mesh capabilities
- **Observability**: Deep network visibility

**ClusterMesh Architecture**:
```
┌──────────────────────┐         ┌──────────────────────┐
│    Cluster A         │         │    Cluster B         │
│                      │         │                      │
│  ┌────────────────┐  │         │  ┌────────────────┐  │
│  │ ClusterMesh    │  │         │  │ ClusterMesh    │  │
│  │ API Server     │◄─┼─────────┼─►│ API Server     │  │
│  └────────────────┘  │         │  └────────────────┘  │
│         ↕             │         │         ↕             │
│  ┌────────────────┐  │         │  ┌────────────────┐  │
│  │ Cilium Agents  │  │         │  │ Cilium Agents  │  │
│  └────────────────┘  │         │  └────────────────┘  │
│                      │         │                      │
│  Pod CIDR:           │         │  Pod CIDR:           │
│  10.1.0.0/16         │         │  10.2.0.0/16         │
└──────────────────────┘         └──────────────────────┘
```

---

## Network Architecture

### Network Topology

```
┌─────────────────────────────────────────────────────────┐
│                  Physical Network                       │
│                  192.168.1.0/24                         │
│                                                         │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐             │
│  │  PVE1    │  │  PVE2    │  │  PVE3    │             │
│  │ .201     │  │ .202     │  │ .203     │             │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘             │
│       │             │             │                     │
└───────┼─────────────┼─────────────┼─────────────────────┘
        │             │             │
┌───────┼─────────────┼─────────────┼─────────────────────┐
│       │             │             │                     │
│  ┌────▼─────┐  ┌───▼──────┐  ┌──▼───────┐             │
│  │ Master 1 │  │ Master 2 │  │ Master 3 │             │
│  │ .110     │  │ .111     │  │ .112     │             │
│  └──────────┘  └──────────┘  └──────────┘             │
│                                                         │
│  VIP: .230 (Kubernetes API)                            │
│                                                         │
│  ┌──────────┐  ┌──────────┐                            │
│  │ Worker 1 │  │ Worker 2 │                            │
│  │ .113     │  │ .114     │                            │
│  └──────────┘  └──────────┘                            │
│                                                         │
│  LoadBalancer IP Pool: .200-.207                       │
└─────────────────────────────────────────────────────────┘
        │
┌───────▼─────────────────────────────────────────────────┐
│              Pod Network (Overlay)                      │
│              10.x.0.0/16                                │
│                                                         │
│  ┌─────────┐  ┌─────────┐  ┌─────────┐                │
│  │  Pod 1  │  │  Pod 2  │  │  Pod N  │                │
│  └─────────┘  └─────────┘  └─────────┘                │
└─────────────────────────────────────────────────────────┘
        │
┌───────▼─────────────────────────────────────────────────┐
│            Service Network (Virtual)                    │
│            172.20.0.0/24                                │
│                                                         │
│  ┌─────────────┐  ┌─────────────┐                      │
│  │ Service 1   │  │ Service 2   │                      │
│  │ 172.20.0.10 │  │ 172.20.0.20 │                      │
│  └─────────────┘  └─────────────┘                      │
└─────────────────────────────────────────────────────────┘
```

### Network Segmentation

| Network | CIDR | Purpose | Managed By |
|---------|------|---------|------------|
| **Management** | 192.168.1.0/24 | Proxmox, VM management | Proxmox |
| **Pod Network** | 10.x.0.0/16 | Pod-to-pod communication | Cilium |
| **Service Network** | 172.20.0.0/24 | Kubernetes services | Kubernetes |
| **LoadBalancer Pool** | 192.168.1.200/29 | External service IPs | Cilium L2 |

### Traffic Flow

**Pod-to-Pod (Same Node)**:
```
Pod A → eBPF → Pod B
```

**Pod-to-Pod (Different Nodes)**:
```
Pod A → eBPF → VXLAN Tunnel → Node B → eBPF → Pod B
```

**Pod-to-Service**:
```
Pod → eBPF (load balance) → Service Endpoint (Pod)
```

**External-to-Service (LoadBalancer)**:
```
External Client → L2 Announcement → LoadBalancer IP → eBPF → Pod
```

---

## Storage Architecture

### Storage Layers

```
┌─────────────────────────────────────────────────────────┐
│              Application Storage                        │
│  (PersistentVolumes, PersistentVolumeClaims)            │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│           Storage Provisioner (CSI)                     │
│  (Proxmox CSI, Ceph CSI, etc.)                          │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│              Proxmox Storage                            │
│  (ZFS, Ceph, NFS, LVM)                                  │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│              Physical Storage                           │
│  (SSDs, HDDs, NVMe)                                     │
└─────────────────────────────────────────────────────────┘
```

### Storage Types

**1. VM Disks**:
- Stored on Proxmox shared storage
- Enables live migration
- Typically ZFS or Ceph

**2. Container Storage**:
- Ephemeral: Container overlay filesystem
- Persistent: PersistentVolumes via CSI

**3. etcd Storage**:
- Local disk on control plane nodes
- Critical for cluster state
- Should be on fast storage (SSD/NVMe)

### Storage Best Practices

- **Separate etcd storage**: Use dedicated disk for etcd
- **Fast storage for control plane**: SSD/NVMe recommended
- **Shared storage for VMs**: Enables HA and migration
- **Backup strategy**: Regular backups of etcd and PVs

---

## Security Architecture

### Defense in Depth

```
┌─────────────────────────────────────────────────────────┐
│  Layer 7: Application Security                         │
│  • Pod Security Standards                              │
│  • RBAC                                                 │
│  • Network Policies                                     │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│  Layer 6: Secrets Management                           │
│  • SOPS + Age encryption                               │
│  • Kubernetes Secrets                                   │
│  • Certificate rotation                                 │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│  Layer 5: Network Security                             │
│  • Cilium Network Policies                             │
│  • Encryption in transit (optional)                     │
│  • Firewall rules                                       │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│  Layer 4: OS Security                                  │
│  • Talos immutable OS                                  │
│  • No SSH access                                        │
│  • Minimal attack surface                              │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│  Layer 3: Virtualization Security                      │
│  • VM isolation                                         │
│  • Proxmox RBAC                                         │
│  • Secure boot (optional)                               │
└─────────────────────────────────────────────────────────┘
```

### Security Features

**1. Talos OS Security**:
- Immutable root filesystem
- No SSH access (API-only)
- Minimal packages (reduced attack surface)
- Automatic security updates
- Secure boot support

**2. Kubernetes Security**:
- RBAC enabled by default
- Pod Security Standards
- Network policies
- Certificate-based authentication
- Encrypted secrets (via SOPS)

**3. Network Security**:
- Cilium network policies
- Optional encryption in transit
- Firewall rules on Proxmox
- Isolated networks

**4. Secrets Management**:
- SOPS encryption at rest
- Age encryption keys
- Kubernetes secrets
- Automatic certificate rotation

---

## High Availability

### HA Components

**1. Control Plane HA**:
```
┌──────────────────────────────────────────────────────┐
│           Control Plane HA                           │
│                                                      │
│  ┌─────────┐    ┌─────────┐    ┌─────────┐         │
│  │ Master1 │    │ Master2 │    │ Master3 │         │
│  │ (PVE1)  │    │ (PVE2)  │    │ (PVE3)  │         │
│  └────┬────┘    └────┬────┘    └────┬────┘         │
│       │              │              │               │
│       └──────────────┴──────────────┘               │
│                      │                              │
│                  VIP (.230)                         │
│              (Shared IP Address)                    │
└──────────────────────────────────────────────────────┘
```

**Features**:
- 3 control plane nodes across different Proxmox hosts
- etcd cluster with quorum (n/2 + 1)
- VIP for API server access
- Automatic failover

**2. Worker Node HA**:
- Pods distributed across multiple workers
- Automatic pod rescheduling on node failure
- Anti-affinity rules for critical workloads

**3. Storage HA**:
- Shared storage for VM disks
- Replicated storage (Ceph) for data redundancy
- Regular backups

**4. Network HA**:
- Multiple network paths
- Cilium health checking
- Automatic route failover

### Failure Scenarios

| Failure | Impact | Recovery |
|---------|--------|----------|
| **Single worker node** | Pods rescheduled | Automatic (seconds) |
| **Single control plane** | No impact (2/3 quorum) | Automatic (immediate) |
| **Two control planes** | Cluster read-only | Manual intervention |
| **Single Proxmox host** | VMs migrate | Automatic (if HA enabled) |
| **Network partition** | Split-brain prevention | etcd quorum |
| **Storage failure** | Depends on redundancy | Varies |

---

## Scalability

### Horizontal Scaling

**Adding Worker Nodes**:
1. Update Tofu configuration
2. Provision new VMs
3. Apply Talos configuration
4. Nodes automatically join cluster

**Adding Control Plane Nodes**:
1. Maintain odd number (3, 5, 7)
2. Update VIP configuration
3. Bootstrap new etcd member
4. Update load balancing

### Vertical Scaling

**Increasing Node Resources**:
1. Update VM configuration in Tofu
2. Apply changes
3. Restart nodes (rolling restart for workers)

### Cluster Limits

Based on Kubernetes and etcd limits:

| Resource | Recommended Limit | Maximum Tested |
|----------|------------------|----------------|
| **Nodes** | 100 | 5000 |
| **Pods** | 10,000 | 150,000 |
| **Pods per Node** | 110 | 250 |
| **Services** | 5,000 | 10,000 |

### Multi-Cluster Architecture

For larger deployments:
```
┌──────────────┐  ┌──────────────┐  ┌──────────────┐
│  Cluster A   │  │  Cluster B   │  │  Cluster C   │
│  (Region 1)  │  │  (Region 2)  │  │  (Region 3)  │
└──────┬───────┘  └──────┬───────┘  └──────┬───────┘
       │                 │                 │
       └─────────────────┴─────────────────┘
                  ClusterMesh
```

---

## Design Decisions

### Why Talos OS?

**Pros**:
- ✅ Immutable and secure by design
- ✅ API-driven (no SSH needed)
- ✅ Minimal attack surface
- ✅ Designed specifically for Kubernetes
- ✅ Atomic updates

**Cons**:
- ❌ Learning curve for traditional sysadmins
- ❌ Limited debugging tools
- ❌ Requires different operational mindset

### Why Cilium?

**Pros**:
- ✅ eBPF-based (high performance)
- ✅ L2 announcements (no external LB needed)
- ✅ ClusterMesh for multi-cluster
- ✅ Advanced network policies
- ✅ Excellent observability

**Cons**:
- ❌ More complex than simple CNIs
- ❌ Requires newer kernels
- ❌ Higher resource usage

### Why OpenTofu over Terraform?

**Pros**:
- ✅ Open source (no licensing concerns)
- ✅ Compatible with Terraform
- ✅ Community-driven
- ✅ No vendor lock-in

**Cons**:
- ❌ Smaller ecosystem (for now)
- ❌ Less mature

### Why Proxmox?

**Pros**:
- ✅ Open source
- ✅ Full-featured virtualization
- ✅ Built-in HA
- ✅ Web UI and API
- ✅ Cost-effective

**Cons**:
- ❌ Less enterprise support than VMware
- ❌ Smaller ecosystem

---

## Performance Considerations

### Optimization Areas

**1. Network Performance**:
- eBPF provides near-native performance
- VXLAN overhead minimal with modern CPUs
- Consider SR-IOV for maximum performance

**2. Storage Performance**:
- Use SSDs for etcd
- ZFS with appropriate ARC size
- Consider NVMe for high-IOPS workloads

**3. CPU Performance**:
- Enable CPU pinning for critical workloads
- Use CPU governor (performance mode)
- Disable unnecessary mitigations (if acceptable)

**4. Memory Performance**:
- Adequate memory for ZFS ARC
- Memory overcommit carefully
- Use huge pages for databases

### Benchmarking

Recommended tools:
- **Network**: `iperf3`, Cilium connectivity test
- **Storage**: `fio`, `dd`
- **Kubernetes**: `kube-bench`, `sonobuoy`
- **Application**: Load testing tools specific to workload

---

## Monitoring and Observability

### Recommended Stack

```
┌─────────────────────────────────────────────────────────┐
│                  Observability Stack                    │
│                                                         │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐    │
│  │ Prometheus  │  │   Grafana   │  │    Loki     │    │
│  │  (Metrics)  │  │(Dashboards) │  │   (Logs)    │    │
│  └─────────────┘  └─────────────┘  └─────────────┘    │
│                                                         │
│  ┌─────────────┐  ┌─────────────┐                      │
│  │   Hubble    │  │ AlertManager│                      │
│  │ (Network)   │  │  (Alerts)   │                      │
│  └─────────────┘  └─────────────┘                      │
└─────────────────────────────────────────────────────────┘
```

### Key Metrics

- **Cluster**: Node status, resource usage
- **Pods**: CPU, memory, restarts
- **Network**: Throughput, latency, errors
- **Storage**: IOPS, latency, capacity
- **etcd**: Latency, leader changes

---

## Future Enhancements

Potential improvements:

1. **GitOps Integration**: ArgoCD or Flux
2. **Service Mesh**: Istio or Linkerd
3. **Storage**: Rook/Ceph for persistent storage
4. **Monitoring**: Full observability stack
5. **CI/CD**: Automated testing and deployment
6. **Disaster Recovery**: Multi-region setup
7. **Security**: OPA/Gatekeeper for policy enforcement
8. **Cost Optimization**: Resource quotas and limits

---

## References

- [Talos Documentation](https://www.talos.dev/docs/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Cilium Documentation](https://docs.cilium.io/)
- [Proxmox Documentation](https://pve.proxmox.com/wiki/)
- [OpenTofu Documentation](https://opentofu.org/docs/)
