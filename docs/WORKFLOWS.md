# Deployment Workflows

This document provides detailed, step-by-step workflows for common operations in the IaC Talos OS project.

---

## Table of Contents

- [Initial Setup](#initial-setup)
- [Complete Cluster Deployment](#complete-cluster-deployment)
- [Adding a New Cluster](#adding-a-new-cluster)
- [Scaling Existing Cluster](#scaling-existing-cluster)
- [Upgrading Talos OS](#upgrading-talos-os)
- [Upgrading Kubernetes](#upgrading-kubernetes)
- [Setting Up ClusterMesh](#setting-up-clustermesh)
- [Backup and Recovery](#backup-and-recovery)

---

## Initial Setup

### Prerequisites Installation

Run these commands on your Debian workstation:

#### 1. Install Packer

```bash
wget -O- https://apt.releases.hashicorp.com/gpg \
  | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg

echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
  https://apt.releases.hashicorp.com $(lsb_release -cs) main" \
  | sudo tee /etc/apt/sources.list.d/hashicorp.list

sudo apt update && sudo apt install -y packer
packer -v
```

#### 2. Install OpenTofu

```bash
sudo apt update && sudo apt install -y gnupg software-properties-common

wget -O- https://apt.releases.hashicorp.com/gpg \
  | gpg --dearmor \
  | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null

echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
  https://apt.releases.hashicorp.com $(lsb_release -cs) main" \
  | sudo tee /etc/apt/sources.list.d/hashicorp.list

sudo apt update
sudo apt install -y tofu
tofu -v
```

#### 3. Install Talosctl

```bash
curl -sL https://talos.dev/install | sh
talosctl version
```

#### 4. Install Talhelper

```bash
curl https://i.jpillora.com/budimanjojo/talhelper! | sudo bash
talhelper -v
```

#### 5. Install kubectl

```bash
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
kubectl version --client
```

#### 6. Install SOPS

```bash
curl -LO https://github.com/getsops/sops/releases/download/v3.8.1/sops-v3.8.1.linux.amd64
sudo mv sops-v3.8.1.linux.amd64 /usr/local/bin/sops
sudo chmod +x /usr/local/bin/sops
sops -v
```

#### 7. Install Age

```bash
sudo apt update && sudo apt install -y age
age --version
```

#### 8. Install Cilium CLI

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

#### 9. Install Ansible (for Proxmox configuration)

```bash
sudo apt update
sudo apt install -y ansible
ansible --version
```

---

## Complete Cluster Deployment

This workflow covers deploying a complete Talos OS Kubernetes cluster from scratch.

### Step 1: Prepare Proxmox Hosts (Optional)

If you need to configure and harden your Proxmox hosts:

```bash
cd proxmox-ansible

# Copy example host variables
cp host_vars/example.yml host_vars/pve1.yml
cp host_vars/example.yml host_vars/pve2.yml
cp host_vars/example.yml host_vars/pve3.yml

# Edit each file with your specific configuration
vim host_vars/pve1.yml
vim host_vars/pve2.yml
vim host_vars/pve3.yml

# Update inventory
cat > inventory.yml <<EOF
all:
  hosts:
    pve1:
      ansible_host: 192.168.1.201
    pve2:
      ansible_host: 192.168.1.202
    pve3:
      ansible_host: 192.168.1.203
EOF

# Run the playbook
ansible-playbook -i inventory.yml proxmox.yml
```

### Step 2: Create Talos Schematic

Create a schematic file defining your Talos OS customizations:

```bash
cd packer

# Create schematic.yaml
cat > schematic.yaml <<EOF
customization:
  systemExtensions:
    officialExtensions:
      - siderolabs/i915-ucode
      - siderolabs/intel-ucode
      - siderolabs/qemu-guest-agent
EOF

# Generate schematic ID from Talos Image Factory
export SCHEMATIC_ID=$(curl -sS \
  -X POST https://factory.talos.dev/schematics \
  -H "Content-Type: application/yaml" \
  --data-binary @schematic.yaml \
  | jq -r .id)

echo "Schematic ID: $SCHEMATIC_ID"
```

### Step 3: Build Talos Templates with Packer

```bash
cd packer

# Create variables file
cat > vars/local.pkrvars.hcl <<EOF
proxmox_api_url          = "https://192.168.1.201:8006/api2/json"
proxmox_api_token_id     = "terraform@pam!provider"
proxmox_api_token_secret = "your-secret-here"

proxmox_node    = "pve1"
proxmox_storage = "local-zfs"

schematic_id = "$SCHEMATIC_ID"
EOF

# Initialize Packer
packer init main.pkr.hcl

# Build template on first node
packer build \
  -var-file="vars/local.pkrvars.hcl" \
  main.pkr.hcl

# Build on additional nodes
packer build \
  -var-file="vars/local.pkrvars.hcl" \
  -var "proxmox_node=pve2" \
  -var "vm_id=9701" \
  main.pkr.hcl

packer build \
  -var-file="vars/local.pkrvars.hcl" \
  -var "proxmox_node=pve3" \
  -var "vm_id=9702" \
  main.pkr.hcl
```

### Step 4: Configure OpenTofu

```bash
cd tofu

# Create credentials file
cat > credentials.auto.tfvars <<EOF
proxmox_api_url          = "https://192.168.1.201:8006/api2/json"
proxmox_api_token_id     = "terraform@pam!provider"
proxmox_api_token_secret = "your-secret-here"
shared_storage_id        = "shared-storage"
EOF

# Review and customize cluster configuration
vim clusters.auto.tfvars

# Example cluster configuration:
cat > clusters.auto.tfvars <<'EOF'
clusters = {
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
        mac_address    = "BC:24:11:2E:C8:11"
      }
      wk02 = {
        vm_id          = 8012
        node_name      = "pve2"
        node_cpu_cores = "8"
        node_memory    = 16384
        node_ipconfig  = "ip=192.168.1.114/24,gw=192.168.1.254"
        node_disk      = "64G"
        mac_address    = "BC:24:11:2E:C8:12"
      }
    }
  }
}
EOF

# Review Talos configuration
vim talos.auto.tfvars
```

### Step 5: Provision VMs

```bash
cd tofu

# Initialize Tofu
tofu init

# Review planned changes
tofu plan

# Apply configuration
tofu apply

# Note the output - you'll need VM IPs for the next steps
```

### Step 6: Configure Talos Cluster

```bash
cd talos

# Generate Age encryption key
age-keygen -o age.key
export AGE_PUBLIC_KEY=$(grep "# public key:" age.key | cut -d: -f2 | tr -d ' ')

# Configure SOPS
cat > .sops.yaml <<EOF
creation_rules:
  - path_regex: talsecret\.sops\..*\.yaml$
    age: $AGE_PUBLIC_KEY
EOF

# Create Talhelper configuration
cat > talconfig-cla.yaml <<EOF
talosVersion: v1.10.3
kubernetesVersion: v1.33.1

clusterName: cla
endpoint: https://192.168.1.230:6443

clusterPodNets:
  - 10.1.0.0/16
clusterSvcNets:
  - 172.20.0.0/24

additionalApiServerCertSans:
  - 192.168.1.230  # VIP
  - 192.168.1.110
  - 192.168.1.111
  - 192.168.1.112

additionalMachineCertSans:
  - 192.168.1.230
  - 192.168.1.110
  - 192.168.1.111
  - 192.168.1.112

patches:
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
      kubelet:
        extraArgs:
          authorization-mode: AlwaysAllow

cluster:
  discovery:
    enabled: false

controlPlane:
  patches:
    - |-
      cluster:
        network:
          cni:
            name: none  # We'll install Cilium manually
        proxy:
          disabled: true

nodes:
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
        vip:
          ip: 192.168.1.230

  - hostname: cla-cp02
    controlPlane: true
    installDisk: /dev/sda
    ipAddress: 192.168.1.111
    gateway: 192.168.1.254
    networkInterfaces:
      - interface: ens18
        dhcp: false
        addresses:
          - 192.168.1.111/24
        vip:
          ip: 192.168.1.230

  - hostname: cla-cp03
    controlPlane: true
    installDisk: /dev/sda
    ipAddress: 192.168.1.112
    gateway: 192.168.1.254
    networkInterfaces:
      - interface: ens18
        dhcp: false
        addresses:
          - 192.168.1.112/24
        vip:
          ip: 192.168.1.230

  - hostname: cla-wk01
    controlPlane: false
    installDisk: /dev/sda
    ipAddress: 192.168.1.113
    gateway: 192.168.1.254

  - hostname: cla-wk02
    controlPlane: false
    installDisk: /dev/sda
    ipAddress: 192.168.1.114
    gateway: 192.168.1.254
EOF

# Generate Talos configurations
talhelper genconfig

# Encrypt secrets
sops -e -i talsecret.sops.cla.yaml
```

### Step 7: Bootstrap Talos Cluster

```bash
cd talos

# Apply configuration to first control plane node
talosctl apply-config --insecure \
  --nodes 192.168.1.110 \
  --file clusterconfig/cla/cla-cp01.yaml

# Wait for node to be ready (check with talosctl health)
talosctl --nodes 192.168.1.110 health --wait-timeout 10m

# Apply to remaining control plane nodes
talosctl apply-config --insecure \
  --nodes 192.168.1.111 \
  --file clusterconfig/cla/cla-cp02.yaml

talosctl apply-config --insecure \
  --nodes 192.168.1.112 \
  --file clusterconfig/cla/cla-cp03.yaml

# Apply to worker nodes
talosctl apply-config --insecure \
  --nodes 192.168.1.113 \
  --file clusterconfig/cla/cla-wk01.yaml

talosctl apply-config --insecure \
  --nodes 192.168.1.114 \
  --file clusterconfig/cla/cla-wk02.yaml

# Bootstrap Kubernetes on first control plane
talosctl bootstrap \
  --nodes 192.168.1.110 \
  --endpoints 192.168.1.110 \
  --talosconfig ./clusterconfig/cla/talosconfig

# Wait for bootstrap to complete
sleep 60

# Get kubeconfig
talosctl kubeconfig \
  --nodes 192.168.1.110 \
  --endpoints 192.168.1.230 \
  --talosconfig ./clusterconfig/cla/talosconfig

# Verify nodes (they will be NotReady until CNI is installed)
kubectl get nodes
```

### Step 8: Install Cilium

```bash
# Install Cilium
cilium install \
  --version 1.14.5 \
  --set ipam.mode=kubernetes \
  --set kubeProxyReplacement=true \
  --set l2announcements.enabled=true

# Wait for Cilium to be ready
cilium status --wait

# Verify installation
kubectl get pods -n kube-system
kubectl get nodes  # Should now show Ready

# Run connectivity test
cilium connectivity test
```

### Step 9: Verify Cluster

```bash
# Check all nodes are ready
kubectl get nodes -o wide

# Check all system pods are running
kubectl get pods -A

# Check Talos health
talosctl health \
  --nodes 192.168.1.110,192.168.1.111,192.168.1.112 \
  --endpoints 192.168.1.230

# Deploy a test application
kubectl create deployment nginx --image=nginx
kubectl expose deployment nginx --port=80 --type=LoadBalancer
kubectl get svc nginx
```

---

## Adding a New Cluster

### Step 1: Update Tofu Configuration

```bash
cd tofu

# Edit clusters.auto.tfvars and add new cluster
vim clusters.auto.tfvars

# Example: Add cluster "clb"
# clusters = {
#   cla = { ... }  # existing
#   clb = {        # new cluster
#     target_nodes = ["pve1", "pve2", "pve3"]
#     vip          = "192.168.1.240"
#     pod_net      = "10.2.0.0/16"
#     svc_net      = "172.21.0.0/24"
#     masters = { ... }
#     workers = { ... }
#   }
# }

# Apply changes
tofu plan
tofu apply
```

### Step 2: Create Talos Configuration

```bash
cd talos

# Copy existing config as template
cp talconfig-cla.yaml talconfig-clb.yaml

# Edit for new cluster
vim talconfig-clb.yaml
# Update: clusterName, endpoint, IPs, pod/svc networks

# Generate configurations
talhelper genconfig

# Encrypt secrets
sops -e -i talsecret.sops.clb.yaml
```

### Step 3: Bootstrap New Cluster

Follow steps 7-9 from "Complete Cluster Deployment" using the new cluster's IPs and configuration.

---

## Scaling Existing Cluster

### Adding Worker Nodes

```bash
# Step 1: Update tofu configuration
cd tofu
vim clusters.auto.tfvars

# Add new worker to the workers map
# workers = {
#   wk01 = { ... }
#   wk02 = { ... }
#   wk03 = {  # new worker
#     vm_id = 8013
#     ...
#   }
# }

# Apply
tofu apply

# Step 2: Update Talos config
cd talos
vim talconfig-cla.yaml

# Add new node to nodes list
# - hostname: cla-wk03
#   controlPlane: false
#   ...

# Regenerate configs
talhelper genconfig

# Step 3: Apply to new node
talosctl apply-config --insecure \
  --nodes 192.168.1.115 \
  --file clusterconfig/cla/cla-wk03.yaml

# Step 4: Verify
kubectl get nodes
```

### Adding Control Plane Nodes

**Warning:** Adding control plane nodes requires careful consideration of etcd quorum.

```bash
# Follow same process as adding workers, but set controlPlane: true
# Ensure odd number of control plane nodes (3, 5, 7)
# Update VIP configuration on all control plane nodes
```

---

## Upgrading Talos OS

### Preparation

```bash
# Check current version
talosctl version --nodes 192.168.1.110

# Check available versions
curl -s https://api.github.com/repos/siderolabs/talos/releases | jq -r '.[].tag_name' | head -10
```

### Upgrade Process

```bash
cd talos

# Step 1: Update talconfig
vim talconfig-cla.yaml
# Change: talosVersion: v1.11.0

# Step 2: Regenerate configs
talhelper genconfig

# Step 3: Upgrade control plane nodes one at a time
talosctl upgrade \
  --nodes 192.168.1.110 \
  --image ghcr.io/siderolabs/installer:v1.11.0 \
  --preserve=true

# Wait for node to come back up
talosctl health --nodes 192.168.1.110 --wait-timeout 10m

# Repeat for other control plane nodes
talosctl upgrade --nodes 192.168.1.111 --image ghcr.io/siderolabs/installer:v1.11.0 --preserve=true
talosctl upgrade --nodes 192.168.1.112 --image ghcr.io/siderolabs/installer:v1.11.0 --preserve=true

# Step 4: Upgrade worker nodes
talosctl upgrade --nodes 192.168.1.113 --image ghcr.io/siderolabs/installer:v1.11.0 --preserve=true
talosctl upgrade --nodes 192.168.1.114 --image ghcr.io/siderolabs/installer:v1.11.0 --preserve=true

# Step 5: Verify
talosctl version --nodes 192.168.1.110,192.168.1.111,192.168.1.112
kubectl get nodes
```

---

## Upgrading Kubernetes

```bash
cd talos

# Step 1: Update talconfig
vim talconfig-cla.yaml
# Change: kubernetesVersion: v1.34.0

# Step 2: Regenerate configs
talhelper genconfig

# Step 3: Apply upgrade
talosctl upgrade-k8s \
  --nodes 192.168.1.110 \
  --to v1.34.0

# Monitor upgrade
kubectl get nodes -w

# Verify
kubectl version
```

---

## Setting Up ClusterMesh

ClusterMesh enables multi-cluster networking with Cilium.

### Prerequisites

- Two or more Kubernetes clusters with Cilium installed
- Non-overlapping pod CIDR ranges
- Network connectivity between clusters

### Step 1: Enable ClusterMesh

```bash
# On first cluster
export KUBECONFIG=~/.kube/config-cla
cilium clustermesh enable --service-type LoadBalancer

# On second cluster
export KUBECONFIG=~/.kube/config-clb
cilium clustermesh enable --service-type LoadBalancer

# Wait for ClusterMesh to be ready
cilium clustermesh status --wait
```

### Step 2: Connect Clusters

```bash
# Connect cluster B to cluster A
export KUBECONFIG=~/.kube/config-cla
cilium clustermesh connect --destination-context clb

# Verify connection
cilium clustermesh status
```

### Step 3: Deploy Global Services

```bash
# Create a global service (example)
cat > global-service.yaml <<EOF
apiVersion: v1
kind: Service
metadata:
  name: global-hello
  annotations:
    service.cilium.io/global: "true"
spec:
  type: ClusterIP
  ports:
  - port: 80
  selector:
    app: hello
EOF

kubectl apply -f global-service.yaml
```

---

## Backup and Recovery

### Backup etcd

```bash
# Create etcd snapshot
talosctl -n 192.168.1.110 etcd snapshot /var/lib/etcd.backup

# Download snapshot
talosctl -n 192.168.1.110 cp /var/lib/etcd.backup ./etcd-backup-$(date +%Y%m%d).db
```

### Backup Talos Configuration

```bash
# All configurations are in Git - ensure they're committed
cd talos
git add .
git commit -m "Backup cluster configuration"
git push
```

### Disaster Recovery

```bash
# Restore from etcd backup
talosctl -n 192.168.1.110 etcd snapshot restore /path/to/backup.db

# Rebootstrap cluster if needed
# Follow "Complete Cluster Deployment" workflow
```

---

## Maintenance Tasks

### Rotate Certificates

```bash
# Talos automatically rotates certificates
# To force rotation, regenerate configs and reapply
cd talos
talhelper genconfig
talosctl apply-config --nodes <node-ip> --file <config-file>
```

### Update Secrets

```bash
# Edit encrypted secrets
cd talos
sops talsecret.sops.cla.yaml

# Regenerate and reapply
talhelper genconfig
# Apply updated configs to nodes
```

### Monitor Cluster Health

```bash
# Talos health
talosctl health --nodes <nodes>

# Kubernetes health
kubectl get nodes
kubectl get pods -A
kubectl top nodes
kubectl top pods -A

# Cilium health
cilium status
cilium connectivity test
```

---

## Next Steps

- Review [TROUBLESHOOTING.md](./TROUBLESHOOTING.md) for common issues
- Explore [ARCHITECTURE.md](./ARCHITECTURE.md) for design details
- Check component-specific READMEs for advanced configuration
