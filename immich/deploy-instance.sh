#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTANCE_NAME="${1:-}"

if [ -z "$INSTANCE_NAME" ]; then
    echo "Usage: $0 <instance-name>"
    exit 1
fi

INSTANCE_DIR="$SCRIPT_DIR/instances/$INSTANCE_NAME"
CONFIG_FILE="$INSTANCE_DIR/instance.env"

if [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: Config file not found: $CONFIG_FILE"
    echo "Please create the config file with required variables."
    exit 1
fi

echo "Loading configuration from $CONFIG_FILE"
set -a
source "$CONFIG_FILE"
set +a

if [ -z "${INSTANCE_NAME:-}" ] || [ -z "${NAMESPACE:-}" ] || [ -z "${DOMAIN_NAME:-}" ] || \
   [ -z "${NFS_SERVER_IP:-}" ] || [ -z "${NFS_BASE_PATH:-}" ] || [ -z "${DB_NAME:-}" ]; then
    echo "Error: Required variables not set in instance.env"
    echo "Required: INSTANCE_NAME, NAMESPACE, DOMAIN_NAME, NFS_SERVER_IP, NFS_BASE_PATH, DB_NAME"
    exit 1
fi

if [ -z "${DB_PASSWORD:-}" ] || [ -z "${JWT_SECRET:-}" ]; then
    echo "Warning: DB_PASSWORD or JWT_SECRET not set in instance.env"
    echo "Generating secrets..."
    
    if [ -z "${DB_PASSWORD:-}" ]; then
        DB_PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-32)
        echo "Generated DB_PASSWORD"
    fi
    
    if [ -z "${JWT_SECRET:-}" ]; then
        JWT_SECRET=$(openssl rand -base64 32)
        echo "Generated JWT_SECRET"
    fi
    
    echo ""
    echo "IMPORTANT: Save these secrets to your instance.env file:"
    echo "DB_PASSWORD=$DB_PASSWORD"
    echo "JWT_SECRET=$JWT_SECRET"
    echo ""
    read -p "Press Enter to continue or Ctrl+C to abort..."
fi

if [ -z "${IMMICH_VERSION:-}" ]; then
    IMMICH_VERSION="v2.1.0"
    echo "Using default Immich version: $IMMICH_VERSION"
fi

echo "Deploying Immich instance: $INSTANCE_NAME"
echo "  Namespace: $NAMESPACE"
echo "  Domain: $DOMAIN_NAME"
echo "  NFS Server: $NFS_SERVER_IP"
echo "  NFS Base Path: $NFS_BASE_PATH"
echo "  Immich Version: $IMMICH_VERSION"
echo ""

mkdir -p "$INSTANCE_DIR"

echo "Generating manifests from templates..."
export INSTANCE_NAME NAMESPACE DOMAIN_NAME NFS_SERVER_IP NFS_BASE_PATH DB_NAME DB_PASSWORD JWT_SECRET IMMICH_VERSION

envsubst < "$SCRIPT_DIR/pvc.yaml" > "$INSTANCE_DIR/pvc.yaml"
envsubst < "$SCRIPT_DIR/postgres.yaml" > "$INSTANCE_DIR/postgres.yaml"
envsubst < "$SCRIPT_DIR/patch.yaml" > "$INSTANCE_DIR/patch.yaml"
envsubst < "$SCRIPT_DIR/secrets.yaml.template" > "$INSTANCE_DIR/secrets.yaml"
envsubst < "$SCRIPT_DIR/values.yaml" > "$INSTANCE_DIR/values.yaml"

echo "Creating namespace..."
kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -

echo "Applying secrets..."
kubectl apply -f "$INSTANCE_DIR/secrets.yaml"

echo "Applying PVCs..."
kubectl apply -f "$INSTANCE_DIR/pvc.yaml"

echo "Deploying PostgreSQL..."
kubectl apply -f "$INSTANCE_DIR/postgres.yaml"

echo "Waiting for PostgreSQL to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/${INSTANCE_NAME}-postgresql -n "$NAMESPACE" || true

echo "Adding Helm repository..."
helm repo add immich https://immich-app.github.io/immich-charts || true
helm repo update

echo "Deploying Immich using Helm..."
helm upgrade --install "$INSTANCE_NAME" immich/immich \
    -n "$NAMESPACE" \
    -f "$INSTANCE_DIR/values.yaml" \
    --wait

echo "Applying patch for additional volumes..."
kubectl -n "$NAMESPACE" patch deployment "${INSTANCE_NAME}-server" --type='json' -p='[{"op": "add", "path": "/spec/template/spec/containers/0/volumeMounts/-", "value": {"name": "photos", "mountPath": "/mnt/photos"}}, {"op": "add", "path": "/spec/template/spec/volumes/-", "value": {"name": "photos", "persistentVolumeClaim": {"claimName": "'"${INSTANCE_NAME}"'-photos-pvc"}}}]' || {
    echo "Warning: Patch may have failed. Check deployment name:"
    kubectl -n "$NAMESPACE" get deployments | grep server
}

echo ""
echo "Deployment complete!"
echo "Instance: $INSTANCE_NAME"
echo "Namespace: $NAMESPACE"
echo "Domain: $DOMAIN_NAME"
echo ""
echo "Check status with:"
echo "  kubectl -n $NAMESPACE get pods"
echo "  kubectl -n $NAMESPACE get svc"

