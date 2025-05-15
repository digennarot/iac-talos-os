#!/usr/bin/env bash
# install-cilium-clustermesh.sh
# Installs/upgrades Cilium via Helm, optionally enables ClusterMesh.
# Derives CTX_NAME automatically from CONTROL_PLANE_VIP.

set -euo pipefail
IFS=$'\n\t'

# ————— Defaults —————
CERT_DIR=/etc/cilium/etcd-certs
NAMESPACE=kube-system
SECRET_NAME=cilium-etcd-secrets
ENABLE_ENCRYPTION=false
ENCRYPTION_TYPE=wireguard
POD_TIMEOUT=120
CM_SECRET="$(openssl rand -hex 16)"
ENABLE_CLUSTERMESH=false
CLUSTER_ID=""
CONTROL_PLANE_VIP=""
# —————————————————

usage() {
  cat <<EOF
Usage: $0 --control-plane-vip <VIP> --cluster-id <ID> [options]

Required:
  --control-plane-vip   IP of your Talos control-plane
  --cluster-id          Numeric cluster ID (0–255)

Options:
  --enable-clustermesh  Enable ClusterMesh after install
  --cm-secret           Shared secret for ClusterMesh
  --enable-encryption   Enable data-plane encryption
  --encryption-type     Type of encryption (wireguard|ipsec)
  --help                Show this help
EOF
  exit 1
}

# Parse args
while [[ $# -gt 0 ]]; do
  case $1 in
    --control-plane-vip) CONTROL_PLANE_VIP=$2; shift 2;;
    --cluster-id)        CLUSTER_ID=$2;        shift 2;;
    --enable-clustermesh)ENABLE_CLUSTERMESH=true; shift;;
    --cm-secret)         CM_SECRET=$2;         shift 2;;
    --enable-encryption) ENABLE_ENCRYPTION=true; shift;;
    --encryption-type)   ENCRYPTION_TYPE=$2;   shift 2;;
    -h|--help)           usage;;
    *)                   echo "Unknown arg: $1"; usage;;
  esac
done

# Validate
[[ -z "$CONTROL_PLANE_VIP" ]] && echo "ERROR: --control-plane-vip required" && usage
[[ -z "$CLUSTER_ID" ]]        && echo "ERROR: --cluster-id required" && usage
(( CLUSTER_ID>=0 && CLUSTER_ID<=255 )) || { echo "ERROR: cluster-id must be 0–255"; exit 1; }

info(){ echo "INFO: $*"; }
error(){ echo "ERROR: $*" >&2; exit 1; }

# Prereqs
for cmd in kubectl helm cilium talosctl openssl base64; do
  command -v "$cmd" &>/dev/null || error "Missing '$cmd'"
done

# Derive context name from VIP (e.g. 192.168.0.120 → talos-192-168-0-120)
CTX_NAME="talos-${CONTROL_PLANE_VIP//./-}"
info "Using kubeconfig context: ${CTX_NAME}"

# 1) Fetch kubeconfig
info "Fetching kubeconfig from Talos ${CONTROL_PLANE_VIP}..."
talosctl kubeconfig \
  --force-context-name "${CTX_NAME}" \
  --nodes "${CONTROL_PLANE_VIP}" \
  --force \
  "${HOME}/.kube/talos-${CTX_NAME}.config"
export KUBECONFIG="${HOME}/.kube/talos-${CTX_NAME}.config"

# 2) Remove Flannel
info "Removing Flannel..."
kubectl delete ds kube-flannel -n "${NAMESPACE}" --ignore-not-found

# 3) (Optional) etcd TLS secret logic if using external etcd
#    [Insert fetch logic here, if needed]

# 4) Detect cluster name & ID
CLUSTER_NAME="${CTX_NAME}"
info "Cluster name/id: ${CLUSTER_NAME}/${CLUSTER_ID}"

# 5) Build Helm args
HELM_ARGS=(
  --namespace "${NAMESPACE}"
  --set clustermesh.enabled="${ENABLE_CLUSTERMESH}"
  --set cluster.id="${CLUSTER_ID}"
  --set cluster.name="${CLUSTER_NAME}"
  --set k8sServiceHost="${CONTROL_PLANE_VIP}"
  --set k8sServicePort="6443"
  --set ipam.mode=kubernetes
  --set kubeProxyReplacement=true
  --set securityContext.capabilities.ciliumAgent="{CHOWN,KILL,NET_ADMIN,NET_RAW,IPC_LOCK,SYS_ADMIN,SYS_RESOURCE,DAC_OVERRIDE,FOWNER,SETGID,SETUID}"
  --set securityContext.capabilities.cleanCiliumState="{NET_ADMIN,SYS_ADMIN,SYS_RESOURCE}"
  --set cgroup.autoMount.enabled=false
  --set cgroup.hostRoot=/sys/fs/cgroup
)
if [[ "${ENABLE_ENCRYPTION}" == "true" ]]; then
  info "Enabling encryption (${ENCRYPTION_TYPE})"
  HELM_ARGS+=(--set encryption.enabled=true --set encryption.type="${ENCRYPTION_TYPE}")
fi

# 6) Install/upgrade Cilium
info "Updating Cilium Helm repo..."
helm repo add cilium https://helm.cilium.io/ &>/dev/null || true
helm repo update &>/dev/null

info "Installing/upgrading Cilium..."
helm upgrade --install cilium cilium/cilium "${HELM_ARGS[@]}"

# 7) Create/update TLS Secret (if needed)
CA_FILE="${CERT_DIR}/ca.crt"
CLIENT_CERT="${CERT_DIR}/client.crt"
CLIENT_KEY="${CERT_DIR}/client.key"
if [[ -r "$CA_FILE" && -r "$CLIENT_CERT" && -r "$CLIENT_KEY" ]]; then
  info "Creating etcd TLS Secret..."
  if ! kubectl -n "${NAMESPACE}" get secret "${SECRET_NAME}" &>/dev/null; then
    kubectl apply -f - <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: ${SECRET_NAME}
  namespace: ${NAMESPACE}
type: Opaque
data:
  ca.crt:   $(base64 -w0 "${CA_FILE}")
  cert.crt: $(base64 -w0 "${CLIENT_CERT}")
  key.key:  $(base64 -w0 "${CLIENT_KEY}")
EOF
  else
    info "Secret '${SECRET_NAME}' exists; skipping."
  fi
fi

# 8) Optionally enable ClusterMesh
if [[ "${ENABLE_CLUSTERMESH}" == "true" ]]; then
  info "Creating ClusterMesh secret..."
  kubectl -n "${NAMESPACE}" create secret generic clustermesh-secrets \
    --from-literal=secret="${CM_SECRET}" \
    --dry-run=client -o yaml | kubectl apply -f -

  info "Enabling ClusterMesh..."
  cilium clustermesh enable --service-type=LoadBalancer
fi

# 9) Wait for pods Ready
info "Waiting up to ${POD_TIMEOUT}s for Cilium pods..."
kubectl -n "${NAMESPACE}" wait --for=condition=Ready pod -l k8s-app=cilium \
  --timeout="${POD_TIMEOUT}s" || {
    kubectl -n "${NAMESPACE}" get pods -l k8s-app=cilium
    error "Cilium pods did not become Ready"
  }

# 10) Final status
info "Cilium status:"; cilium status
if [[ "${ENABLE_CLUSTERMESH}" == "true" ]]; then
  info "ClusterMesh status:"; cilium clustermesh status
fi

echo "🎉 Done."
