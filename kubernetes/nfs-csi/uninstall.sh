#!/bin/bash

# NFS CSI Driver Uninstall Script for K3s

set -e

echo "🗑️  Uninstalling NFS CSI Driver..."

# Uninstall the Helm chart
echo "🔧 Uninstalling NFS CSI Driver Helm chart..."
helm uninstall csi-driver-nfs -n kube-system

# Remove the repository
echo "📚 Removing CSI driver NFS repository..."
helm repo remove csi-driver-nfs

# Clean up any remaining resources
echo "🧹 Cleaning up remaining resources..."
kubectl delete storageclass nfs-csi --ignore-not-found=true
kubectl delete serviceaccount csi-driver-nfs-controller -n kube-system --ignore-not-found=true
kubectl delete serviceaccount csi-driver-nfs-node -n kube-system --ignore-not-found=true

echo "✅ NFS CSI Driver uninstallation completed!"
