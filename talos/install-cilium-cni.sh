#!/usr/bin/env bash
# install-cilium-cni.sh - Installs and configures Cilium CNI, ClusterMesh,
# eBPF load balancing, encryption, and Service Mesh on a Talos Kubernetes cluster
# Usage: install-cilium-cni.sh -c CLUSTER_NAME -v CONTROL_PLANE_VIP \
#        [--enable-encryption] [--encryption-type wireguard] [--enable-clustermesh] \
#        [--clustermesh-secret SECRET] [--remote-contexts ctx1,ctx2,...] \
#        [--enable-loadbalancing] [--lb-mode <mode>] [--enable-servicemesh]
#
# Example (single-line):
#   install-cilium-cni.sh 
#     -c b \
#     -v 192.168.0.231 \
#     --enable-encryption \
#     --encryption-type wireguard \
#     --enable-clustermesh \
#     --clustermesh-secret 's3cr3tKey!' \
#     --remote-contexts  "admin@cla,admin@clb,admin@clc" 
#     --enable-loadbalancing 
#     --lb-mode cluster 
#     --enable-servicemesh
#
# Example (single-line):
#   install-cilium-cni.sh -c b -v 192.168.0.231 --enable-encryption --encryption-type wireguard --enable-clustermesh --clustermesh-secret 's3cr3tKey!' --remote-contexts  "admin@cla,admin@clb,admin@clc" --enable-loadbalancing --lb-mode cluster --enable-servicemesh

set -Eeuo pipefail
IFS=$'\n\t'

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Default options
ENABLE_ENCRYPTION=false
ENCRYPTION_TYPE="wireguard"
ENABLE_CLUSTERMESH=false
CLUSTERMESH_SECRET=""
REMOTE_CONTEXTS=""
ENABLE_LOADBALANCING=false
LB_MODE="cluster"  # Options: cluster, dsr, hybrid
ENABLE_SERVICEMESH=false

# Temp files
CNI_PATCH_FILE=$(mktemp)
KUBELET_PATCH_FILE=$(mktemp)

cleanup() {
  rm -f "$CNI_PATCH_FILE" "$KUBELET_PATCH_FILE"
}
trap cleanup EXIT

error()   { echo -e "${RED}[ERROR] $*${NC}" >&2; exit 1; }
warn()    { echo -e "${YELLOW}[WARN] $*${NC}"; }
info()    { echo -e "${GREEN}[INFO] $*${NC}"; }

usage() {
  cat <<EOF
Usage: $0 -c CLUSTER_NAME -v CONTROL_PLANE_VIP [options]

Required:
  -c, --cluster-name       Talos cluster name
  -v, --control-plane-vip  IP of Kubernetes API server

Options:
      --enable-encryption   Enable data-plane encryption
      --encryption-type     Type of encryption (ipsec|wireguard, default: wireguard)
      --enable-clustermesh  Enable Cilium ClusterMesh
      --clustermesh-secret  Shared secret for ClusterMesh
      --remote-contexts     Comma-separated list of kubeconfig contexts for remote clusters
      --enable-loadbalancing Enable eBPF-based load balancing
      --lb-mode             LoadBalancer mode (cluster|dsr|hybrid, default: cluster)
      --enable-servicemesh  Enable Cilium Service Mesh (L7 inspection)
  -h, --help               Show this help message
EOF
  exit 1
}

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    -c|--cluster-name)      CLUSTER_NAME="$2"; shift 2;;
    -v|--control-plane-vip) CONTROL_PLANE_VIP="$2"; shift 2;;
    --enable-encryption)    ENABLE_ENCRYPTION=true; shift;;
    --encryption-type)      ENCRYPTION_TYPE="$2"; shift 2;;
    --enable-clustermesh)   ENABLE_CLUSTERMESH=true; shift;;
    --clustermesh-secret)   CLUSTERMESH_SECRET="$2"; shift 2;;
    --remote-contexts)      REMOTE_CONTEXTS="$2"; shift 2;;
    --enable-loadbalancing) ENABLE_LOADBALANCING=true; shift;;
    --lb-mode)              LB_MODE="$2"; shift 2;;
    --enable-servicemesh)   ENABLE_SERVICEMESH=true; shift;;
    -h|--help)              usage;;
    *)                      usage;;
  esac
done

# Validate required arguments
[[ -z "${CLUSTER_NAME-}" || -z "${CONTROL_PLANE_VIP-}" ]] && usage
[[ "$ENABLE_CLUSTERMESH" == true && -z "$CLUSTERMESH_SECRET" ]] && error "ClusterMesh secret required when enabling clustermesh"
[[ "$ENABLE_CLUSTERMESH" == true && -z "$REMOTE_CONTEXTS" ]] && error "Remote contexts required when enabling clustermesh"

