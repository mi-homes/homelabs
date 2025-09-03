#!/bin/bash

set -e

echo "Uninstalling NFS CSI Driver Helm chart..."
helm uninstall csi-driver-nfs -n kube-system

echo "Removing CSI driver NFS repository..."
helm repo remove csi-driver-nfs

echo "Cleaning up remaining resources..."
kubectl delete storageclass nfs-csi --ignore-not-found=true
kubectl delete serviceaccount csi-driver-nfs-controller -n kube-system --ignore-not-found=true
kubectl delete serviceaccount csi-driver-nfs-node -n kube-system --ignore-not-found=true

echo "NFS CSI Driver uninstallation completed!"
