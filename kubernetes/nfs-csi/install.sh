#!/bin/bash

set -e

echo "Adding CSI driver NFS repository..."
helm repo add csi-driver-nfs https://raw.githubusercontent.com/kubernetes-csi/csi-driver-nfs/master/charts
helm repo update

echo "Installing NFS CSI Driver..."
helm install csi-driver-nfs csi-driver-nfs/csi-driver-nfs \
  --namespace kube-system \
  --values values.yaml \
  --wait

echo "Waiting for CSI controller and node pods to be ready..."
kubectl wait --for=condition=Ready pod -l app.kubernetes.io/name=csi-driver-nfs \
  --namespace kube-system \
  --timeout=300s

echo "Verifying installation..."
kubectl get pods -n kube-system -l app.kubernetes.io/name=csi-driver-nfs

echo "NFS CSI Driver installation completed successfully!"