# Validate that CLUSTER_NAME matches a kubeconfig context when using ClusterMesh
if [[ "$ENABLE_CLUSTERMESH" == true ]]; then
  if ! kubectl config get-contexts -o name | grep  "${CLUSTER_NAME}"; then
    error "Kubeconfig context '${CLUSTER_NAME}' not found. Ensure -c matches a context name."
  fi
fi

# Ensure required commands
for cmd in kubectl talosctl curl tar cilium; do
  command -v "$cmd" &>/dev/null || error "$cmd is not installed"
done

# Ensure cluster is reachable
kubectl get nodes &>/dev/null || error "Cannot connect to cluster; check KUBECONFIG"
talosctl version &>/dev/null || error "talosctl not configured correctly"

# Step 1: Disable built-in CNI in Talos
apply_talos_cni_patch() {
  info "Disabling Talos built-in CNI"
  cat >"$CNI_PATCH_FILE" <<EOF
cluster:
  network:
    cni:
      name: none
  proxy:
    disabled: true
EOF
  talosctl gen config "$CLUSTER_NAME" "https://${CONTROL_PLANE_VIP}:6443" --config-patch "@${CNI_PATCH_FILE}" --force
  echo "Apply to all nodes: talosctl apply-config --nodes <IP> --file <generated-config>"
  read -rp "Applied to all nodes? [y/N]: " ans && [[ "$ans" =~ ^[Yy]$ ]] || error "Please apply config to all nodes"
}

