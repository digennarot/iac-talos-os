# Quick Reference Guide

Quick commands and references for common operations.

---

## Table of Contents

- [Essential Commands](#essential-commands)
- [Talosctl Commands](#talosctl-commands)
- [Kubectl Commands](#kubectl-commands)
- [Cilium Commands](#cilium-commands)
- [Diagnostic Commands](#diagnostic-commands)
- [Configuration Files](#configuration-files)
- [Network Ports](#network-ports)
- [Useful Scripts](#useful-scripts)

---

## Essential Commands

### Packer

```bash
# Initialize Packer
packer init main.pkr.hcl

# Validate configuration
packer validate -var-file="vars/local.pkrvars.hcl" main.pkr.hcl

# Build template
packer build -var-file="vars/local.pkrvars.hcl" main.pkr.hcl

# Build with specific variables
packer build \
  -var-file="vars/local.pkrvars.hcl" \
  -var "proxmox_node=pve2" \
  -var "vm_id=9701" \
  main.pkr.hcl
```

### OpenTofu/Terraform

```bash
# Initialize
tofu init

# Validate
tofu validate

# Plan
tofu plan

# Apply
tofu apply

# Destroy
tofu destroy

# Show state
tofu show

# List resources
tofu state list

# Import existing resource
tofu import module.masters.proxmox_vm_qemu.vm["cp01"] pve1/qemu/8001
```

### Talhelper

```bash
# Generate configurations
talhelper genconfig

# Validate configuration
talhelper validate --config talconfig-cla.yaml

# Generate secrets
talhelper gensecret > talsecret.yaml

# Encrypt secrets
sops -e -i talsecret.sops.cla.yaml
```

---

## Talosctl Commands

### Cluster Management

```bash
# Apply configuration (initial)
talosctl apply-config --insecure \
  --nodes 192.168.1.110 \
  --file clusterconfig/cla/cla-cp01.yaml

# Apply configuration (after initial)
talosctl apply-config \
  --nodes 192.168.1.110 \
  --file clusterconfig/cla/cla-cp01.yaml

# Bootstrap cluster
talosctl bootstrap \
  --nodes 192.168.1.110 \
  --endpoints 192.168.1.110

# Get kubeconfig
talosctl kubeconfig \
  --nodes 192.168.1.110 \
  --endpoints 192.168.1.230

# Merge kubeconfig
talosctl kubeconfig \
  --nodes 192.168.1.110 \
  --endpoints 192.168.1.230 \
  --merge
```

### Node Operations

```bash
# Reboot node
talosctl reboot --nodes 192.168.1.110

# Shutdown node
talosctl shutdown --nodes 192.168.1.110

# Reset node (DESTRUCTIVE!)
talosctl reset --nodes 192.168.1.110 --graceful=false --reboot

# Upgrade Talos
talosctl upgrade \
  --nodes 192.168.1.110 \
  --image ghcr.io/siderolabs/installer:v1.11.0 \
  --preserve=true

# Upgrade Kubernetes
talosctl upgrade-k8s --nodes 192.168.1.110 --to v1.34.0
```

### Information & Diagnostics

```bash
# Check health
talosctl health --nodes 192.168.1.110

# Get version
talosctl version --nodes 192.168.1.110

# List services
talosctl services --nodes 192.168.1.110

# Get service status
talosctl service kubelet --nodes 192.168.1.110

# View logs
talosctl logs kubelet --nodes 192.168.1.110
talosctl logs etcd --nodes 192.168.1.110

# Get dmesg
talosctl dmesg --nodes 192.168.1.110

# Get system info
talosctl get members --nodes 192.168.1.110
talosctl get addresses --nodes 192.168.1.110
talosctl get links --nodes 192.168.1.110

# Interactive dashboard
talosctl dashboard --nodes 192.168.1.110

# Top (resource usage)
talosctl top --nodes 192.168.1.110
```

### File Operations

```bash
# Read file
talosctl read /proc/cpuinfo --nodes 192.168.1.110

# Copy file from node
talosctl cp /var/log/audit.log ./audit.log --nodes 192.168.1.110

# List directory
talosctl ls /var/log --nodes 192.168.1.110
```

### etcd Operations

```bash
# etcd member list
talosctl etcd members --nodes 192.168.1.110

# etcd snapshot
talosctl etcd snapshot /var/lib/etcd.backup --nodes 192.168.1.110

# etcd status
talosctl etcd status --nodes 192.168.1.110

# etcd alarm list
talosctl etcd alarm list --nodes 192.168.1.110
```

---

## Kubectl Commands

### Cluster Information

```bash
# Cluster info
kubectl cluster-info

# Get nodes
kubectl get nodes
kubectl get nodes -o wide

# Describe node
kubectl describe node <node-name>

# Get all resources
kubectl get all -A

# Get events
kubectl get events -A --sort-by='.lastTimestamp'
```

### Pod Management

```bash
# Get pods
kubectl get pods -A
kubectl get pods -n kube-system

# Describe pod
kubectl describe pod <pod-name> -n <namespace>

# Get pod logs
kubectl logs <pod-name> -n <namespace>
kubectl logs -f <pod-name> -n <namespace>  # Follow
kubectl logs --previous <pod-name> -n <namespace>  # Previous container

# Execute command in pod
kubectl exec -it <pod-name> -n <namespace> -- /bin/sh

# Debug with ephemeral container
kubectl debug <pod-name> -n <namespace> -it --image=busybox
```

### Service & Networking

```bash
# Get services
kubectl get svc -A

# Get endpoints
kubectl get endpoints -A

# Get ingress
kubectl get ingress -A

# Port forward
kubectl port-forward svc/<service-name> 8080:80 -n <namespace>
```

### Resource Management

```bash
# Get resource usage
kubectl top nodes
kubectl top pods -A

# Get resource quotas
kubectl get resourcequota -A

# Get limit ranges
kubectl get limitrange -A
```

### Troubleshooting

```bash
# Run debug pod
kubectl run debug --image=busybox --rm -it --restart=Never -- sh

# Run network debug pod
kubectl run netdebug --image=nicolaka/netshoot --rm -it --restart=Never -- bash

# Check DNS
kubectl run -it --rm debug --image=busybox --restart=Never -- nslookup kubernetes.default

# Check connectivity
kubectl run -it --rm debug --image=busybox --restart=Never -- wget -O- http://service-name
```

---

## Cilium Commands

### Status & Health

```bash
# Check status
cilium status

# Wait for Cilium to be ready
cilium status --wait

# Check connectivity
cilium connectivity test

# Check cluster mesh status
cilium clustermesh status
```

### Installation & Upgrade

```bash
# Install Cilium
cilium install --version 1.14.5

# Upgrade Cilium
cilium upgrade --version 1.15.0

# Uninstall Cilium
cilium uninstall
```

### Configuration

```bash
# Get Cilium config
cilium config view

# Enable Hubble
cilium hubble enable

# Enable ClusterMesh
cilium clustermesh enable

# Connect clusters
cilium clustermesh connect --destination-context <cluster-name>
```

### Monitoring

```bash
# Monitor flows
cilium hubble observe

# Monitor specific namespace
cilium hubble observe --namespace kube-system

# Monitor specific pod
cilium hubble observe --pod <pod-name>

# Port forward Hubble UI
cilium hubble ui
```

---

## Diagnostic Commands

### Complete Health Check Script

```bash
#!/bin/bash
# health-check.sh

echo "=== Talos Health ==="
talosctl health --nodes 192.168.1.110,192.168.1.111,192.168.1.112

echo -e "\n=== Kubernetes Nodes ==="
kubectl get nodes -o wide

echo -e "\n=== System Pods ==="
kubectl get pods -n kube-system

echo -e "\n=== Cilium Status ==="
cilium status

echo -e "\n=== Resource Usage ==="
kubectl top nodes

echo -e "\n=== Recent Events ==="
kubectl get events -A --sort-by='.lastTimestamp' | tail -20

echo -e "\n=== Failed Pods ==="
kubectl get pods -A --field-selector=status.phase!=Running,status.phase!=Succeeded
```

### Log Collection Script

```bash
#!/bin/bash
# collect-logs.sh

OUTDIR="logs-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$OUTDIR"

# Talos logs
for node in 192.168.1.110 192.168.1.111 192.168.1.112; do
  echo "Collecting logs from $node..."
  talosctl -n $node logs kubelet > "$OUTDIR/kubelet-$node.log" 2>&1
  talosctl -n $node logs etcd > "$OUTDIR/etcd-$node.log" 2>&1
  talosctl -n $node dmesg > "$OUTDIR/dmesg-$node.log" 2>&1
done

# Kubernetes logs
kubectl logs -n kube-system -l k8s-app=cilium --tail=1000 > "$OUTDIR/cilium.log"
kubectl logs -n kube-system -l k8s-app=kube-dns --tail=1000 > "$OUTDIR/coredns.log"

# Cluster state
kubectl get all -A -o yaml > "$OUTDIR/cluster-state.yaml"
kubectl describe nodes > "$OUTDIR/nodes-describe.txt"

tar czf "$OUTDIR.tar.gz" "$OUTDIR"
echo "Logs collected in $OUTDIR.tar.gz"
```

---

## Configuration Files

### Important File Locations

```
Project Root
├── packer/
│   ├── main.pkr.hcl              # Packer template
│   ├── variables.pkr.hcl         # Variable definitions
│   └── vars/local.pkrvars.hcl    # Your variables
│
├── tofu/
│   ├── main.tf                   # Main infrastructure
│   ├── variables.tf              # Variable definitions
│   ├── clusters.auto.tfvars      # Cluster config
│   ├── talos.auto.tfvars         # Talos config
│   └── credentials.auto.tfvars   # Credentials (gitignored)
│
├── talos/
│   ├── talconfig-*.yaml          # Cluster definitions
│   ├── talsecret.sops.*.yaml     # Encrypted secrets
│   ├── .sops.yaml                # SOPS config
│   ├── age.key                   # Encryption key (gitignored)
│   └── clusterconfig/            # Generated configs
│
└── proxmox-ansible/
    ├── proxmox.yml               # Main playbook
    ├── inventory.yml             # Inventory
    └── host_vars/                # Host-specific vars
```

---

## Network Ports

### Talos OS

| Port | Protocol | Purpose |
|------|----------|---------|
| 50000 | TCP | Talos API (apid) |
| 50001 | TCP | Talos trustd |

### Kubernetes

| Port | Protocol | Purpose |
|------|----------|---------|
| 6443 | TCP | Kubernetes API Server |
| 2379-2380 | TCP | etcd client/peer |
| 10250 | TCP | kubelet API |
| 10256 | TCP | kube-proxy health |

### Cilium

| Port | Protocol | Purpose |
|------|----------|---------|
| 4240 | TCP | Cilium health |
| 4244 | TCP | Hubble server |
| 4245 | TCP | Hubble relay |
| 8472 | UDP | VXLAN overlay |

### Proxmox

| Port | Protocol | Purpose |
|------|----------|---------|
| 8006 | TCP | Web UI / API |
| 22 | TCP | SSH |
| 5900-5999 | TCP | VNC console |

---

## Useful Scripts

### Generate MAC Address

```bash
#!/bin/bash
# generate-mac.sh
printf 'BC:24:11:%02X:%02X:%02X\n' $((RANDOM%256)) $((RANDOM%256)) $((RANDOM%256))
```

### Wait for Node Ready

```bash
#!/bin/bash
# wait-for-node.sh
NODE=$1
while ! kubectl get node $NODE &> /dev/null; do
  echo "Waiting for node $NODE..."
  sleep 5
done
echo "Node $NODE is ready!"
```

### Backup etcd

```bash
#!/bin/bash
# backup-etcd.sh
BACKUP_DIR="./backups"
mkdir -p "$BACKUP_DIR"

for node in 192.168.1.110 192.168.1.111 192.168.1.112; do
  echo "Backing up etcd from $node..."
  talosctl -n $node etcd snapshot /var/lib/etcd-backup.db
  talosctl -n $node cp /var/lib/etcd-backup.db \
    "$BACKUP_DIR/etcd-$node-$(date +%Y%m%d-%H%M%S).db"
done
```

### Rolling Restart Workers

```bash
#!/bin/bash
# rolling-restart-workers.sh
WORKERS=$(kubectl get nodes -l node-role.kubernetes.io/worker -o name)

for worker in $WORKERS; do
  NODE_NAME=$(echo $worker | cut -d/ -f2)
  echo "Draining $NODE_NAME..."
  kubectl drain $NODE_NAME --ignore-daemonsets --delete-emptydir-data
  
  echo "Rebooting $NODE_NAME..."
  NODE_IP=$(kubectl get node $NODE_NAME -o jsonpath='{.status.addresses[?(@.type=="InternalIP")].address}')
  talosctl reboot --nodes $NODE_IP
  
  echo "Waiting for $NODE_NAME to be ready..."
  kubectl wait --for=condition=Ready node/$NODE_NAME --timeout=10m
  
  echo "Uncordoning $NODE_NAME..."
  kubectl uncordon $NODE_NAME
  
  echo "Waiting 30s before next node..."
  sleep 30
done
```

---

## Environment Setup

### Shell Aliases

Add to your `~/.bashrc` or `~/.zshrc`:

```bash
# Talos
alias tc='talosctl'
alias tcn='talosctl --nodes'
alias tch='talosctl health'

# Kubernetes
alias k='kubectl'
alias kgp='kubectl get pods'
alias kgs='kubectl get svc'
alias kgn='kubectl get nodes'
alias kd='kubectl describe'
alias kl='kubectl logs'
alias ke='kubectl exec -it'

# Cilium
alias cs='cilium status'
alias ct='cilium connectivity test'

# Quick cluster access
export TALOSCONFIG="$HOME/iac-talos-os/talos/clusterconfig/cla/talosconfig"
export KUBECONFIG="$HOME/.kube/config"
```

### Bash Completion

```bash
# Talosctl
source <(talosctl completion bash)

# Kubectl
source <(kubectl completion bash)

# Cilium
source <(cilium completion bash)
```

---

## Quick Troubleshooting

### Node Not Ready

```bash
# Check node status
kubectl describe node <node-name>

# Check kubelet logs
talosctl logs kubelet --nodes <node-ip>

# Check if CNI is running
kubectl get pods -n kube-system -l k8s-app=cilium
```

### Pod Not Starting

```bash
# Check pod events
kubectl describe pod <pod-name> -n <namespace>

# Check pod logs
kubectl logs <pod-name> -n <namespace>

# Check node resources
kubectl top nodes
```

### Network Issues

```bash
# Check Cilium status
cilium status

# Run connectivity test
cilium connectivity test

# Check pod network
kubectl run -it --rm debug --image=busybox --restart=Never -- ping 8.8.8.8
```

---

## References

- [Talos Documentation](https://www.talos.dev/docs/)
- [Kubernetes Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)
- [Cilium Documentation](https://docs.cilium.io/)
- [Proxmox Documentation](https://pve.proxmox.com/wiki/)
