#!/bin/bash

# === Variables ===
# Name of the Kubernetes cluster context
CLUSTER_NAME="cla"
# kubectl context flag for convenience
CONTEXT="--context $CLUSTER_NAME"
# Namespace where Cilium’s control-plane components live
NAMESPACE="kube-system"

# === Step 0: Apply Talos OS configuration to each node ===
# Talosctl pushes the YAML config to each node’s Talos OS
talosctl apply-config --nodes 192.168.1.110 --file clusterconfig/a/cla-cla-cp01.yaml --insecure
talosctl apply-config --nodes 192.168.1.111 --file clusterconfig/a/cla-cla-cp02.yaml --insecure
talosctl apply-config --nodes 192.168.1.112 --file clusterconfig/a/cla-cla-cp03.yaml --insecure
talosctl apply-config --nodes 192.168.1.113 --file clusterconfig/a/cla-cla-wk01.yaml --insecure
talosctl apply-config --nodes 192.168.1.114 --file clusterconfig/a/cla-cla-wk02.yaml --insecure

# Point talosctl to the generated cluster-wide config (credentials, CA, etc.)
export TALOSCONFIG=/home/tdigenna/repo/iac-talos-os/talos/clusterconfig/a/talosconfig

# Bootstrap the first control-plane node to actually create the Kubernetes control plane
talosctl bootstrap --nodes 192.168.1.110

kubectx cla
./wait-for-etcd.sh

# === Step 1: Deploy Gateway API CRDs ===
# Gateway API is a Kubernetes-standard way to define Ingress/Gateway resources.
# We install its CustomResourceDefinitions (CRDs) so the cluster understands them.
echo "Installing Gateway API CRDs..."
kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/gateway-api/v1.2.0/config/crd/standard/gateway.networking.k8s.io_gatewayclasses.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/gateway-api/v1.2.0/config/crd/standard/gateway.networking.k8s.io_gateways.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/gateway-api/v1.2.0/config/crd/standard/gateway.networking.k8s.io_httproutes.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/gateway-api/v1.2.0/config/crd/standard/gateway.networking.k8s.io_referencegrants.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/gateway-api/v1.2.0/config/crd/standard/gateway.networking.k8s.io_grpcroutes.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/gateway-api/v1.2.0/config/crd/experimental/gateway.networking.k8s.io_tlsroutes.yaml

# === Step 2: Install Cilium with Gateway API and Clustermesh support ===
# Cilium is a CNI plugin providing advanced networking and security for Kubernetes.
# We enable features like Gateway API integration and cross-cluster mesh.
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
  --helm-set cluster.id=1

# === Step 3: Wait for Cilium components to become ready ===
echo "Waiting for Cilium to be ready..."
MAX_RETRIES=3
RETRY_INTERVAL=30  # seconds

for i in $(seq 1 $MAX_RETRIES); do
    # cilium status returns non-zero until all pods are up
    cilium status && break || echo "Retrying Cilium status check ($i/$MAX_RETRIES)..."
    sleep $RETRY_INTERVAL
done

# If status is still not OK, redeploy Hubble (telemetry components)
if ! cilium status | grep -q "Status: OK"; then
    echo "Cilium is still not ready. Attempting to redeploy Hubble..."
    kubectl delete deployment -n $NAMESPACE hubble-relay hubble-ui || true
    cilium hubble enable --relay=true --ui=true
    cilium status --wait
fi

# Apply your cross-cluster pool configuration
kubectl apply -f clustermesh-pool-a.yaml

# === Step 4: Install NGINX Ingress Controller with Cilium integration ===
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace \
  --set controller.externalTrafficPolicy="Local" \
  --set controller.kind="DaemonSet" \
  --set controller.service.annotations."io.cilium/global-service"="true" \
  --set controller.service.annotations."io.cilium/lb-ipam-ips"="192.168.1.45"
# Verify that the LoadBalancer got an external IP
kubectl get svc ingress-nginx-controller -n ingress-nginx

# === Step 5: Enable Clustermesh in Cilium ===
echo "Enabling Clustermesh..."
cilium clustermesh enable ${CONTEXT} --service-type LoadBalancer # --enable-kvstoremesh=false

read -p "Press enter to continue"
# Label and restart the Clustermesh API server deployment to pick up service changes
echo "Labeling and restarting clustermesh-apiserver..."
kubectl ${CONTEXT} -n ${NAMESPACE} label svc clustermesh-apiserver clustermesh=enabled --overwrite
kubectl ${CONTEXT} -n ${NAMESPACE} rollout restart deployment clustermesh-apiserver
kubectl ${CONTEXT} -n ${NAMESPACE} rollout status deployment clustermesh-apiserver

# Check Clustermesh status and wait for quorum
echo "Checking Clustermesh status..."
cilium clustermesh status ${CONTEXT} --wait

# Display the Clustermesh service endpoint details
echo "Clustermesh Service Endpoint:"
kubectl ${CONTEXT} -n ${NAMESPACE} get svc clustermesh-apiserver -o wide

# === Final Diagnostic: Look for any pending pods across all namespaces ===
echo "=== Checking for Pending Pods ==="
PENDING_PODS=$(kubectl get pods -A | grep Pending | grep -v "NAMESPACE")
if [[ -n "$PENDING_PODS" ]]; then
    echo "Found pending pods. Showing details..."
    echo "$PENDING_PODS"
    # Describe each pending pod for troubleshooting
    while read -r line; do
        ns=$(echo $line | awk '{print $1}')
        pod=$(echo $line | awk '{print $2}')
        echo "=== Describing pod: $pod in namespace: $ns ==="
        kubectl describe pod "$pod" -n "$ns"
    done <<< "$PENDING_PODS"
else
    echo "No pending pods found."
fi

echo "✅ Clustermesh installation completed successfully!"