# Step 2: Install Cilium CLI
install_cilium_cli() {
  if command -v cilium &>/dev/null; then
    info "Cilium CLI already present"
  else
    info "Installing Cilium CLI"
    version=$(curl -fsSL https://raw.githubusercontent.com/cilium/cilium-cli/main/stable.txt)
    arch=$(uname -m); [[ "$arch" =~ ^(aarch64|arm64)$ ]] && arch="arm64" || arch="amd64"
    curl -fsSL "https://github.com/cilium/cilium-cli/releases/download/${version}/cilium-linux-${arch}.tar.gz" \
      | sudo tar xz -C /usr/local/bin
    info "Cilium CLI v${version} installed"
  fi
}

# Step 3: Install Cilium with Helm values and reset if already installed
install_cilium() {
  info "Checking for terminating cilium-secrets namespace"
  if kubectl get namespace cilium-secrets &>/dev/null; then
    phase=$(kubectl get namespace cilium-secrets -o jsonpath='{.status.phase}')
    if [[ "$phase" == "Terminating" ]]; then
      warn "Namespace cilium-secrets is Terminating; cleaning up finalizers"
      kubectl patch namespace cilium-secrets -p '{"metadata":{"finalizers":[]}}' --type=merge
      info "Waiting for namespace cilium-secrets to terminate"
      until ! kubectl get namespace cilium-secrets &>/dev/null; do sleep 2; done
      info "Namespace cilium-secrets removed"
    fi
  fi

  info "Installing Cilium"
  if cilium status &>/dev/null; then
    warn "Existing Cilium installation detected, cleaning up"
    printf 'y
' | cilium uninstall --wait 
  fi
  info "Installing Cilium"
  if cilium status &>/dev/null; then
    warn "Existing Cilium installation detected, cleaning up"
    printf 'y\n' | cilium uninstall --wait 
  fi

  args=(
    --set ipam.mode=kubernetes
    --set kubeProxyReplacement=true
    --set securityContext.capabilities.ciliumAgent="{CHOWN,KILL,NET_ADMIN,NET_RAW,IPC_LOCK,SYS_ADMIN,SYS_RESOURCE,DAC_OVERRIDE,FOWNER,SETGID,SETUID}"
    --set securityContext.capabilities.cleanCiliumState="{NET_ADMIN,SYS_ADMIN,SYS_RESOURCE}"
    --set cgroup.autoMount.enabled=false
    --set cgroup.hostRoot=/sys/fs/cgroup
    --set k8sServiceHost="${CONTROL_PLANE_VIP}" --set k8sServicePort=6443
    --set gatewayAPI.enabled=true --set gatewayAPI.enableAlpn=true --set gatewayAPI.enableAppProtocol=true
    --set bpf.masquerade=true         # NAT via BPF masquerading
    --set hubble.enabled=true         # Enable Hubble observability
    --set hubble.relay.enabled=true   # Enable Hubble relay for UI functionality
    --set hubble.listenAddress=":4244" 
    --set hubble.ui.enabled=true
    --set ipv6.enabled=false          # Disable IPv6 support
    --set prometheus.enabled=true
    --set operator.prometheus.enabled=true
    --set hubble.metrics.enableOpenMetrics=true
    --set hubble.metrics.enabled="{dns,drop,tcp,flow,port-distribution,icmp,httpV2:exemplars=true;labelsContext=source_ip\,source_namespace\,source_workload\,destination_ip\,destination_namespace\,destination_workload\,traffic_direction}"
  )
  $ENABLE_ENCRYPTION && args+=(--set encryption.enabled=true --set encryption.type="${ENCRYPTION_TYPE}")
  $ENABLE_LOADBALANCING && args+=(--set service.loadBalancer.mode="${LB_MODE}")
  $ENABLE_SERVICEMESH && args+=(--set serviceMesh.enabled=true --set l7Proxy=true)

  cilium install "${args[@]}"
}

# Step 4: Install ClusterMesh
install_clustermesh() {
  info "Validating Kubernetes contexts for ClusterMesh"
  # Determine local kubeconfig context
  local LOCAL_CTX
  LOCAL_CTX=$(kubectl config current-context)
  info "Local context: $LOCAL_CTX"

    # Build full list of contexts: local + remotes
  IFS=',' read -ra REMOTES <<< "$REMOTE_CONTEXTS"
  CTXS=($LOCAL_CTX "${REMOTES[@]}")

  # Deduplicate and trim whitespace
  declare -A seen=()
  unique_ctxs=()
  for raw_ctx in "${CTXS[@]}"; do
    # Trim leading/trailing whitespace
    ctx=$(echo "$raw_ctx" | xargs)
    # Skip empty entries
    [[ -z "$ctx" ]] && continue
    # Only add unique contexts
    if [[ -z "${seen[$ctx]:-}" ]]; then
      seen[$ctx]=1
      unique_ctxs+=("$ctx")
    fi
  done
  CTXS=("${unique_ctxs[@]}")

  # Validate each context exists
  for ctx in "${CTXS[@]}"; do
    if ! kubectl config get-contexts -o name | grep "$ctx"; then
      error "Kubeconfig context '$ctx' not found"
    fi
    info "Context '$ctx' is valid"
  done

  # Apply shared secret in each context
  for ctx in "${CTXS[@]}"; do
    info "Applying shared secret in context $ctx"
    kubectl --context "$ctx" create secret generic clustermesh-secrets \
      --from-literal=secret="$CLUSTERMESH_SECRET" -n kube-system --dry-run=client -o yaml \
      | kubectl --context "$ctx" apply -f -
  done

  # Enable ClusterMesh in each context
  for ctx in "${CTXS[@]}"; do
    info "Enabling ClusterMesh on context $ctx"
    cilium --context "$ctx" clustermesh enable --service-type=LoadBalancer
  done

  info "ClusterMesh enabled on contexts: ${CTXS[*]}"
}

# Step 5: Remove default Flannel DaemonSet
remove_flannel() {
  if kubectl get ds kube-flannel -n kube-system &>/dev/null; then
    info "Removing Flannel DaemonSet"
    kubectl delete ds kube-flannel -n kube-system
    for res in clusterrole/flannel clusterrolebinding/flannel sa/flannel configmap/kube-flannel-cfg; do
      kubectl delete -n kube-system "${res#*/}" &>/dev/null && info "Deleted ${res}"
    done
  else
    info "No Flannel resources detected"
  fi
}

# Step 6: Patch kubelet TLS workaround
apply_kubelet_patch() {
  info "Patching kubelet authorization mode to AlwaysAllow"
  cat >"\$KUBELET_PATCH_FILE" <<EOF
- op: add
  path: /machine/kubelet/extraArgs
  value:
    authorization-mode: \"AlwaysAllow\"
EOF
  ips=(
    $(kubectl get nodes -o jsonpath='{.items[*].status.addresses[?(@.type=="InternalIP")].address}')
  )
  for ip in "${ips[@]}"; do
    talosctl -n "$ip" patch mc -p "@${KUBELET_PATCH_FILE}" || warn "Failed to patch kubelet on $ip"
  done
  sleep 30
}

# Step 7: Verify installation
verify() {
  info "Waiting for Cilium to be ready"
  cilium status --wait
  info "Checking CoreDNS pods"
  kubectl get pods -n kube-system -l k8s-app=kube-dns
  $ENABLE_CLUSTERMESH && cilium clustermesh status
}

# Main execution flow
main() {
  apply_talos_cni_patch
  install_cilium_cli
  install_cilium
  $ENABLE_CLUSTERMESH && install_clustermesh
  remove_flannel
  apply_kubelet_patch
  verify
  info "Cilium CNI, ClusterMesh, load balancing, encryption, and service mesh setup complete! 🎉"
}

# Invoke main
main "$@"
