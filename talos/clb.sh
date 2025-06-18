#!/bin/bash

# === Variables ===
# Name of the Kubernetes cluster context we’ll switch to
CLUSTER_NAME="clb"
# Shortcut for specifying the kubectl context
CONTEXT="--context $CLUSTER_NAME"
# Namespace where Cilium components run
NAMESPACE="kube-system"

# --- Step 0: Apply Talos OS configuration to each node ---
# Push Talos OS settings (networking, users, certificates, etc.) to each machine.
talosctl apply-config --nodes 192.168.1.120 --file clusterconfig/b/clb-clb-cp01.yaml --insecure
talosctl apply-config --nodes 192.168.1.121 --file clusterconfig/b/clb-clb-cp02.yaml --insecure
talosctl apply-config --nodes 192.168.1.122 --file clusterconfig/b/clb-clb-cp03.yaml --insecure
talosctl apply-config --nodes 192.168.1.123 --file clusterconfig/b/clb-clb-wk01.yaml --insecure
talosctl apply-config --nodes 192.168.1.124 --file clusterconfig/b/clb-clb-wk02.yaml --insecure

# Point talosctl at the generated cluster config (includes credentials & CA)
export TALOSCONFIG=/home/tdigenna/repo/iac-talos-os/talos/clusterconfig/b/talosconfig

# Bootstrap the first control-plane node to initialize Kubernetes control plane
talosctl bootstrap --nodes 192.168.1.120

kubectx clb
./wait-for-etcd.sh

# === Step 1: Deploy Gateway API CRDs ===
# Gateway API allows Kubernetes-native definitions for Ingress and routing.
# We install its CRDs so the API server recognizes Gateway, HTTPRoute, etc.
echo "Installing Gateway API CRDs..."
kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/gateway-api/v1.2.0/config/crd/standard/gateway.networking.k8s.io_gatewayclasses.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/gateway-api/v1.2.0/config/crd/standard/gateway.networking.k8s.io_gateways.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/gateway-api/v1.2.0/config/crd/standard/gateway.networking.k8s.io_httproutes.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/gateway-api/v1.2.0/config/crd/standard/gateway.networking.k8s.io_referencegrants.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/gateway-api/v1.2.0/config/crd/standard/gateway.networking.k8s.io_grpcroutes.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/gateway-api/v1.2.0/config/crd/experimental/gateway.networking.k8s.io_tlsroutes.yaml

# === Step 2: Install Cilium with Gateway API & Clustermesh support ===
# Cilium is a Container Network Interface plugin offering advanced L3–L7 networking,
# security policies, and multi-cluster mesh (Clustermesh).
echo "Installing Cilium with Clustermesh and Gateway API support..."
cilium install \
  --helm-set ipam.mode=kubernetes \
  --helm-set kubeProxyReplacement=true \
  --helm-set securityContext.capabilities.ciliumAgent="{CHOWN,KILL,NET_ADMIN,NET_RAW,IPC_LOCK,SYS_ADMIN,SYS_RESOURCE,DAC_OVERRIDE,FOWNER,SETGID,SETUID}" \
  --helm-set securityContext.capabilities.cleanCiliumState="{NET_ADMIN,SYS_ADMIN,SYS_RESOURCE}" \
  --helm-set cgroup.autoMount.enabled=false \
  --helm-set cgroup.hostRoot=/sys/fs/cgroup \
  --helm-set hubble.ui.frontend.server.ipv6.enabled=false \
  --helm-set gatewayAPI.enabled=true \
  --helm-set gatewayAPI.enableAlpn=true \
  --helm-set gatewayAPI.enableAppProtocol=true \
  --helm-set ipv6.enabled=false \
  --helm-set l2announcements.enabled=true \
  --helm-set externalIPs.enabled=true \
  --helm-set l2announcements.leaseDuration=3s \
  --helm-set l2announcements.leaseRenewDeadline=1s \
  --helm-set l2announcements.leaseRetryPeriod=200ms \
  --helm-set ipv4NativeRoutingCIDR=10.0.0.0/8 \
  --helm-set routingMode=native \
  --helm-set autoDirectNodeRoutes=true \
  --helm-set encryption.enabled=true \
  --helm-set encryption.type=wireguard \
  --helm-set cluster.id=2

