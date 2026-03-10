# Infrastructure-as-Code for Talos OS on Proxmox VE

## Introduction

This repository provides a complete Infrastructure-as-Code (IaC) solution for deploying and managing **Talos OS-based Kubernetes clusters** on **Proxmox VE** infrastructure. It combines multiple automation tools to create a production-ready, secure, and highly available Kubernetes environment.

### Key Components

- **Talos OS**: A minimal, secure, immutable operating system designed specifically for Kubernetes
- **Proxmox VE**: Open-source virtualization platform
- **Cilium**: Advanced networking and L2 load balancing with eBPF
- **OpenTofu/Terraform**: Infrastructure provisioning
- **Packer**: Automated VM template creation
- **Ansible**: Proxmox host configuration and hardening

## 📚 Documentation

Comprehensive documentation is available in the [`docs/`](./docs/) directory:

- **[Main Documentation](./docs/README.md)** - Complete overview, architecture, and usage guide
- **[Workflows](./docs/WORKFLOWS.md)** - Step-by-step deployment and operational procedures
- **[Architecture](./docs/ARCHITECTURE.md)** - Detailed system architecture and design decisions
- **[Configuration Reference](./docs/CONFIGURATION.md)** - Complete configuration options for all components
- **[Troubleshooting](./docs/TROUBLESHOOTING.md)** - Common issues and solutions
- **[Quick Reference](./docs/QUICK_REFERENCE.md)** - Quick commands and daily operations
- **[Contributing](./docs/CONTRIBUTING.md)** - How to contribute to this project

## Prerequisites
1. A Proxmox VE cluster or standalone Proxmox VE server.  
2. A Debian VM to act as your workstation/bastion host.  
3. Basic familiarity with Linux, containers, and Kubernetes.  

## Prepare the Workstation
On your Debian workstation, run the following commands to install the required tools.

### 1. Install Packer
```bash
wget -O- https://apt.releases.hashicorp.com/gpg \
  | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg

echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
  https://apt.releases.hashicorp.com $(lsb_release -cs) main" \
  | sudo tee /etc/apt/sources.list.d/hashicorp.list

sudo apt update && sudo apt install -y packer
packer -v
```

### 2. Install Tofu (OpenTofu)
```bash
sudo apt update && sudo apt install -y gnupg software-properties-common

wget -O- https://apt.releases.hashicorp.com/gpg \
  | gpg --dearmor \
  | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null

echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
  https://apt.releases.hashicorp.com $(lsb_release -cs) main" \
  | sudo tee /etc/apt/sources.list.d/hashicorp.list

sudo apt update && sudo apt install -y tofu
tofu -v
```

### 3. Install Talosctl
```bash
curl -sL https://talos.dev/install | sh
talosctl version
```

### 4. Install Talhelper
```bash
curl https://i.jpillora.com/budimanjojo/talhelper! | sudo bash
talhelper -v
```

### 5. Install kubectl
```bash
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
kubectl version --client
```

### 6. Install Sops
```bash
curl -LO https://github.com/getsops/sops/releases/download/v3.8.1/sops-v3.8.1.linux.amd64
sudo mv sops-v3.8.1.linux.amd64 /usr/local/bin/sops
sudo chmod +x /usr/local/bin/sops
sops -v
```

### 7. Install Age
```bash
sudo apt update && sudo apt install -y age
age --version
```

### 8. Install Cilium CLI
```bash
CILIUM_CLI_VERSION=$(curl -s https://raw.githubusercontent.com/cilium/cilium-cli/main/stable.txt)
CLI_ARCH=amd64
if [ "$(uname -m)" = "aarch64" ]; then CLI_ARCH=arm64; fi

curl -LO --fail https://github.com/cilium/cilium-cli/releases/download/${CILIUM_CLI_VERSION}/cilium-linux-${CLI_ARCH}.tar.gz
curl -LO https://github.com/cilium/cilium-cli/releases/download/${CILIUM_CLI_VERSION}/cilium-linux-${CLI_ARCH}.tar.gz.sha256sum

echo "$(cat cilium-linux-${CLI_ARCH}.tar.gz.sha256sum)  cilium-linux-${CLI_ARCH}.tar.gz" | sha256sum --check -
sudo tar xzvf cilium-linux-${CLI_ARCH}.tar.gz -C /usr/local/bin
rm cilium-linux-${CLI_ARCH}.tar.gz cilium-linux-${CLI_ARCH}.tar.gz.sha256sum
```