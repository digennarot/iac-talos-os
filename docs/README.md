# Infrastructure-as-Code for Talos OS on Proxmox VE

## 📋 Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Project Structure](#project-structure)
- [Components](#components)
- [Workflows](#workflows)
- [Configuration](#configuration)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)

---

## Overview

This repository provides a complete Infrastructure-as-Code (IaC) solution for deploying and managing **Talos OS-based Kubernetes clusters** on **Proxmox VE** infrastructure. It combines multiple automation tools to create a production-ready, secure, and highly available Kubernetes environment.

### Key Features

- 🔒 **Secure by Default**: Talos OS is an immutable, minimal Linux distribution designed specifically for Kubernetes
- 🚀 **Fully Automated**: End-to-end automation from Proxmox setup to Kubernetes cluster deployment
- 🔄 **GitOps Ready**: Infrastructure defined as code with version control
- 🌐 **Advanced Networking**: Cilium CNI with ClusterMesh support for multi-cluster networking
- 📦 **Modular Design**: Separate components for different stages of infrastructure deployment
- 🔐 **Secrets Management**: SOPS integration for encrypted secrets

### Technology Stack

- **Proxmox VE**: Virtualization platform (versions 7 & 8 supported)
- **Talos OS**: Immutable Kubernetes operating system
- **OpenTofu/Terraform**: Infrastructure provisioning
- **Packer**: VM template creation
- **Ansible**: Proxmox host configuration and hardening
- **Cilium**: Advanced Kubernetes networking and service mesh
- **Talhelper**: Talos configuration management
- **SOPS + Age**: Secrets encryption

---

## Architecture

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Proxmox VE Cluster                       │
│  ┌──────────┐    ┌──────────┐    ┌──────────┐             │
│  │  PVE1    │    │  PVE2    │    │  PVE3    │             │
│  └──────────┘    └──────────┘    └──────────┘             │
│         │               │               │                   │
│         └───────────────┴───────────────┘                   │
│                    Shared Storage                           │
└─────────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────┐
│              Talos OS Kubernetes Clusters                   │
│  ┌─────────────────┐  ┌─────────────────┐                  │
│  │   Cluster A     │  │   Cluster B     │                  │
│  │  ┌───┬───┬───┐  │  │  ┌───┬───┬───┐  │                  │
│  │  │CP1│CP2│CP3│  │  │  │CP1│CP2│CP3│  │                  │
│  │  └───┴───┴───┘  │  │  └───┴───┴───┘  │                  │
│  │  ┌────┬────┐    │  │  ┌────┬────┐    │                  │
│  │  │WK1 │WK2 │    │  │  │WK1 │WK2 │    │                  │
│  │  └────┴────┘    │  │  └────┴────┘    │                  │
│  └─────────────────┘  └─────────────────┘                  │
│           │                     │                           │
│           └──────Cilium─────────┘                           │
│                ClusterMesh                                  │
└─────────────────────────────────────────────────────────────┘
```

### Deployment Flow

```
1. Proxmox Setup (Ansible)
   ↓
2. Template Creation (Packer)
   ↓
3. VM Provisioning (OpenTofu)
   ↓
4. Talos Configuration (Talhelper)
   ↓
5. Kubernetes Deployment (Talosctl)
   ↓
6. Network Configuration (Cilium)
```

---

## Prerequisites

### Hardware Requirements

- **Proxmox VE Cluster**: 3+ nodes recommended for HA
- **CPU**: x86_64 with virtualization support (Intel VT-x or AMD-V)
- **Memory**: Minimum 32GB per Proxmox node (64GB+ recommended)
- **Storage**: Shared storage (ZFS, Ceph, NFS) for VM migration
- **Network**: Dedicated network for cluster communication

### Software Requirements

- **Proxmox VE**: Version 7.x or 8.x
- **Debian Workstation**: For running automation tools
- **Git**: For repository management
- **SSH Access**: Root access to Proxmox nodes

### Network Requirements

- **Management Network**: For Proxmox and VM management
- **Cluster Network**: For Kubernetes control plane communication
- **Pod Network**: CIDR range for pod networking (e.g., 10.x.0.0/16)
- **Service Network**: CIDR range for Kubernetes services (e.g., 172.20.0.0/24)
- **VIP**: Virtual IP for Kubernetes API server high availability

---

## Quick Start

### 1. Prepare Your Workstation

Clone this repository and install required tools:

```bash
git clone https://github.com/digennarot/iac-talos-os.git
cd iac-talos-os

# Install all required tools (see Prerequisites section in main README.md)
# Packer, OpenTofu, Talosctl, Talhelper, kubectl, SOPS, Age, Cilium CLI
```

### 2. Configure Proxmox Hosts (Optional)

If you need to configure and harden your Proxmox hosts:

```bash
cd proxmox-ansible

# Copy and customize host variables
cp host_vars/example.yml host_vars/your-host.yml

# Update inventory
vim inventory.yml

# Run the playbook
ansible-playbook proxmox.yml
```

### 3. Create Talos OS Templates

Generate a Talos schematic and build VM templates:

```bash
cd packer

# Create your schematic.yaml with required extensions
# Generate schematic ID
export SCHEMATIC_ID=$(curl -sS \
  -X POST https://factory.talos.dev/schematics \
  -H "Content-Type: application/yaml" \
  --data-binary @schematic.yaml \
  | jq -r .id)

# Create vars file
cp vars/example.pkrvars.hcl vars/local.pkrvars.hcl
# Edit vars/local.pkrvars.hcl with your Proxmox details

# Build templates
packer init main.pkr.hcl
packer build -var-file="vars/local.pkrvars.hcl" main.pkr.hcl
```

### 4. Provision VMs with OpenTofu

```bash
cd tofu

# Create credentials file
cat > credentials.auto.tfvars <<EOF
proxmox_api_url          = "https://your-proxmox:8006/api2/json"
proxmox_api_token_id     = "terraform@pam!provider"
proxmox_api_token_secret = "your-secret-here"
EOF

# Review and customize cluster configuration
vim clusters.auto.tfvars
vim talos.auto.tfvars

# Initialize and apply
tofu init
tofu plan
tofu apply
```

### 5. Deploy Kubernetes Clusters

```bash
cd talos

# Generate Age key for secrets encryption
age-keygen -o age.key

# Configure SOPS
cat > .sops.yaml <<EOF
creation_rules:
  - path_regex: talsecret\.sops\..*\.yaml$
    age: <your-age-public-key>
EOF

# Customize cluster configuration
vim talconfig-a.yaml

# Generate Talos configurations
talhelper genconfig

# Apply configurations and bootstrap cluster
talosctl apply-config --insecure \
  --nodes 192.168.1.110 \
  --file clusterconfig/cla/cla-cp01.yaml

# Bootstrap Kubernetes
talosctl bootstrap --nodes 192.168.1.110 \
  --endpoints 192.168.1.110 \
  --talosconfig ./clusterconfig/cla/talosconfig

# Get kubeconfig
talosctl kubeconfig --nodes 192.168.1.110
```

### 6. Install Cilium

```bash
# Install Cilium CNI
cilium install --version 1.14.5

# Verify installation
cilium status
kubectl get pods -n kube-system
```

---

## Project Structure

```
iac-talos-os/
├── docs/                          # Documentation
│   ├── [Workflows](./WORKFLOWS.md) - Step-by-step deployment and operational procedures
│   ├── [Architecture](./ARCHITECTURE.md) - Detailed architecture and design decisions
│   ├── [Configuration](./CONFIGURATION.md) - Complete configuration reference
│   ├── [Troubleshooting](./TROUBLESHOOTING.md) - Common issues and solutions
│   ├── [Quick Reference](./QUICK_REFERENCE.md) - Quick commands and daily operations
│   └── [Contributing](./CONTRIBUTING.md) - How to contribute to this project
│
├── packer/                        # Talos OS template creation
│   ├── main.pkr.hcl              # Packer template definition
│   ├── variables.pkr.hcl         # Variable definitions
│   ├── vars/                     # Variable files
│   └── README.md                 # Packer-specific documentation
│
├── proxmox-ansible/              # Proxmox host configuration
│   ├── proxmox.yml               # Main playbook
│   ├── cluster.yml               # Cluster-specific playbook
│   ├── roles/                    # Ansible roles
│   ├── inventory.yml             # Inventory file
│   └── README.md                 # Ansible-specific documentation
│
├── proxmox-autoinstall/          # Automated Proxmox installation
│   ├── answer*.toml              # Auto-install answers
│   ├── bootstrap.sh              # Post-install script
│   └── auto-installer-mode.toml  # Installer configuration
│
├── tofu/                         # Infrastructure provisioning
│   ├── main.tf                   # Main Terraform configuration
│   ├── variables.tf              # Variable definitions
│   ├── clusters.auto.tfvars      # Cluster configurations
│   ├── talos.auto.tfvars         # Talos-specific variables
│   ├── modules/                  # Terraform modules
│   │   ├── compute/              # VM provisioning module
│   │   └── talconfig/            # Talos config generation
│   └── examples/                 # Example configurations
│
├── talos/                        # Talos and Kubernetes configs
│   ├── talconfig-*.yaml          # Talhelper configurations
│   ├── talsecret.sops.*.yaml     # Encrypted secrets
│   ├── clusterconfig/            # Generated Talos configs
│   ├── *.sh                      # Helper scripts
│   └── cilium-*.yaml             # Cilium configurations
│
├── star-wars-demo/               # Demo application
│
├── .gitignore                    # Git ignore rules
└── README.md                     # Main project README
```

---

## Components

### 1. Proxmox Ansible (`proxmox-ansible/`)

Automates Proxmox VE host configuration, hardening, and optimization.

**Key Features:**
- System updates and security patches
- Network configuration
- Storage optimization (ZFS tuning)
- User management and SSH hardening
- Service configuration
- Performance tuning

**Documentation:** [proxmox-ansible/README.md](../proxmox-ansible/README.md)

### 2. Packer Templates (`packer/`)

Creates Talos OS VM templates using the Talos Image Factory.

**Key Features:**
- Custom Talos images with system extensions
- Multi-node template deployment
- Automated template creation
- Version management

**Documentation:** [packer/README.md](../packer/README.md)

### 3. OpenTofu/Terraform (`tofu/`)

Provisions VMs and infrastructure on Proxmox.

**Key Features:**
- Multi-cluster support
- Modular architecture
- State management
- Resource lifecycle management

**Key Files:**
- `main.tf`: Main infrastructure definition
- `variables.tf`: Variable declarations
- `clusters.auto.tfvars`: Cluster-specific configuration
- `modules/compute/`: VM provisioning module

### 4. Talos Configuration (`talos/`)

Manages Talos OS and Kubernetes cluster configuration.

**Key Features:**
- Talhelper-based configuration management
- SOPS-encrypted secrets
- Multi-cluster support
- VIP configuration for HA

**Key Files:**
- `talconfig-*.yaml`: Cluster definitions
- `talsecret.sops.*.yaml`: Encrypted secrets
- `clusterconfig/`: Generated configurations

### 5. Cilium Networking (`talos/`)

Advanced Kubernetes networking with ClusterMesh support.

**Key Features:**
- L2 load balancing
- Multi-cluster networking
- Network policies
- Service mesh capabilities

**Key Files:**
- `cilium-clustermesh.yaml`: ClusterMesh configuration
- `clustermesh-pool-*.yaml`: IP pool definitions

---

## Workflows

### Complete Deployment Workflow

See [WORKFLOWS.md](./WORKFLOWS.md) for detailed step-by-step instructions.

### Common Operations

#### Adding a New Cluster

1. Update `tofu/clusters.auto.tfvars` with new cluster definition
2. Create `talos/talconfig-<name>.yaml` configuration
3. Run `tofu apply` to provision VMs
4. Run `talhelper genconfig` to generate Talos configs
5. Apply configurations with `talosctl`
6. Bootstrap the cluster

#### Scaling a Cluster

1. Update cluster configuration in `clusters.auto.tfvars`
2. Run `tofu apply`
3. Generate new node configurations
4. Apply to new nodes

#### Upgrading Talos OS

1. Update `talos_version` in configuration
2. Generate new configurations
3. Apply upgrades node by node
4. Verify cluster health

---

## Configuration

### Environment Variables

```bash
# Proxmox API
export PROXMOX_API_URL="https://your-proxmox:8006/api2/json"
export PROXMOX_API_TOKEN_ID="terraform@pam!provider"
export PROXMOX_API_TOKEN_SECRET="your-secret"

# Talos
export TALOSCONFIG="./talos/clusterconfig/cla/talosconfig"

# Kubernetes
export KUBECONFIG="~/.kube/config"
```

### Secrets Management

This project uses **SOPS** with **Age** for secrets encryption:

```bash
# Generate Age key
age-keygen -o age.key

# Encrypt a file
sops -e -i talsecret.yaml

# Decrypt a file
sops -d talsecret.sops.yaml

# Edit encrypted file
sops talsecret.sops.yaml
```

### Network Configuration

Default network ranges (customize in `talconfig-*.yaml`):

- **Pod Network**: `10.x.0.0/16`
- **Service Network**: `172.20.0.0/24`
- **Management Network**: `192.168.1.0/24`

---

## Troubleshooting

See [TROUBLESHOOTING.md](./TROUBLESHOOTING.md) for detailed troubleshooting guides.

### Quick Checks

```bash
# Check Proxmox API connectivity
curl -k https://your-proxmox:8006/api2/json/version

# Check Talos node status
talosctl health --nodes <node-ip>

# Check Kubernetes cluster
kubectl get nodes
kubectl get pods -A

# Check Cilium status
cilium status
cilium connectivity test
```

---

## Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

---

## License

This project is provided as-is for educational and production use.

---

## Support

For issues and questions:
- Open an issue on GitHub
- Check existing documentation
- Review Talos OS documentation: https://www.talos.dev/
- Review Cilium documentation: https://docs.cilium.io/

---

## Acknowledgments

- **Talos OS**: https://www.talos.dev/
- **Proxmox VE**: https://www.proxmox.com/
- **Cilium**: https://cilium.io/
- **OpenTofu**: https://opentofu.org/
