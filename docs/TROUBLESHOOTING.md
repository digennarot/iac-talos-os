# Troubleshooting Guide

This document provides solutions to common issues you may encounter when deploying and managing Talos OS clusters on Proxmox.

---

## Table of Contents

- [Proxmox Issues](#proxmox-issues)
- [Packer Issues](#packer-issues)
- [OpenTofu/Terraform Issues](#opentofuterraform-issues)
- [Talos OS Issues](#talos-os-issues)
- [Kubernetes Issues](#kubernetes-issues)
- [Cilium Issues](#cilium-issues)
- [Networking Issues](#networking-issues)
- [Performance Issues](#performance-issues)

---

## Proxmox Issues

### Cannot Connect to Proxmox API

**Symptoms:**
- Connection timeout or refused
- SSL certificate errors
- Authentication failures

**Solutions:**

```bash
# Test API connectivity
curl -k https://your-proxmox:8006/api2/json/version

# Check if API token is correct
# Format should be: user@realm!tokenid
# Example: terraform@pam!provider

# Verify token has correct permissions
# In Proxmox UI: Datacenter → Permissions → API Tokens
# Required permissions: VM.Allocate, VM.Config.*, Datastore.Allocate

# Check firewall
sudo iptables -L -n | grep 8006
```

### Template Not Found

**Symptoms:**
- Error: "template 'talos-x.x.x-qemu' not found"

**Solutions:**

```bash
# List available templates on Proxmox node
ssh root@proxmox-node "qm list"

# Check if template exists
ssh root@proxmox-node "qm config 9700"

# Verify template name matches in tofu configuration
# In tofu/main.tf, check:
# clone = "talos-${var.talos.version}-qemu"

# Rebuild template if missing
cd packer
packer build -var-file="vars/local.pkrvars.hcl" main.pkr.hcl
```

### Storage Not Available

**Symptoms:**
- Error: "storage 'xxx' does not exist"
- Cannot allocate disk space

**Solutions:**

```bash
# List available storage on Proxmox
ssh root@proxmox-node "pvesm status"

# Check storage configuration
ssh root@proxmox-node "cat /etc/pve/storage.cfg"

# Verify storage is shared (for HA)
# In Proxmox UI: Datacenter → Storage
# Check "Shared" checkbox for your storage

# Update tofu configuration with correct storage ID
vim tofu/credentials.auto.tfvars
# shared_storage_id = "your-storage-name"
```

---

## Packer Issues

### Packer Build Fails - SSH Timeout

**Symptoms:**
- "Timeout waiting for SSH"
- Build hangs at SSH connection

**Solutions:**

```bash
# Increase SSH timeout in main.pkr.hcl
# ssh_timeout = "30m"  # Increase from default

# Check if VM is actually booting
# In Proxmox UI, check console of VM being built

# Verify network configuration
# Ensure VM can reach network and get IP via DHCP

# Check Proxmox firewall
ssh root@proxmox-node "pve-firewall status"
```

### Schematic ID Invalid

**Symptoms:**
- Error downloading Talos image
- 404 or invalid URL errors

**Solutions:**

```bash
# Regenerate schematic ID
curl -sS \
  -X POST https://factory.talos.dev/schematics \
  -H "Content-Type: application/yaml" \
  --data-binary @schematic.yaml \
  | jq -r .id

# Verify schematic is valid
curl -I "https://factory.talos.dev/image/$SCHEMATIC_ID/v1.10.3/nocloud-amd64.raw.xz"

# Check schematic.yaml syntax
cat schematic.yaml
# Ensure proper YAML formatting
```

### Disk Size Too Small

**Symptoms:**
- "No space left on device"
- Image won't fit on disk

**Solutions:**

```bash
# Check Talos image size
curl -I "https://factory.talos.dev/image/$SCHEMATIC_ID/v1.10.3/nocloud-amd64.raw.xz" | grep -i content-length

# Increase disk size in variables.pkr.hcl
# disk_size = "4G"  # Increase as needed

# Rebuild template
packer build -var-file="vars/local.pkrvars.hcl" main.pkr.hcl
```

---

## OpenTofu/Terraform Issues

### State Lock Error

**Symptoms:**
- "Error acquiring the state lock"
- "Lock Info: ID: ..."

**Solutions:**

```bash
# Force unlock (use with caution!)
tofu force-unlock <LOCK_ID>

# If using remote backend, check backend availability
# For local state, ensure no other tofu process is running
ps aux | grep tofu

# Remove stale lock file (local backend only)
rm -f tofu/.terraform.tfstate.lock.info
```

### Resource Already Exists

**Symptoms:**
- "already exists" errors
- Duplicate resource errors

**Solutions:**

```bash
# Import existing resource into state
tofu import module.masters.proxmox_vm_qemu.vm["cp01"] pve1/qemu/8001

# Or remove from Proxmox and let Tofu recreate
# In Proxmox UI, delete the VM
# Then run: tofu apply

# Check for duplicate definitions in .tfvars files
grep -r "vm_id.*8001" tofu/
```

### MAC Address Conflicts

**Symptoms:**
- Network issues
- Duplicate IP addresses
- VMs not getting correct IPs

**Solutions:**

```bash
# Ensure unique MAC addresses in clusters.auto.tfvars
# Use format: BC:24:11:XX:XX:XX
# Last 4 digits should be unique

# Generate random MAC addresses
printf 'BC:24:11:%02X:%02X:%02X\n' $((RANDOM%256)) $((RANDOM%256)) $((RANDOM%256))

# Check for duplicates
grep -r "mac_address" tofu/clusters.auto.tfvars | sort
```

### Provider Version Conflicts

**Symptoms:**
- "provider version constraint" errors
- Incompatible provider versions

**Solutions:**

```bash
# Remove lock file and reinitialize
rm tofu/.terraform.lock.hcl
tofu init -upgrade

# Pin provider version in provider.tf
# terraform {
#   required_providers {
#     proxmox = {
#       source  = "telmate/proxmox"
#       version = "~> 2.9"
#     }
#   }
# }
```

---

## Talos OS Issues

### Node Won't Boot

**Symptoms:**
- VM starts but doesn't respond
- No network connectivity
- Talosctl can't connect

**Solutions:**

```bash
# Check VM console in Proxmox UI
# Look for boot errors or kernel panics

# Verify VM has correct boot order
ssh root@proxmox-node "qm config <vmid> | grep boot"

# Check if disk was properly written
# Ensure Packer build completed successfully

# Try manual installation
# Boot from Talos ISO and install manually
# talosctl apply-config --insecure --nodes <ip> --file <config>
```

### Cannot Apply Configuration

**Symptoms:**
- "connection refused" when applying config
- "certificate verify failed"
- Timeout errors

**Solutions:**

```bash
# Use --insecure flag for initial configuration
talosctl apply-config --insecure \
  --nodes 192.168.1.110 \
  --file clusterconfig/cla/cla-cp01.yaml

# Check if node is reachable
ping 192.168.1.110

# Verify IP configuration is correct
# Check Proxmox console for actual IP

# Check firewall rules
# Talos needs ports: 50000, 50001, 6443

# Wait longer - first boot can take time
# Try again after 5-10 minutes
```

### etcd Won't Start

**Symptoms:**
- "etcd is not running"
- Bootstrap fails
- Control plane not ready

**Solutions:**

```bash
# Check etcd logs
talosctl -n 192.168.1.110 logs etcd

# Verify time synchronization
talosctl -n 192.168.1.110 time

# Check if other control plane nodes are interfering
# Only bootstrap on ONE node initially

# Verify network connectivity between control plane nodes
talosctl -n 192.168.1.110 ping 192.168.1.111

# Reset etcd and retry (DESTRUCTIVE)
talosctl -n 192.168.1.110 reset --graceful=false --reboot
# Then reapply config and bootstrap
```

### VIP Not Working

**Symptoms:**
- Cannot reach VIP address
- API server not accessible via VIP
- VIP not responding to ping

**Solutions:**

```bash
# Check VIP configuration in talconfig
# Ensure all control plane nodes have same VIP

# Verify network interface name
talosctl -n 192.168.1.110 get links

# Check if VIP is announced
talosctl -n 192.168.1.110 get addresses

# Ensure L2 announcements are enabled (for Cilium)
kubectl get ciliuml2announcementpolicy -A

# Check for IP conflicts
# Ensure VIP is not used by another device
ping 192.168.1.230  # Before starting cluster
```

### Certificate Errors

**Symptoms:**
- "x509: certificate signed by unknown authority"
- "certificate has expired"
- Cannot connect with talosctl

**Solutions:**

```bash
# Regenerate certificates
cd talos
talhelper genconfig

# Update talosconfig
export TALOSCONFIG=./clusterconfig/cla/talosconfig

# Reapply configuration
talosctl apply-config \
  --nodes 192.168.1.110 \
  --file clusterconfig/cla/cla-cp01.yaml

# For expired certificates, check system time
talosctl -n 192.168.1.110 time
# Ensure NTP is working
```

---

## Kubernetes Issues

### Nodes Not Ready

**Symptoms:**
- `kubectl get nodes` shows NotReady
- Pods not scheduling

**Solutions:**

```bash
# Check node status details
kubectl describe node <node-name>

# Most common: CNI not installed
# Install Cilium
cilium install --version 1.14.5

# Check kubelet logs
talosctl -n <node-ip> logs kubelet

# Verify pod network CIDR
kubectl cluster-info dump | grep -i cidr

# Check for resource pressure
kubectl top nodes
```

### Pods Stuck in Pending

**Symptoms:**
- Pods remain in Pending state
- "Insufficient resources" errors

**Solutions:**

```bash
# Check pod events
kubectl describe pod <pod-name>

# Check node resources
kubectl top nodes
kubectl describe nodes

# Check for taints
kubectl get nodes -o json | jq '.items[].spec.taints'

# Check PVC status (if using storage)
kubectl get pvc
kubectl describe pvc <pvc-name>

# Check scheduler logs
kubectl logs -n kube-system -l component=kube-scheduler
```

### CoreDNS Not Working

**Symptoms:**
- DNS resolution fails in pods
- "server misbehaving" errors
- Cannot resolve service names

**Solutions:**

```bash
# Check CoreDNS pods
kubectl get pods -n kube-system -l k8s-app=kube-dns

# Check CoreDNS logs
kubectl logs -n kube-system -l k8s-app=kube-dns

# Test DNS resolution
kubectl run -it --rm debug --image=busybox --restart=Never -- nslookup kubernetes.default

# Check CoreDNS ConfigMap
kubectl get cm -n kube-system coredns -o yaml

# Restart CoreDNS
kubectl rollout restart deployment -n kube-system coredns
```

### API Server Unreachable

**Symptoms:**
- "connection refused" to API server
- kubectl commands fail
- "Unable to connect to the server"

**Solutions:**

```bash
# Check if API server is running
talosctl -n 192.168.1.110 service kube-apiserver

# Check API server logs
talosctl -n 192.168.1.110 logs kube-apiserver

# Verify endpoint in kubeconfig
kubectl config view

# Test direct connection
curl -k https://192.168.1.230:6443/version

# Check if VIP is working
ping 192.168.1.230

# Try connecting to individual control plane node
kubectl --server=https://192.168.1.110:6443 get nodes
```

---

## Cilium Issues

### Cilium Pods CrashLooping

**Symptoms:**
- Cilium pods restart repeatedly
- Network connectivity issues
- Pods cannot communicate

**Solutions:**

```bash
# Check Cilium status
cilium status

# Check pod logs
kubectl logs -n kube-system -l k8s-app=cilium

# Verify kernel version
talosctl -n 192.168.1.110 version
# Cilium requires kernel 4.9+

# Check for required kernel modules
talosctl -n 192.168.1.110 read /proc/modules | grep -E 'bpf|vxlan'

# Reinstall Cilium
cilium uninstall
cilium install --version 1.14.5

# Check Cilium configuration
kubectl get cm -n kube-system cilium-config -o yaml
```

### L2 Announcements Not Working

**Symptoms:**
- LoadBalancer services don't get external IPs
- Services not reachable from outside cluster

**Solutions:**

```bash
# Check if L2 announcements are enabled
kubectl get ciliuml2announcementpolicy -A

# Create L2 announcement policy
cat <<EOF | kubectl apply -f -
apiVersion: cilium.io/v2alpha1
kind: CiliumL2AnnouncementPolicy
metadata:
  name: default-policy
spec:
  interfaces:
  - ^ens.*
  externalIPs: true
  loadBalancerIPs: true
EOF

# Create IP pool
cat <<EOF | kubectl apply -f -
apiVersion: cilium.io/v2alpha1
kind: CiliumLoadBalancerIPPool
metadata:
  name: default-pool
spec:
  cidrs:
  - cidr: 192.168.1.200/29
EOF

# Check Cilium L2 status
kubectl get ciliumnode -o yaml | grep -A 10 l2announce
```

### ClusterMesh Connection Failed

**Symptoms:**
- Clusters cannot communicate
- "clustermesh is not enabled"
- Connection timeout between clusters

**Solutions:**

```bash
# Check ClusterMesh status
cilium clustermesh status

# Verify ClusterMesh service
kubectl get svc -n kube-system clustermesh-apiserver

# Check if clusters have different pod CIDRs
# They MUST NOT overlap

# Verify network connectivity between clusters
# From cluster A, try to reach cluster B's ClusterMesh service

# Re-enable ClusterMesh
cilium clustermesh disable
cilium clustermesh enable

# Reconnect clusters
cilium clustermesh connect --destination-context <other-cluster>
```

---

## Networking Issues

### Pods Cannot Reach Internet

**Symptoms:**
- Pods cannot download images
- External DNS resolution fails
- Outbound connections timeout

**Solutions:**

```bash
# Check if nodes can reach internet
talosctl -n 192.168.1.110 ping 8.8.8.8

# Verify DNS configuration
talosctl -n 192.168.1.110 get resolvers

# Check NAT/masquerading
# Ensure Proxmox host or gateway provides NAT

# Test from pod
kubectl run -it --rm debug --image=busybox --restart=Never -- ping 8.8.8.8

# Check Cilium masquerading
kubectl get cm -n kube-system cilium-config -o yaml | grep masquerade
```

### Inter-Pod Communication Fails

**Symptoms:**
- Pods cannot reach each other
- Service endpoints not working
- Network policies blocking traffic

**Solutions:**

```bash
# Run Cilium connectivity test
cilium connectivity test

# Check Cilium agent status
kubectl exec -n kube-system -it <cilium-pod> -- cilium status

# Verify pod network
kubectl get pods -o wide
# Check if pods have IPs in correct range

# Check for network policies
kubectl get networkpolicies -A

# Test pod-to-pod connectivity
kubectl run -it --rm debug --image=busybox --restart=Never -- ping <other-pod-ip>
```

### Service Not Accessible

**Symptoms:**
- Cannot reach service ClusterIP
- Service endpoints empty
- Connection refused to service

**Solutions:**

```bash
# Check service
kubectl get svc <service-name>

# Check endpoints
kubectl get endpoints <service-name>

# Verify pod labels match service selector
kubectl get pods --show-labels
kubectl describe svc <service-name>

# Test service from pod
kubectl run -it --rm debug --image=busybox --restart=Never -- wget -O- http://<service-name>

# Check kube-proxy (if not using Cilium kube-proxy replacement)
talosctl -n <node-ip> service kube-proxy
```

---

## Performance Issues

### High CPU Usage

**Symptoms:**
- Nodes showing high CPU usage
- Pods being throttled
- Slow response times

**Solutions:**

```bash
# Check node resources
kubectl top nodes

# Check pod resources
kubectl top pods -A

# Identify high CPU pods
kubectl top pods -A --sort-by=cpu

# Check for CPU limits
kubectl describe pod <pod-name> | grep -A 5 Limits

# Increase VM CPU cores in tofu configuration
vim tofu/clusters.auto.tfvars
# node_cpu_cores = "8"  # Increase
tofu apply

# Check for runaway processes
talosctl -n <node-ip> top
```

### High Memory Usage

**Symptoms:**
- OOMKilled pods
- Nodes running out of memory
- Swap usage (if enabled)

**Solutions:**

```bash
# Check memory usage
kubectl top nodes
kubectl top pods -A --sort-by=memory

# Check for memory leaks
kubectl describe node <node-name> | grep -A 10 Allocated

# Increase VM memory
vim tofu/clusters.auto.tfvars
# node_memory = 32768  # Increase
tofu apply

# Check pod memory limits
kubectl get pods -A -o json | jq '.items[] | {name: .metadata.name, limits: .spec.containers[].resources.limits}'

# Restart high-memory pods
kubectl rollout restart deployment <deployment-name>
```

### Slow Disk I/O

**Symptoms:**
- Slow pod startup
- Database performance issues
- High iowait

**Solutions:**

```bash
# Check disk usage
talosctl -n <node-ip> df

# Check I/O stats
talosctl -n <node-ip> read /proc/diskstats

# In Proxmox, check storage performance
ssh root@proxmox-node "zpool iostat -v 1"

# Use faster storage
# Update tofu configuration to use SSD storage

# Enable disk caching in Proxmox
# VM → Hardware → Hard Disk → Cache: Write back

# Increase disk size
vim tofu/clusters.auto.tfvars
# node_disk = "128G"  # Increase
tofu apply
```

### Network Latency

**Symptoms:**
- High ping times between pods
- Slow service responses
- Timeout errors

**Solutions:**

```bash
# Test latency between nodes
talosctl -n 192.168.1.110 ping 192.168.1.111

# Check Cilium encryption overhead
kubectl get cm -n kube-system cilium-config -o yaml | grep encryption

# Disable encryption if not needed
cilium upgrade --set encryption.enabled=false

# Check network interface settings
talosctl -n <node-ip> get links

# Verify MTU settings
# Ensure consistent MTU across all nodes and network

# Check for network congestion
# Monitor Proxmox host network usage
```

---

## Diagnostic Commands

### Comprehensive Health Check

```bash
#!/bin/bash
# health-check.sh - Comprehensive cluster health check

echo "=== Talos Health ==="
talosctl health --nodes 192.168.1.110,192.168.1.111,192.168.1.112

echo "=== Kubernetes Nodes ==="
kubectl get nodes -o wide

echo "=== System Pods ==="
kubectl get pods -n kube-system

echo "=== Cilium Status ==="
cilium status

echo "=== Resource Usage ==="
kubectl top nodes
kubectl top pods -A --sort-by=cpu | head -10

echo "=== Recent Events ==="
kubectl get events -A --sort-by='.lastTimestamp' | tail -20

echo "=== Storage ==="
kubectl get pv
kubectl get pvc -A

echo "=== Services ==="
kubectl get svc -A
```

### Log Collection

```bash
#!/bin/bash
# collect-logs.sh - Collect logs for troubleshooting

OUTDIR="logs-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$OUTDIR"

# Talos logs
for node in 192.168.1.110 192.168.1.111 192.168.1.112; do
  talosctl -n $node logs kubelet > "$OUTDIR/kubelet-$node.log"
  talosctl -n $node logs etcd > "$OUTDIR/etcd-$node.log"
  talosctl -n $node dmesg > "$OUTDIR/dmesg-$node.log"
done

# Kubernetes logs
kubectl logs -n kube-system -l k8s-app=cilium --tail=1000 > "$OUTDIR/cilium.log"
kubectl logs -n kube-system -l k8s-app=kube-dns --tail=1000 > "$OUTDIR/coredns.log"

# Cluster state
kubectl get all -A -o yaml > "$OUTDIR/cluster-state.yaml"
kubectl describe nodes > "$OUTDIR/nodes-describe.txt"

echo "Logs collected in $OUTDIR/"
tar czf "$OUTDIR.tar.gz" "$OUTDIR"
echo "Archive created: $OUTDIR.tar.gz"
```

---

## Getting Help

If you're still experiencing issues:

1. **Check Logs**: Collect comprehensive logs using the script above
2. **Review Documentation**:
   - [Talos Documentation](https://www.talos.dev/docs/)
   - [Cilium Documentation](https://docs.cilium.io/)
   - [Proxmox Documentation](https://pve.proxmox.com/wiki/)
3. **Community Support**:
   - Talos Slack: https://slack.dev.talos-systems.io/
   - Cilium Slack: https://cilium.io/slack
   - Proxmox Forum: https://forum.proxmox.com/
4. **GitHub Issues**: Open an issue with detailed logs and reproduction steps

---

## Prevention Best Practices

- **Version Pinning**: Pin versions of all components
- **Testing**: Test changes in a development environment first
- **Backups**: Regular etcd backups and configuration backups
- **Monitoring**: Implement monitoring and alerting
- **Documentation**: Document your specific configuration
- **Change Management**: Use GitOps for all infrastructure changes
