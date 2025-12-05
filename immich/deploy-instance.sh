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
envsubst < "$SCRIPT_DIR/redis.yaml" > "$INSTANCE_DIR/redis.yaml"
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

echo "Deploying Redis..."
kubectl apply -f "$INSTANCE_DIR/redis.yaml"

echo "Waiting for Redis to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/${INSTANCE_NAME}-redis -n "$NAMESPACE" || true

echo "Deploying Immich using Helm..."
helm upgrade --install "$INSTANCE_NAME" oci://ghcr.io/immich-app/immich-charts/immich \
    -n "$NAMESPACE" \
    -f "$INSTANCE_DIR/values.yaml" \
    --wait --timeout 5m || {
    HELM_ERROR=$?
    echo ""
    echo "Warning: Helm deployment encountered an error (exit code: $HELM_ERROR)."
    echo ""
    
    if helm status "$INSTANCE_NAME" -n "$NAMESPACE" &>/dev/null; then
        echo "Checking for immutable field errors..."
        if kubectl get deployment "${INSTANCE_NAME}-server" -n "$NAMESPACE" &>/dev/null && \
           kubectl get deployment "${INSTANCE_NAME}-machine-learning" -n "$NAMESPACE" &>/dev/null; then
            echo ""
            echo "Detected immutable selector label conflicts."
            echo "This happens when upgrading from an older Helm chart version."
            echo ""
            echo "To fix this, you need to delete the deployments and let Helm recreate them:"
            echo "  kubectl delete deployment ${INSTANCE_NAME}-server ${INSTANCE_NAME}-machine-learning -n $NAMESPACE"
            echo "  Then run this script again: ./deploy-instance.sh $INSTANCE_NAME"
            echo ""
            read -p "Would you like to delete and recreate the deployments now? (y/N) " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                echo "Deleting deployments..."
                kubectl delete deployment "${INSTANCE_NAME}-server" "${INSTANCE_NAME}-machine-learning" -n "$NAMESPACE" --wait=false
                echo "Waiting for pods to terminate..."
                sleep 5
                echo "Retrying Helm upgrade..."
                helm upgrade --install "$INSTANCE_NAME" oci://ghcr.io/immich-app/immich-charts/immich \
                    -n "$NAMESPACE" \
                    -f "$INSTANCE_DIR/values.yaml" \
                    --wait --timeout 5m || {
                    echo "Helm upgrade still failed. Please check the error above."
                }
            else
                echo "Skipping deployment recreation. Please fix manually and rerun the script."
            fi
        fi
    fi
    
    echo ""
    echo "Checking deployment status..."
    helm status "$INSTANCE_NAME" -n "$NAMESPACE" 2>/dev/null || echo "Helm release status unavailable"
    echo ""
    echo "Current pod status:"
    kubectl -n "$NAMESPACE" get pods 2>/dev/null || echo "Unable to get pod status"
    echo ""
    echo "The deployment may still be in progress. You can:"
    echo "  1. Check pod status: kubectl -n $NAMESPACE get pods"
    echo "  2. Check server logs: kubectl -n $NAMESPACE logs -l app.kubernetes.io/name=immich,app.kubernetes.io/component=server"
    echo "  3. Wait and check again, or manually verify the deployment"
    echo ""
    echo "Continuing with post-deployment steps..."
}

echo "Applying patch for additional volumes..."
if kubectl get deployment "${INSTANCE_NAME}-server" -n "$NAMESPACE" &>/dev/null; then
    EXISTING_VOLUME=$(kubectl get deployment "${INSTANCE_NAME}-server" -n "$NAMESPACE" -o jsonpath='{.spec.template.spec.volumes[*].name}' | grep -q "photos" && echo "yes" || echo "no")
    
    if [ "$EXISTING_VOLUME" = "yes" ]; then
        echo "Photos volume already exists, skipping patch."
    else
        if command -v yq &> /dev/null; then
            VOLUME_MOUNT=$(yq eval '.spec.template.spec.containers[0].volumeMounts[0]' "$INSTANCE_DIR/patch.yaml" -o json)
            VOLUME=$(yq eval '.spec.template.spec.volumes[0]' "$INSTANCE_DIR/patch.yaml" -o json)
            PATCH_JSON=$(cat <<EOF
[
  {
    "op": "add",
    "path": "/spec/template/spec/containers/0/volumeMounts/-",
    "value": $VOLUME_MOUNT
  },
  {
    "op": "add",
    "path": "/spec/template/spec/volumes/-",
    "value": $VOLUME
  }
]
EOF
)
        else
            PATCH_JSON=$(cat <<EOF
[
  {
    "op": "add",
    "path": "/spec/template/spec/containers/0/volumeMounts/-",
    "value": {
      "name": "photos",
      "mountPath": "/mnt/photos",
      "readOnly": true
    }
  },
  {
    "op": "add",
    "path": "/spec/template/spec/volumes/-",
    "value": {
      "name": "photos",
      "persistentVolumeClaim": {
        "claimName": "${INSTANCE_NAME}-photos-pvc"
      }
    }
  }
]
EOF
)
        fi
        kubectl -n "$NAMESPACE" patch deployment "${INSTANCE_NAME}-server" --type='json' -p="$PATCH_JSON" || {
            echo "Warning: Patch failed. Check deployment name:"
            kubectl -n "$NAMESPACE" get deployments | grep server
        }
    fi
else
    echo "Warning: Deployment ${INSTANCE_NAME}-server not found. Skipping volume patch."
fi

echo ""
echo "Deployment complete!"
echo "Instance: $INSTANCE_NAME"
echo "Namespace: $NAMESPACE"
echo "Domain: $DOMAIN_NAME"
echo ""
echo "Check status with:"
echo "  kubectl -n $NAMESPACE get pods"
echo "  kubectl -n $NAMESPACE get svc"