# Sync the Cilium CA from the 'cla' cluster so both clusters share trust
kubectl --context=clb delete secret cilium-ca -n kube-system
kubectl --context=cla get secret -n kube-system cilium-ca -o yaml | \
  kubectl --context=clb create -f -

# === Step 3: Wait for Cilium to be ready, retrying if necessary ===
echo "Waiting for Cilium to be ready..."
MAX_RETRIES=3
RETRY_INTERVAL=30  # seconds

for i in $(seq 1 $MAX_RETRIES); do
    # `cilium status` exits non-zero until all Cilium pods and dependencies are up
    cilium status && break || echo "Retrying Cilium status check ($i/$MAX_RETRIES)…"
    sleep $RETRY_INTERVAL
done

# If still unhealthy, redeploy Hubble (observability components)
if ! cilium status | grep -q "Status: OK"; then
    echo "Cilium is still not ready. Redeploying Hubble components…"
    kubectl delete deployment -n $NAMESPACE hubble-relay hubble-ui || true
    cilium hubble enable --relay=true --ui=true
    cilium status --wait
fi

# Apply the pool configuration for cluster B’s Clustermesh
kubectl apply -f clustermesh-pool-b.yaml

# === Step 4: Install NGINX Ingress Controller with Cilium annotations ===
# This gives you an Ingress to route external HTTP(s) into the cluster.
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace \
  --set controller.externalTrafficPolicy="Local" \
  --set controller.kind="DaemonSet" \
  --set controller.service.annotations."io.cilium/global-service"="true" \
  --set controller.service.annotations."io.cilium/lb-ipam-ips"="192.168.1.65"
# Verify that the LoadBalancer has been assigned an external IP
kubectl get svc ingress-nginx-controller -n ingress-nginx

# === Step 5: Enable Clustermesh on this cluster ===
echo "Enabling Clustermesh for cross-cluster networking…"
cilium clustermesh enable ${CONTEXT} --service-type LoadBalancer #--enable-kvstoremesh=false

read -p "Press enter to continue"
# Label the clustermesh-apiserver Service so Cilium picks it up, then restart the deployment
echo "Labeling and restarting clustermesh-apiserver…"
kubectl ${CONTEXT} -n ${NAMESPACE} label svc clustermesh-apiserver clustermesh=enabled --overwrite
kubectl ${CONTEXT} -n ${NAMESPACE} rollout restart deployment clustermesh-apiserver
kubectl ${CONTEXT} -n ${NAMESPACE} rollout status deployment clustermesh-apiserver

# Wait for the mesh status to report all clusters connected
echo "Checking Clustermesh status…"
cilium clustermesh status ${CONTEXT} --wait

# Show the details of the clustermesh-apiserver Service endpoint
echo "Clustermesh Service Endpoint:"
kubectl ${CONTEXT} -n ${NAMESPACE} get svc clustermesh-apiserver -o wide

# === Final Diagnostic: Look for any Pending Pods ===
echo "=== Checking for Pending Pods Across All Namespaces ==="
PENDING_PODS=$(kubectl get pods -A | grep Pending | grep -v "NAMESPACE")
if [[ -n "$PENDING_PODS" ]]; then
    echo "Found pending pods: "
    echo "$PENDING_PODS"
    # Describe each one for troubleshooting details
    while read -r line; do
        ns=$(echo $line | awk '{print $1}')
        pod=$(echo $line | awk '{print $2}')
        echo "=== Describing pod: $pod in namespace: $ns ==="
        kubectl describe pod "$pod" -n "$ns"
    done <<< "$PENDING_PODS"
else
    echo "No pending pods found."
fi

echo "✅ Clustermesh installation for 'clb' completed successfully!"
