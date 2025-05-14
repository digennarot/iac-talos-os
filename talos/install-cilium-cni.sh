#!/usr/bin/env bash
# install-cilium-cni.sh - Installs and configures Cilium CNI on a Talos Kubernetes cluster
# Usage: install-cilium-cni.sh -c CLUSTER_NAME -v CONTROL_PLANE_VIP [--enable-encryption] [--encryption-type wireguard]

set -Eeuo pipefail
IFS=$'\n\t'

# Colors
GREEN='\033[0;32m' YELLOW='\033[1;33m' RED='\033[0;31m' NC='\033[0m'

# Default options
ENABLE_ENCRYPTION=false
ENCRYPTION_TYPE="wireguard"

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
  -c  --cluster-name      Talos cluster name
  -v  --control-plane-vip IP of Kubernetes API server

Options:
      --enable-encryption  Enable encryption
      --encryption-type    Type of encryption (default: wireguard)
  -h  --help              Show this help message
EOF
  exit 1
}

# Parse args
while [[ $# -gt 0 ]]; do
  case $1 in
    -c|--cluster-name)      CLUSTER_NAME="$2"; shift 2;;
    -v|--control-plane-vip) CONTROL_PLANE_VIP="$2"; shift 2;;
    --enable-encryption)    ENABLE_ENCRYPTION=true; shift;;
    --encryption-type)      ENCRYPTION_TYPE="$2"; shift 2;;
    -h|--help)              usage;;
    *)                      usage;;
  esac
done

[[ -z "${CLUSTER_NAME-}" || -z "${CONTROL_PLANE_VIP-}" ]] && usage

# Ensure required commands are present
for cmd in kubectl talosctl curl tar; do
  command -v "$cmd" >/dev/null 2>&1 || error "$cmd is not installed"
done

# Ensure cluster is reachable
if ! kubectl get nodes &>/dev/null; then
  error "Cannot connect to cluster; check KUBECONFIG"
fi

talosctl version &>/dev/null || error "talosctl not configured correctly"

# Step 1: Disable built-in CNI in Talos
apply_talos_cni_patch() {
  info "Generating Talos CNI patch"
  cat >"$CNI_PATCH_FILE" <<EOF
cluster:
  network:
    cni:
      name: none
  proxy:
    disabled: true
EOF

  info "Regenerating Talos config with no-CNI"
  talosctl gen config "$CLUSTER_NAME" "https://${CONTROL_PLANE_VIP}:6443" \
    --config-patch "@${CNI_PATCH_FILE}" --force
  info "Please apply the new Talos config to all nodes before proceeding:"
  echo "  talosctl apply-config --nodes <NODE_IP> --file <path-to-generated-config>"
  read -rp "Have you applied it to all nodes? [y/N]: " ans
  [[ "$ans" =~ ^[Yy]$ ]] || error "Apply config to all nodes and rerun"
}

# Step 2: Install Cilium CLI
install_cilium_cli() {
  if command -v cilium &>/dev/null; then
    info "Cilium CLI already present"
    return
  fi

  info "Installing Cilium CLI"
  local version
  version=$(curl -fsSL https://raw.githubusercontent.com/cilium/cilium-cli/main/stable.txt)
  local arch=$(uname -m)
  [[ "$arch" == "aarch64" || "$arch" == "arm64" ]] && arch="arm64" || arch="amd64"

  curl -fsSL "https://github.com/cilium/cilium-cli/releases/download/${version}/cilium-linux-${arch}.tar.gz" \
    | sudo tar xz -C /usr/local/bin
  info "Cilium CLI v${version} installed"
}

# Step 3: Install Cilium itself
install_cilium() {
  info "Installing Cilium"
  local args=(
    --set ipam.mode=kubernetes
    --set kubeProxyReplacement=true
    --set securityContext.capabilities.ciliumAgent="{CHOWN,KILL,NET_ADMIN,NET_RAW,IPC_LOCK,SYS_ADMIN,SYS_RESOURCE,DAC_OVERRIDE,FOWNER,SETGID,SETUID}"
    --set securityContext.capabilities.cleanCiliumState="{NET_ADMIN,SYS_ADMIN,SYS_RESOURCE}"
    --set cgroup.autoMount.enabled=false
    --set cgroup.hostRoot=/sys/fs/cgroup
    --set k8sServiceHost="${CONTROL_PLANE_VIP}"
    --set k8sServicePort=6443
    --set gatewayAPI.enabled=true
    --set gatewayAPI.enableAlpn=true
    --set gatewayAPI.enableAppProtocol=true
  )

  $ENABLE_ENCRYPTION && args+=(--set encryption.enabled=true --set encryption.type="${ENCRYPTION_TYPE}")

  cilium install "${args[@]}"
}

# Step 4: Remove default Flannel if present
remove_flannel() {
  if kubectl get ds kube-flannel -n kube-system &>/dev/null; then
    info "Removing Flannel DaemonSet"
    kubectl delete ds kube-flannel -n kube-system

    for res in clusterrole/flannel clusterrolebinding/flannel sa/flannel configmap/kube-flannel-cfg; do
      kubectl delete -n kube-system "${res#*/}" &>/dev/null && info "Deleted ${res}"
    done
  else
    info "No Flannel resources found"
  fi
}

# Step 5: Patch kubelet to AlwaysAllow (TLS workaround)
apply_kubelet_patch() {
  info "Creating kubelet patch"
  cat >"$KUBELET_PATCH_FILE" <<EOF
- op: add
  path: /machine/kubelet/extraArgs
  value:
    authorization-mode: "AlwaysAllow"
EOF

  local ips
  read -r -a ips <<< "$(kubectl get nodes -o jsonpath='{.items[*].status.addresses[?(@.type=="InternalIP")].address}')"
  for ip in "${ips[@]}"; do
    info "Patching kubelet on ${ip}"
    talosctl -n "${ip}" patch mc -p "@${KUBELET_PATCH_FILE}" || warn "Failed on ${ip}"
  done

  info "Waiting for kubelet to restart"
  sleep 30
}

# Step 6: Verification
verify() {
  info "Waiting for Cilium to be ready"
  cilium status --wait

  info "Checking CoreDNS pods"
  kubectl get pods -n kube-system -l k8s-app=kube-dns
}

main() {
  apply_talos_cni_patch
  install_cilium_cli
  install_cilium
  remove_flannel
  apply_kubelet_patch
  verify
  info "Cilium CNI setup complete! 🎉"
  echo "Next: consider installing MetalLB for external load balancing."
}

main "$@"
