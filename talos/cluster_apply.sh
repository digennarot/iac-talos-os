#!/usr/bin/env bash
set -euo pipefail
IFS=$' \t\n'

#-------------------------------------------------------------------------------
# cluster_apply.sh
# A production-ready script to reset, bootstrap, and configure Talos clusters
#-------------------------------------------------------------------------------

# ——— Configuration —————————————————————————————————————————————
DEFAULT_RESET=0
MAX_PARALLEL=5  # max concurrent reset jobs

# ——— Logging Functions —————————————————————————————————————————
log()   { printf "[%s] [INFO]    %s\n" "$(date +'%Y-%m-%dT%H:%M:%S%z')" "$*"; }
warn()  { printf "[%s] [WARNING] %s\n" "$(date +'%Y-%m-%dT%H:%M:%S%z')" "$*" >&2; }
error() { printf "[%s] [ERROR]   %s\n" "$(date +'%Y-%m-%dT%H:%M:%S%z')" "$*" >&2; exit 1; }

# ——— Usage —————————————————————————————————————————————————————
usage() {
  cat <<EOF
Usage: $(basename "$0") -c <cluster> [--reset] [--max-parallel N]

  -c CLUSTER        Cluster directory under clusterconfig/ (required)
  --reset           Perform reset of all nodes before configuration
  --max-parallel N  Maximum parallel reset jobs (default: $MAX_PARALLEL)
  -h, --help        Show this help message

Examples:
  $(basename "$0") -c b
  $(basename "$0") -c prod --reset --max-parallel 10
EOF
  exit 1
}

# ——— Argument Parsing —————————————————————————————————————————————
cluster=""
do_reset=$DEFAULT_RESET
while [[ $# -gt 0 ]]; do
  case "$1" in
    -c|--cluster)
      cluster="$2"; shift 2;;
    --reset)
      do_reset=1; shift;;
    --max-parallel)
      MAX_PARALLEL="$2"; shift 2;;
    -h|--help)
      usage;;
    *)
      warn "Unknown option: $1"; usage;;
  esac
done
[[ -n "$cluster" ]] || usage

# ——— Paths & Checks ———————————————————————————————————————————
CONFIG_DIR="clusterconfig/${cluster}"
TALOS_CFG="${CONFIG_DIR}/talosconfig"
command -v talosctl &>/dev/null || error "talosctl must be installed"
[[ -d "$CONFIG_DIR" ]] || error "Configuration directory not found: $CONFIG_DIR"
[[ -f "$TALOS_CFG" ]]  || error "talosconfig file missing: $TALOS_CFG"

# ——— Extract IPs —————————————————————————————————————————————
# Control-plane endpoints from "endpoints:" section
mapfile -t ENDPOINTS < <(
  sed -n '/endpoints:/,/nodes:/p' "$TALOS_CFG" \
    | grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}'
)
# create comma-separated list for --endpoints flag
ENDPOINTS_CSV="$(IFS=,; echo "${ENDPOINTS[*]}")"
# All nodes from "nodes:" section
mapfile -t ALL_NODES < <(
  sed -n '/nodes:/,$p' "$TALOS_CFG" \
    | grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}'
)
# Filter workers
WORKERS=()
for ip in "${ALL_NODES[@]}"; do
  if [[ ! " ${ENDPOINTS[*]} " =~ " $ip " ]]; then
    WORKERS+=("$ip")
  fi
done

# ——— Config Files ——————————————————————————————————————————————
CP_FILES=( $(ls -1 "${CONFIG_DIR}"/*-cp*.yaml | sort) )
WK_FILES=( $(ls -1 "${CONFIG_DIR}"/*-wk*.yaml | sort) )
(( ${#ENDPOINTS[@]} == ${#CP_FILES[@]} )) || error "#endpoints (${#ENDPOINTS[@]}) != #cp-files (${#CP_FILES[@]})"
(( ${#WORKERS[@]}   == ${#WK_FILES[@]}   )) || error "#workers (${#WORKERS[@]}) != #wk-files (${#WK_FILES[@]})"

# ——— Display Summary ——————————————————————————————————————————
log "Cluster: $cluster"
log "Control-planes: ${ENDPOINTS[*]}"
log "Workers:        ${WORKERS[*]}"
log "Configuration directory: $CONFIG_DIR"

# ——— Reset Phase —————————————————————————————————————————————————
if (( do_reset )); then
  read -rp "Reset ALL nodes? [y/N]: " confirm
  [[ "$confirm" =~ ^[Yy] ]] || error "Reset cancelled by user"
  log "Resetting nodes in parallel (max $MAX_PARALLEL jobs)"
  all_nodes=("${ENDPOINTS[@]}" "${WORKERS[@]}")
  n=0
  for ip in "${all_nodes[@]}"; do
    (( n % MAX_PARALLEL == 0 )) && wait
    log "Reset $ip"
    talosctl \
      --talosconfig "$TALOS_CFG" \
      --endpoints "$ENDPOINTS_CSV" \
      reset \
      --nodes "$ip" &
    ((n++))
  done
  wait
  log "All nodes reset"
fi

# ——— Apply Configuration ——————————————————————————————————————
# Remaining control-planes
for idx in "${!ENDPOINTS[@]}"; do
  [[ $idx -eq 0 ]] && continue
  ip="${ENDPOINTS[idx]}"; file="${CP_FILES[idx]}"
  log "Applying control-plane config $file to $ip"
  talosctl \
    --talosconfig "$TALOS_CFG" \
    --endpoints "$ENDPOINTS_CSV" \
    apply-config \
    --nodes "$ip" \
    --file "$file" \
    --insecure
done
# Workers
for idx in "${!WORKERS[@]}"; do
  ip="${WORKERS[idx]}"; file="${WK_FILES[idx]}"
  log "Applying worker config $file to $ip"
  talosctl \
    --talosconfig "$TALOS_CFG" \
    --endpoints "$ENDPOINTS_CSV" \
    apply-config \
    --nodes "$ip" \
    --file "$file" \
    --insecure
done

# ——— Bootstrap First Control-Plane —————————————————————————————
first_ip="${ENDPOINTS[0]}"
log "Bootstrapping first control-plane ($first_ip)"
talosctl \
  --talosconfig "$TALOS_CFG" \
  --endpoints "$ENDPOINTS_CSV" \
  bootstrap \
  --nodes "$first_ip"

log "Cluster configuration complete"
