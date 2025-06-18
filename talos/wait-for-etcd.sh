#!/usr/bin/env bash
set -euo pipefail

GREEN="\e[32m"
RED="\e[31m"
RESET="\e[0m"

# 1️⃣ Ottieni la lista dei nodi dal contesto attivo, se non fornita via env
if [[ -z "${TALOS_NODES:-}" ]]; then
  echo "🔍 Ricavo lista nodi dal contesto attivo di talosctl..."
  ENDPOINTS_LINE=$(talosctl config contexts | grep -v CURRENT | awk '{print $3}')
  if [[ -z "$ENDPOINTS_LINE" ]]; then
    echo -e "${RED}❌ Impossibile trovare alcun endpoint nel contesto attivo.${RESET}"
    exit 1
  fi
  # Trasforma "ip1,ip2,ip3" in array ("ip1" "ip2" "ip3")
  RAW_NODES=$(echo "$ENDPOINTS_LINE" | tr ',' ' ')
  IFS=' ' read -r -a NODES <<< "$RAW_NODES"
else
  IFS=',' read -r -a NODES <<< "$TALOS_NODES"
fi

if [[ "${#NODES[@]}" -eq 0 ]]; then
  echo -e "${RED}❌ Nessun nodo trovato. Esporta TALOS_NODES o configura talosctl.${RESET}"
  exit 1
fi

REF_NODE="${NODES[0]}"
echo "🕓 Attendo che etcd sia attivo, sano e in quorum sui nodi: ${NODES[*]}"

# 2️⃣ Loop di polling
while true; do
    ALL_GOOD=true

    for NODE in "${NODES[@]}"; do
        echo -ne "🔍 Controllo etcd su $NODE... "
        OUTPUT=$(talosctl -n "$NODE" get svc etcd -o json 2>/dev/null || true)
        RUNNING=$(echo "$OUTPUT" | jq -r '.spec.running' 2>/dev/null || echo "false")
        HEALTHY=$(echo "$OUTPUT" | jq -r '.spec.healthy' 2>/dev/null || echo "false")

        if [[ "$RUNNING" != "true" || "$HEALTHY" != "true" ]]; then
            echo -e "${RED}NON pronto (running=$RUNNING, healthy=$HEALTHY)${RESET}"
            ALL_GOOD=false
        else
            echo -e "${GREEN}OK${RESET}"
        fi
    done

    if [[ "$ALL_GOOD" == "true" ]]; then
        echo "✅ Tutti i nodi etcd sono attivi e sani. Verifico il quorum…"
        RAW_MEMBERS=$(talosctl -n "$REF_NODE" etcd members 2>/dev/null || echo "")
        LEADERS=$(echo "$RAW_MEMBERS" | grep -c LEADER)
        FOLLOWERS=$(echo "$RAW_MEMBERS" | grep -c FOLLOWER)
        TOTAL=$((LEADERS + FOLLOWERS))

        if [[ "$TOTAL" -eq "${#NODES[@]}" && "$LEADERS" -eq 1 ]]; then
            echo -e "🎉 ${GREEN}etcd è in quorum${RESET}: 1 leader, $FOLLOWERS follower"
            break
        else
            echo -e "${RED}⚠️ etcd non ancora in quorum (leader=$LEADERS, follower=$FOLLOWERS)${RESET}"
        fi
    fi

    sleep 5
done

echo -e "${GREEN}🚀 etcd è pronto su tutti i nodi ed è in quorum!${RESET}"

