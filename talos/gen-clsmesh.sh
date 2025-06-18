#!/usr/bin/env bash
set -euo pipefail

# 1. Leggi i cluster-name dai ConfigMap
CLUSTER_CLA=$(kubectl -n kube-system get configmap cilium-config \
  --context cla -o jsonpath='{.data.cluster-name}')
CLUSTER_CLB=$(kubectl -n kube-system get configmap cilium-config \
  --context clb -o jsonpath='{.data.cluster-name}')

echo "Cluster name on cla: $CLUSTER_CLA"
echo "Cluster name on clb: $CLUSTER_CLB"

# 2. Estrai i dati Base64 dai Secret esistenti
DATA_FROM_CLA=$(kubectl -n kube-system get secret cilium-clustermesh \
  --context cla -o jsonpath="{.data.$CLUSTER_CLB}")
DATA_FROM_CLB=$(kubectl -n kube-system get secret cilium-clustermesh \
  --context clb -o jsonpath="{.data.$CLUSTER_CLA}")

# 3. Genera il file YAML
cat <<EOF > cilium-clustermesh.yaml
apiVersion: v1
kind: Secret
metadata:
  name: cilium-clustermesh
  namespace: kube-system
type: Opaque
data:
  $CLUSTER_CLA: $DATA_FROM_CLB
  $CLUSTER_CLB: $DATA_FROM_CLA
EOF

for ctx in cla clb; do
  kubectl --context=$ctx -n kube-system delete secret cilium-clustermesh || true
  kubectl --context=$ctx -n kube-system apply -f cilium-clustermesh.yaml
  kubectl --context=$ctx -n kube-system rollout restart daemonset cilium
done

echo "🌟 cilium-clustermesh.yaml generato con successo."

