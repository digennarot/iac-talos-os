#!/usr/bin/env bash
# install-cilium.sh
# 1. Remove Flannel
# 2. Discover etcd pod hosts (for endpoints & cert fetch)
# 3. Fetch or read etcd TLS certificates
# 4. Create/update k8s Secret for etcd TLS
# 5. Auto-detect cluster name & ID
# 6. Install/upgrade Cilium with ClusterMesh + external etcd
#    – includes IPAM, kube-proxy replacement, securityContext, cgroups
#    – optional data-plane encryption via env vars
# 7. Verify pods Ready & ClusterMesh active

set -euo pipefail
IFS=$'\n\t'

# ————— Configuration —————
CERT_DIR=${CERT_DIR:-/etc/cilium/etcd-certs}
CA_FILE="${CERT_DIR}/ca.crt"
CLIENT_CERT="${CERT_DIR}/client.crt"
CLIENT_KEY="${CERT_DIR}/client.key"
NAMESPACE="kube-system"
SECRET_NAME="cilium-etcd-secrets"

# Optional encryption settings (export these or rely on defaults)
ENABLE_ENCRYPTION=${ENABLE_ENCRYPTION:-true}
ENCRYPTION_TYPE=${ENCRYPTION_TYPE:-wireguard}
# ——————————————————————

cleanup() {
  [[ -n "${TMP_CERT_DIR-}" ]] && rm -rf "${TMP_CERT_DIR}"
}
trap cleanup EXIT

# 1) Remove Flannel DaemonSet if present
echo "Removing Flannel DaemonSet (if any)…"
kubectl delete ds kube-flannel -n "${NAMESPACE}" --ignore-not-found

# 2) Discover etcd pod host IPs
echo "Discovering etcd pod hosts…"
ETCD_HOSTS=( $(kubectl get pods -n "${NAMESPACE}" -l component=etcd \
  -o jsonpath='{.items[*].status.hostIP}') )
if [[ ${#ETCD_HOSTS[@]} -eq 0 ]]; then
  echo "ERROR: No etcd pods found in namespace ${NAMESPACE}" >&2
  exit 1
fi
echo "Found etcd hosts: ${ETCD_HOSTS[*]}"

# 3) Ensure TLS certs: local or fetch from first etcd host
if [[ -r "$CA_FILE" && -r "$CLIENT_CERT" && -r "$CLIENT_KEY" ]]; then
  echo "Using local TLS certs from ${CERT_DIR}"
else
  echo "Local certs not found; fetching from etcd host ${ETCD_HOSTS[0]}…"
  TMP_CERT_DIR=$(mktemp -d)
  for f in ca.crt client.crt client.key; do
    echo "  pulling /persist/secrets/etcd/${f}"
    talosctl -n "${ETCD_HOSTS[0]}" fs read "/persist/secrets/etcd/${f}" > "${TMP_CERT_DIR}/${f}"
  done
  CA_FILE="${TMP_CERT_DIR}/ca.crt"
  CLIENT_CERT="${TMP_CERT_DIR}/client.crt"
  CLIENT_KEY="${TMP_CERT_DIR}/client.key"
fi

# 4) Create or update the Kubernetes Secret for etcd TLS
if ! kubectl -n "${NAMESPACE}" get secret "${SECRET_NAME}" &>/dev/null; then
  echo "Creating Secret '${SECRET_NAME}' in namespace '${NAMESPACE}'…"
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
  echo "Secret '${SECRET_NAME}' already exists; skipping."
fi

# 5) Auto-detect cluster name & ID
CLUSTER_NAME=$(kubectl config current-context)
if [[ -z "$CLUSTER_NAME" ]]; then
  echo "ERROR: Could not detect current kubeconfig context." >&2
  exit 1
fi
CLUSTER_ID=$(echo -n "${CLUSTER_NAME}" | cksum | awk '{print $1}')
echo "Detected CLUSTER_NAME='${CLUSTER_NAME}', CLUSTER_ID='${CLUSTER_ID}'"

# 6) Prepare etcd endpoint flags
ETCD_FLAGS=()
for idx in "${!ETCD_HOSTS[@]}"; do
  ETCD_FLAGS+=(--set global.etcd.endpoints["${idx}"]="https://${ETCD_HOSTS[$idx]}:2379")
done

# 7) Add/update Cilium Helm repo
echo "Updating Cilium Helm repo…"
helm repo add cilium https://helm.cilium.io/ 2>/dev/null || true
helm repo update

# 8) Construct base Helm args
HELM_ARGS=(
  --namespace "${NAMESPACE}"
  --set clustermesh.enabled=true
  --set cluster.id="${CLUSTER_ID}"
  --set cluster.name="${CLUSTER_NAME}"
  --set global.etcd.enabled=true
  "${ETCD_FLAGS[@]}"
  --set global.etcd.secrets.secretName="${SECRET_NAME}"

  # Core Cilium settings
  --set ipam.mode=kubernetes
  --set kubeProxyReplacement=true
  --set securityContext.capabilities.ciliumAgent="{CHOWN,KILL,NET_ADMIN,NET_RAW,IPC_LOCK,SYS_ADMIN,SYS_RESOURCE,DAC_OVERRIDE,FOWNER,SETGID,SETUID}"
  --set securityContext.capabilities.cleanCiliumState="{NET_ADMIN,SYS_ADMIN,SYS_RESOURCE}"
  --set cgroup.autoMount.enabled=false
  --set cgroup.hostRoot=/sys/fs/cgroup
)

# 9) Optionally enable data-plane encryption
if [[ "${ENABLE_ENCRYPTION}" == "true" ]]; then
  echo "Enabling data-plane encryption (type=${ENCRYPTION_TYPE})"
  HELM_ARGS+=(--set encryption.enabled=true --set encryption.type="${ENCRYPTION_TYPE}")
fi

# 10) Install or upgrade Cilium
echo "Installing/upgrading Cilium with ClusterMesh + external etcd…"
helm upgrade --install cilium cilium/cilium "${HELM_ARGS[@]}"

# 11) Wait for all Cilium pods to be Ready
echo
echo "Waiting up to 120s for Cilium pods to be Ready…"
if kubectl -n "${NAMESPACE}" wait --for=condition=Ready pod -l k8s-app=cilium --timeout=120s; then
  echo "✅ All Cilium pods are Ready."
else
  echo "❌ Timeout waiting for pods; current status:"
  kubectl -n "${NAMESPACE}" get pods -l k8s-app=cilium
  exit 1
fi

# 12) Verify ClusterMesh in cilium status
echo
echo "Checking 'cilium status' for ClusterMesh…"
CM_LINE=$(cilium status | grep -E 'ClusterMesh')
if [[ -n "$CM_LINE" ]]; then
  echo "✅ ClusterMesh is active: $CM_LINE"
else
  echo "❌ ClusterMesh not detected."
  cilium status
  exit 1
fi

echo
echo "🎉 Cilium + ClusterMesh installation & verification complete!"
