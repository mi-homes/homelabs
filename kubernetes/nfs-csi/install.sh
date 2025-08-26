#!/bin/bash

# NFS CSI Driver Installation Script for K3s
# Based on the official documentation

set -e

echo "🚀 Installing NFS CSI Driver for K3s..."

# Step 1: Check if Helm is available
echo "📦 Checking Helm availability..."
if ! command -v helm &> /dev/null; then
    echo "❌ Helm is not installed. Please install Helm first."
    echo "   You can install it with: curl https://get.helm.sh/helm-v3.12.0-linux-amd64.tar.gz | tar xz && sudo mv linux-amd64/helm /usr/local/bin/"
    exit 1
fi

# Step 2: Add the CSI driver NFS repository
echo "📚 Adding CSI driver NFS repository..."
helm repo add csi-driver-nfs https://raw.githubusercontent.com/kubernetes-csi/csi-driver-nfs/master/charts
helm repo update

# Step 3: Install the Helm chart
echo "🔧 Installing NFS CSI Driver..."
helm install csi-driver-nfs csi-driver-nfs/csi-driver-nfs \
  --namespace kube-system \
  --values values.yaml \
  --wait

# Step 4: Wait for pods to be ready
echo "⏳ Waiting for CSI controller and node pods to be ready..."
kubectl wait --for=condition=Ready pod -l app.kubernetes.io/name=csi-driver-nfs \
  --namespace kube-system \
  --timeout=300s

# Step 5: Verify installation
echo "✅ Verifying installation..."
kubectl get pods -n kube-system -l app.kubernetes.io/name=csi-driver-nfs

echo "🎉 NFS CSI Driver installation completed successfully!"
echo ""
echo "📋 Next steps:"
echo "1. Create a PersistentVolumeClaim using the 'nfs-csi' storage class"
echo "2. Mount the PVC in your applications"
echo ""
echo "📖 Example PVC:"
echo "apiVersion: v1"
echo "kind: PersistentVolumeClaim"
echo "metadata:"
echo "  name: nfs-pvc"
echo "spec:"
echo "  accessModes:"
echo "    - ReadWriteMany"
echo "  storageClassName: nfs-csi"
echo "  resources:"
echo "    requests:"
echo "      storage: 10Gi"
