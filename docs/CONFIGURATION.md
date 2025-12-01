# Configuration Reference

This document provides detailed configuration reference for all components of the Talos OS on Proxmox infrastructure.

---

## Table of Contents

- [Packer Configuration](#packer-configuration)
- [OpenTofu Configuration](#opentofu-configuration)
- [Talos Configuration](#talos-configuration)
- [Cilium Configuration](#cilium-configuration)
- [Proxmox Ansible Configuration](#proxmox-ansible-configuration)
- [Environment Variables](#environment-variables)

---

## Packer Configuration

### Variables (`packer/variables.pkr.hcl`)

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `proxmox_api_url` | string | - | Proxmox API URL (e.g., `https://192.168.1.201:8006/api2/json`) |
| `proxmox_api_token_id` | string | - | API token ID (format: `user@realm!tokenid`) |
| `proxmox_api_token_secret` | string | - | API token secret |
| `proxmox_node` | string | `"pve1"` | Target Proxmox node |
| `proxmox_storage` | string | `"local-zfs"` | Storage pool for template |
| `vm_id` | number | `9700` | Template VM ID |
| `vm_name` | string | `"talos-template"` | Template name |
| `disk_size` | string | `"4G"` | Template disk size |
| `memory` | number | `2048` | Template memory (MB) |
| `cores` | number | `2` | Template CPU cores |
| `schematic_id` | string | - | Talos Image Factory schematic ID |
| `talos_version` | string | `"v1.10.3"` | Talos OS version |

### Example Configuration (`packer/vars/local.pkrvars.hcl`)

```hcl
proxmox_api_url          = "https://192.168.1.201:8006/api2/json"
proxmox_api_token_id     = "terraform@pam!provider"
proxmox_api_token_secret = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"

proxmox_node    = "pve1"
proxmox_storage = "local-zfs"

vm_id       = 9700
vm_name     = "talos-v1.10.3-template"
disk_size   = "4G"
memory      = 2048
cores       = 2

schematic_id  = "your-schematic-id-here"
talos_version = "v1.10.3"
```

### Schematic Configuration (`packer/schematic.yaml`)

```yaml
customization:
  systemExtensions:
    officialExtensions:
      # Intel CPU microcode updates
      - siderolabs/intel-ucode
      # AMD CPU microcode updates
      # - siderolabs/amd-ucode
      # Intel GPU drivers
      - siderolabs/i915-ucode
      # QEMU guest agent for Proxmox integration
      - siderolabs/qemu-guest-agent
      # Additional extensions as needed
      # - siderolabs/iscsi-tools
      # - siderolabs/util-linux-tools
```

---

## OpenTofu Configuration

### Main Variables (`tofu/variables.tf`)

#### Proxmox Connection

```hcl
variable "proxmox_api_url" {
  description = "Proxmox API URL"
  type        = string
}

variable "proxmox_api_token_id" {
  description = "Proxmox API token ID"
  type        = string
  sensitive   = true
}

variable "proxmox_api_token_secret" {
  description = "Proxmox API token secret"
  type        = string
  sensitive   = true
}
```

#### Cluster Configuration

```hcl
variable "clusters" {
  description = "Map of cluster configurations"
  type = map(object({
    masters = map(object({
      vm_id                = number
      node_name            = string
      node_cpu_cores       = string
      node_memory          = number
      node_ipconfig        = string
      node_disk            = string
      additional_node_disk = optional(string)
      patches              = optional(list(string))
      mac_address          = string
    }))
    workers = map(object({
      vm_id                = number
      node_name            = string
      node_cpu_cores       = string
      node_memory          = number
      node_ipconfig        = string
      node_disk            = string
      additional_node_disk = optional(string)
      patches              = optional(list(string))
      mac_address          = string
    }))
    target_nodes = list(string)
    vip          = string
    pod_net      = string
    svc_net      = string
  }))
}
```

### Example Cluster Configuration (`tofu/clusters.auto.tfvars`)

```hcl
clusters = {
  # Cluster A - Production
  cla = {
    target_nodes = ["pve1", "pve2", "pve3"]
    vip          = "192.168.1.230"
    pod_net      = "10.1.0.0/16"
    svc_net      = "172.20.0.0/24"
    
    masters = {
      cp01 = {
        vm_id          = 8001
        node_name      = "pve1"
        node_cpu_cores = "4"
        node_memory    = 8192
        node_ipconfig  = "ip=192.168.1.110/24,gw=192.168.1.254"
        node_disk      = "32G"
        mac_address    = "BC:24:11:2E:C8:01"
      }
      cp02 = {
        vm_id          = 8002
        node_name      = "pve2"
        node_cpu_cores = "4"
        node_memory    = 8192
        node_ipconfig  = "ip=192.168.1.111/24,gw=192.168.1.254"
        node_disk      = "32G"
        mac_address    = "BC:24:11:2E:C8:02"
      }
      cp03 = {
        vm_id          = 8003
        node_name      = "pve3"
        node_cpu_cores = "4"
        node_memory    = 8192
        node_ipconfig  = "ip=192.168.1.112/24,gw=192.168.1.254"
        node_disk      = "32G"
        mac_address    = "BC:24:11:2E:C8:03"
      }
    }
    
    workers = {
      wk01 = {
        vm_id          = 8011
        node_name      = "pve1"
        node_cpu_cores = "8"
        node_memory    = 16384
        node_ipconfig  = "ip=192.168.1.113/24,gw=192.168.1.254"
        node_disk      = "64G"
        additional_node_disk = "100G"  # Optional additional disk
        mac_address    = "BC:24:11:2E:C8:11"
      }
      wk02 = {
        vm_id          = 8012
        node_name      = "pve2"
        node_cpu_cores = "8"
        node_memory    = 16384
        node_ipconfig  = "ip=192.168.1.114/24,gw=192.168.1.254"
        node_disk      = "64G"
        additional_node_disk = "100G"
        mac_address    = "BC:24:11:2E:C8:12"
      }
    }
  }
  
  # Cluster B - Development
  clb = {
    target_nodes = ["pve1", "pve2", "pve3"]
    vip          = "192.168.1.240"
    pod_net      = "10.2.0.0/16"
    svc_net      = "172.21.0.0/24"
    
    masters = {
      cp01 = {
        vm_id          = 8101
        node_name      = "pve1"
        node_cpu_cores = "2"
        node_memory    = 4096
        node_ipconfig  = "ip=192.168.1.120/24,gw=192.168.1.254"
        node_disk      = "32G"
        mac_address    = "BC:24:11:2E:D8:01"
      }
      # ... additional masters
    }
    
    workers = {
      wk01 = {
        vm_id          = 8111
        node_name      = "pve1"
        node_cpu_cores = "4"
        node_memory    = 8192
        node_ipconfig  = "ip=192.168.1.123/24,gw=192.168.1.254"
        node_disk      = "64G"
        mac_address    = "BC:24:11:2E:D8:11"
      }
      # ... additional workers
    }
  }
}
```

### Talos Configuration (`tofu/talos.auto.tfvars`)

```hcl
talos = {
  factory_url = "https://factory.talos.dev"
  schematic   = "your-schematic-id"
  version     = "v1.10.3"
  storage     = "local-zfs"
  disk_size   = "4G"
  platform    = "nocloud"
  arch        = "amd64"
}

talos_version      = "v1.10.3"
kubernetes_version = "v1.33.1"
```

### Credentials (`tofu/credentials.auto.tfvars`)

```hcl
proxmox_api_url          = "https://192.168.1.201:8006/api2/json"
proxmox_api_token_id     = "terraform@pam!provider"
proxmox_api_token_secret = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
shared_storage_id        = "shared-storage"
```

---

## Talos Configuration

### Talhelper Configuration (`talos/talconfig-*.yaml`)

#### Basic Structure

```yaml
# Talos and Kubernetes versions
talosVersion: v1.10.3
kubernetesVersion: v1.33.1

# Cluster identification
clusterName: cla
endpoint: https://192.168.1.230:6443

# Network configuration
clusterPodNets:
  - 10.1.0.0/16
clusterSvcNets:
  - 172.20.0.0/24

# Certificate SANs
additionalApiServerCertSans:
  - 192.168.1.230  # VIP
  - 192.168.1.110  # CP1
  - 192.168.1.111  # CP2
  - 192.168.1.112  # CP3
  - 127.0.0.1

additionalMachineCertSans:
  - 192.168.1.230
  - 192.168.1.110
  - 192.168.1.111
  - 192.168.1.112
  - 127.0.0.1
```

#### Global Patches

```yaml
patches:
  # Machine-level configuration
  - |-
    machine:
      network:
        nameservers:
          - 1.1.1.1
          - 8.8.8.8
      time:
        disabled: false
        servers:
          - time.cloudflare.com
          - time.google.com
      kubelet:
        extraArgs:
          authorization-mode: AlwaysAllow
          rotate-server-certificates: "true"
      
      # Sysctls for performance
      sysctls:
        net.core.somaxconn: "65535"
        net.ipv4.ip_forward: "1"
```

#### Cluster Configuration

```yaml
cluster:
  # Disable discovery service
  discovery:
    enabled: false
    registries:
      service:
        disabled: true
  
  # Proxy configuration
  proxy:
    disabled: true  # Using Cilium instead
  
  # Network configuration
  network:
    cni:
      name: none  # Install Cilium manually
    
    # DNS configuration
    dnsDomain: cluster.local
```

#### Control Plane Patches

```yaml
controlPlane:
  patches:
    - |-
      cluster:
        # Controller Manager configuration
        controllerManager:
          extraArgs:
            bind-address: 0.0.0.0
        
        # Scheduler configuration
        scheduler:
          extraArgs:
            bind-address: 0.0.0.0
        
        # API Server configuration
        apiServer:
          extraArgs:
            # Audit logging
            audit-log-path: /var/log/audit.log
            audit-log-maxage: "30"
            audit-log-maxbackup: "10"
            audit-log-maxsize: "100"
```

#### Node Definitions

```yaml
nodes:
  # Control Plane Node
  - hostname: cla-cp01
    controlPlane: true
    installDisk: /dev/sda
    ipAddress: 192.168.1.110
    gateway: 192.168.1.254
    networkInterfaces:
      - interface: ens18
        dhcp: false
        addresses:
          - 192.168.1.110/24
        routes:
          - network: 0.0.0.0/0
            gateway: 192.168.1.254
        vip:
          ip: 192.168.1.230
    
    # Node-specific patches
    patches:
      - |-
        machine:
          nodeLabels:
            node-role.kubernetes.io/control-plane: ""
          nodeTaints:
            - key: node-role.kubernetes.io/control-plane
              effect: NoSchedule
  
  # Worker Node
  - hostname: cla-wk01
    controlPlane: false
    installDisk: /dev/sda
    ipAddress: 192.168.1.113
    gateway: 192.168.1.254
    networkInterfaces:
      - interface: ens18
        dhcp: false
        addresses:
          - 192.168.1.113/24
    
    # Additional disks
    disks:
      - device: /dev/sdb
        partitions:
          - mountpoint: /var/lib/longhorn
    
    patches:
      - |-
        machine:
          nodeLabels:
            node-role.kubernetes.io/worker: ""
            storage: "true"
```

### SOPS Configuration (`talos/.sops.yaml`)

```yaml
creation_rules:
  - path_regex: talsecret\.sops\..*\.yaml$
    age: age1xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

---

## Cilium Configuration

### Installation Options

```bash
# Basic installation
cilium install --version 1.14.5

# With L2 announcements
cilium install \
  --version 1.14.5 \
  --set ipam.mode=kubernetes \
  --set kubeProxyReplacement=true \
  --set l2announcements.enabled=true

# With encryption
cilium install \
  --version 1.14.5 \
  --set encryption.enabled=true \
  --set encryption.type=wireguard

# With Hubble (observability)
cilium install \
  --version 1.14.5 \
  --set hubble.enabled=true \
  --set hubble.relay.enabled=true \
  --set hubble.ui.enabled=true
```

### L2 Announcement Policy (`talos/cilium-l2-policy.yaml`)

```yaml
apiVersion: cilium.io/v2alpha1
kind: CiliumL2AnnouncementPolicy
metadata:
  name: default-policy
spec:
  # Announce on all interfaces matching pattern
  interfaces:
    - ^ens.*
    - ^eth.*
  
  # Announce external IPs
  externalIPs: true
  
  # Announce LoadBalancer IPs
  loadBalancerIPs: true
  
  # Node selector (optional)
  nodeSelector:
    matchLabels:
      node-role.kubernetes.io/worker: ""
```

### LoadBalancer IP Pool (`talos/cilium-ippool.yaml`)

```yaml
apiVersion: cilium.io/v2alpha1
kind: CiliumLoadBalancerIPPool
metadata:
  name: default-pool
spec:
  cidrs:
    - cidr: 192.168.1.200/29
  
  # Disabled by default, enable per-service
  disabled: false
  
  # Service selector (optional)
  serviceSelector:
    matchLabels:
      io.cilium/lb-ipam: "default-pool"
```

### ClusterMesh Configuration

```yaml
# Enable ClusterMesh
apiVersion: cilium.io/v2alpha1
kind: CiliumClusterwideNetworkPolicy
metadata:
  name: clustermesh-policy
spec:
  endpointSelector: {}
  ingress:
    - fromEndpoints:
        - matchLabels:
            io.cilium.k8s.policy.cluster: cluster-a
            io.cilium.k8s.policy.cluster: cluster-b
```

---

## Proxmox Ansible Configuration

### Host Variables (`proxmox-ansible/host_vars/pve1.yml`)

```yaml
# Connection settings
initial_user: root
initial_password: "YourSecurePassword"
system_user: admin

# Network configuration
network_interfaces:
  - name: vmbr0
    type: bridge
    address: 192.168.1.201
    netmask: 255.255.255.0
    gateway: 192.168.1.254
    bridge_ports: eno1

dns_servers:
  - 1.1.1.1
  - 8.8.8.8

# Storage configuration
zfs_arc_max: 16G  # Maximum ZFS ARC size

# Security settings
ssh_port: 22
ssh_password_auth: false
ssh_root_login: false

# System settings
timezone: Europe/Rome
locale: en_US.UTF-8

# Proxmox settings
pve_enterprise_repo: false
pve_no_subscription_repo: true

# Performance settings
cpu_governor: performance
disable_ipv6: true

# Services to disable
disable_services:
  - pve-ha-lrm
  - pve-ha-crm
  - corosync  # If not using clustering
```

### Inventory (`proxmox-ansible/inventory.yml`)

```yaml
all:
  hosts:
    pve1:
      ansible_host: 192.168.1.201
      ansible_user: root
    pve2:
      ansible_host: 192.168.1.202
      ansible_user: root
    pve3:
      ansible_host: 192.168.1.203
      ansible_user: root
  
  vars:
    ansible_python_interpreter: /usr/bin/python3
```

---

## Environment Variables

### Required Variables

```bash
# Proxmox API
export PROXMOX_API_URL="https://192.168.1.201:8006/api2/json"
export PROXMOX_API_TOKEN_ID="terraform@pam!provider"
export PROXMOX_API_TOKEN_SECRET="xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"

# Talos
export TALOSCONFIG="./talos/clusterconfig/cla/talosconfig"

# Kubernetes
export KUBECONFIG="~/.kube/config"

# SOPS/Age
export SOPS_AGE_KEY_FILE="./talos/age.key"
```

### Optional Variables

```bash
# Packer
export PACKER_LOG=1
export PACKER_LOG_PATH="./packer.log"

# Terraform/Tofu
export TF_LOG=INFO
export TF_LOG_PATH="./tofu.log"

# Ansible
export ANSIBLE_HOST_KEY_CHECKING=False
export ANSIBLE_STDOUT_CALLBACK=yaml
```

---

## Configuration Best Practices

### 1. Security

- ✅ Use strong, unique passwords
- ✅ Enable SSH key authentication
- ✅ Disable root SSH login
- ✅ Encrypt secrets with SOPS
- ✅ Use network policies
- ✅ Regular security updates

### 2. High Availability

- ✅ Odd number of control plane nodes (3, 5, 7)
- ✅ Distribute nodes across Proxmox hosts
- ✅ Use shared storage
- ✅ Configure VIP for API server
- ✅ Regular backups

### 3. Performance

- ✅ Use SSDs for etcd
- ✅ Adequate memory for ZFS ARC
- ✅ CPU pinning for critical workloads
- ✅ Tune network MTU
- ✅ Monitor resource usage

### 4. Networking

- ✅ Non-overlapping pod CIDRs
- ✅ Separate networks for management and data
- ✅ Configure proper DNS
- ✅ Use network policies
- ✅ Monitor network performance

### 5. Storage

- ✅ Separate storage for etcd
- ✅ Use shared storage for VMs
- ✅ Regular backups
- ✅ Monitor disk usage
- ✅ Plan for growth

---

## Validation

### Configuration Validation

```bash
# Validate Packer configuration
cd packer
packer validate -var-file="vars/local.pkrvars.hcl" main.pkr.hcl

# Validate Tofu configuration
cd tofu
tofu validate

# Validate Talos configuration
cd talos
talhelper validate --config talconfig-cla.yaml

# Validate Kubernetes manifests
kubectl apply --dry-run=client -f manifest.yaml
```

### Testing

```bash
# Test Proxmox API connectivity
curl -k https://192.168.1.201:8006/api2/json/version

# Test Talos connectivity
talosctl version --nodes 192.168.1.110

# Test Kubernetes connectivity
kubectl cluster-info

# Test Cilium
cilium status
cilium connectivity test
```

---

## Common Configuration Patterns

### Multi-Cluster Setup

```hcl
# tofu/clusters.auto.tfvars
clusters = {
  prod = {
    vip     = "192.168.1.230"
    pod_net = "10.1.0.0/16"
    svc_net = "172.20.0.0/24"
    # ... nodes
  }
  
  staging = {
    vip     = "192.168.1.240"
    pod_net = "10.2.0.0/16"
    svc_net = "172.21.0.0/24"
    # ... nodes
  }
  
  dev = {
    vip     = "192.168.1.250"
    pod_net = "10.3.0.0/16"
    svc_net = "172.22.0.0/24"
    # ... nodes
  }
}
```

### Resource Tiers

```hcl
# Small (dev/test)
node_cpu_cores = "2"
node_memory    = 4096
node_disk      = "32G"

# Medium (staging)
node_cpu_cores = "4"
node_memory    = 8192
node_disk      = "64G"

# Large (production)
node_cpu_cores = "8"
node_memory    = 16384
node_disk      = "128G"
```

---

## References

- [Talos Configuration Reference](https://www.talos.dev/v1.10/reference/configuration/)
- [Cilium Configuration Reference](https://docs.cilium.io/en/stable/configuration/)
- [Proxmox API Documentation](https://pve.proxmox.com/pve-docs/api-viewer/)
- [Terraform Proxmox Provider](https://registry.terraform.io/providers/Telmate/proxmox/latest/docs)
