#!/usr/bin/env bash
# approve-pending-csrs.sh - Approves pending CSRs for Talos Kubernetes nodes
# Usage: approve-pending-csrs.sh [--dry-run] [--label-selector LABELS]

set -Eeuo pipefail
IFS=$'\n\t'

# Color codes
GREEN='\033[0;32m' YELLOW='\033[1;33m' RED='\033[0;31m' NC='\033[0m'

# Defaults
DRY_RUN=false
LABEL_SELECTOR=""

# Cleanup on error
trap 'error "An unexpected error occurred."' ERR

error() { echo -e "${RED}[ERROR] $*${NC}" >&2; exit 1; }
warn()  { echo -e "${YELLOW}[WARN] $*${NC}"; }
info()  { echo -e "${GREEN}[INFO] $*${NC}"; }

usage() {
  cat <<EOF
Usage: $0 [options]

Options:
  --dry-run               List pending CSRs without approving them
  --label-selector LABELS Approve only CSRs matching this label selector
  -h, --help              Show this help message
EOF
  exit 1
}

# Parse arguments
while [[ "${1-}" ]]; do
  case "$1" in
    --dry-run)           DRY_RUN=true; shift ;;
    --label-selector)    LABEL_SELECTOR="$2"; shift 2 ;;
    -h|--help)           usage ;;
    *)                   usage ;;
  esac
done

# Ensure kubectl is available
if ! command -v kubectl &>/dev/null; then
  error "kubectl not found; please install and add it to your PATH"
fi

# Ensure we can connect to Kubernetes
if ! kubectl get nodes &>/dev/null; then
  error "Cannot connect to Kubernetes cluster; check your KUBECONFIG"
fi

# Fetch pending CSRs
get_pending_csrs() {
  local selector_arg=( )
  if [[ -n "$LABEL_SELECTOR" ]]; then
    selector_arg=(--selector "$LABEL_SELECTOR")
  fi

  mapfile -t csrs < <(
    kubectl get csr "${selector_arg[@]}" --field-selector=status.conditions[0].type!=Approved \
      -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}'
  )
}

# Approve given CSRs
approve_csrs() {
  for csr in "${csrs[@]}"; do
    if [[ "$DRY_RUN" == true ]]; then
      echo "DRY-RUN: would approve CSR ${csr}"
    else
      info "Approving CSR: ${csr}"
      kubectl certificate approve "${csr}"
    fi
  done
}

main() {
  info "Retrieving pending CSRs..."
  get_pending_csrs

  if [[ ${#csrs[@]} -eq 0 ]]; then
    info "No pending CSRs found."
    exit 0
  fi

  info "Found ${#csrs[@]} pending CSR(s)."
  approve_csrs

  if [[ "$DRY_RUN" == false ]]; then
    info "All pending CSRs have been approved."
    warn "Future kubelet CSRs should be auto-approved by the kubelet-serving-cert-approver."
  else
    warn "Dry-run complete. No CSRs were modified."
  fi
}

main
