# Kubernetes Homelabs

Homelab infrastructure and applications management using Kubernetes, Proxmox, and various self-hosted services.

## Overview

This repository contains the infrastructure as code, application deployments, and configuration management for a homelab environment.

- **Infrastructure**: Proxmox VMs serves as Kubernetes clusters
- **Storage**: Synology NAS with NFS, Ceph distributed storage
- **Networking**: pfSense, Pi-hole, Tailscale/WireGuard VPN
- **Applications**: Plex, Immich, Google Photos Sync, Home Assistant, monitoring stack, etc.
- **AI/ML**: Inference with GPU support, distributed computing

## Quick Start

1. Clone the repository
2. Review documents at [https://mi-homes.org/docs/](https://mi-homes.org/docs/)
3. Follow deployment guides for specific components

## Naming Convention

- `pve` - Proxmox VE
- `pnode` - Proxmox node
- `pvm` - Proxmox VM
- `plxc` - Proxmox LXC container
- `kcluster` - Kubernetes cluster
- `knode` - Kubernetes node

## K3s Ansible
This is based on https://github.com/techno-tim/k3s-ansible

### Deploying the k3s cluster
- `./install_ansible.sh`
- Follow the guide to deploy the k3s cluster (TODO: write directly here)

### Connecting to k3s cluster from a new dev machine

#### 1. Install kubectl
```bash
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/
```

#### 2. Install ansible (for kubeconfig retrieval)
```bash
sudo apt update && sudo apt install -y ansible-core
```

#### 3. Get kubeconfig from k3s cluster
- Make sure you have the SSH key `~/.ssh/pvm-ubuntu-cloud` available

```bash
mkdir -p ~/.kube
scp -i ~/.ssh/pvm-ubuntu-cloud ansibleuser@192.168.68.201:~/.kube/config ~/.kube/config
```

#### 4. Verify connection
```bash
kubectl get pods --all-namespaces
```

#### 5. Optional: Add kubectl alias
```bash
echo 'alias k="kubectl"' >> ~/.bashrc
source ~/.bashrc
```

## NFS CSI Setup

### Installation

Install the NFS CSI Driver to enable NFS volume support in Kubernetes:

```bash
cd kubernetes/nfs-csi
./install.sh
```

## Plex Setup

### Configuration

Configure the following values in the deployment files:

- `SYNOLOGY_NAS_IP`: Your Synology NAS IP address
- `SYNOLOGY_NAS_SHARE`: NFS share path on your NAS
- `PLEX_CLAIM_TOKEN`: Get from https://www.plex.tv/claim/ (valid for 4 minutes)
- `PLEX_LOADBALANCER_IP`: Your desired LoadBalancer IP
- `PLEX_SERVER_NAME`: Your Plex server name

#### Installation Steps

1. Create Plex namespace:
   ```bash
   kubectl create namespace plex
   ```

2. Apply Plex PVCs:
   ```bash
   kubectl apply -f plex/pvc.yaml
   ```

3. Deploy Plex:
   ```bash
   kubectl apply -f plex/deployment.yaml
   ```

## Immich Setup

Immich is a self-hosted photo and video backup solution. This directory contains a reusable template-based deployment for Immich that allows easy deployment of multiple instances with different namespaces, domains, and NFS paths.

### Prerequisites

- Kubernetes cluster with NFS CSI driver support
- Helm 3.x
- NFS server accessible from the cluster
- Domain name for ingress (optional)

#### Configuration Variables

**Required Variables:**

- `INSTANCE_NAME`: Unique identifier for this instance
- `NAMESPACE`: Kubernetes namespace
- `DOMAIN_NAME`: Domain name for ingress
- `NFS_SERVER_IP`: IP address of the NFS server
- `NFS_BASE_PATH`: Base path on NFS server
- `DB_NAME`: PostgreSQL database name (typically `immich`)
- `DB_PASSWORD`: PostgreSQL database password
- `JWT_SECRET`: JWT secret for authentication

#### Deploying a New Instance

1. **Create NFS directories on the NAS first:**
   
   Before deploying, you must create the required directories on your NFS server. The PVCs will mount these directories, but they must exist beforehand.
   
   On your NAS, create the following directories under `${NFS_BASE_PATH}`:
   - `library/` - User library storage
   - `ml-cache/` - Machine learning model cache
   - `photos/` - Photo storage (read-only mount)
   - `redis/` - Redis data
   
   **Note:** The `postgres/` directory is not needed as PostgreSQL currently uses local-path storage, not NFS.

2. Create instance configuration directory:
   ```bash
   mkdir -p immich/instances/<instance-name>
   ```

3. Create `immich/instances/<instance-name>/instance.env` with the following variables:
   ```bash
   INSTANCE_NAME=<instance-name>
   NAMESPACE=immich-<instance-name>
   DOMAIN_NAME=<your-domain>
   NFS_SERVER_IP=<nfs-server-ip>
   NFS_BASE_PATH=/volume2/immich/<nfs-path>
   DB_NAME=immich
   DB_PASSWORD=<strong-password-or-empty>
   JWT_SECRET=<jwt-secret-or-empty>
   ```

4. Deploy the instance:
   ```bash
   cd immich
   ./deploy-instance.sh <instance-name>
   ```

   The script will:
   - Load configuration from `instances/<instance-name>/instance.env`
   - Validate required variables
   - Generate secrets if not provided
   - Generate instance-specific manifests from templates using `envsubst`
   - Create Kubernetes namespace
   - Apply secrets
   - Apply PVCs
   - Deploy PostgreSQL
   - Wait for PostgreSQL to be ready
   - Deploy Immich via Helm
   - Apply volume patch

### Upgrading

To upgrade an Immich instance:

```bash
cd immich
# Regenerate manifests and upgrade
./deploy-instance.sh <instance-name>

### Removal Steps

1. Uninstall Helm release:
   ```bash
   helm -n <namespace> uninstall <instance-name>
   ```

2. Remove PVCs:
   ```bash
   kubectl -n <namespace> delete pvc --all
   ```

3. Delete released PVs if needed

4. (Optional) Remove namespace:
   ```bash
   kubectl delete namespace <namespace>
   ```

## Cloudflare Tunnel Setup for Immich

This section contains Kubernetes manifests to deploy Cloudflare Tunnel (cloudflared) to expose your Immich application via a custom domain.

### Prerequisites

- Kubernetes cluster with kubectl access
- Cloudflare account (free tier works)
- Domain `yourdomain.com` purchased from Cloudflare
- Immich deployed and running in the `immich` namespace

### Step-by-Step Setup Guide

#### Step 1: Create Cloudflare Account

1. Go to [https://dash.cloudflare.com/sign-up](https://dash.cloudflare.com/sign-up)
2. Sign up for a free Cloudflare account
3. Verify your email address

#### Step 2: Verify Domain in Cloudflare

Since your domain is purchased from Cloudflare, it should already be configured in your Cloudflare account. Verify the setup:

1. Log in to [Cloudflare Dashboard](https://dash.cloudflare.com)
2. Ensure `yourdomain.com` is listed in your domains
3. Verify the domain is active and using Cloudflare nameservers (this is automatic for Cloudflare-purchased domains)
4. The `immich.yourdomain.com` subdomain will be automatically created when you configure the Cloudflare Tunnel in Step 4

#### Step 3: Set Up Cloudflare Zero Trust (Tunnels)

1. In Cloudflare Dashboard, go to **Zero Trust** (or visit [https://one.dash.cloudflare.com](https://one.dash.cloudflare.com))
2. If prompted, select the **Free** plan for Zero Trust
3. Navigate to **Networks** → **Tunnels**
4. Click **Create a tunnel**
5. Select **Cloudflared** as the connector type
6. Give your tunnel a name (e.g., `immich-tunnel`)
7. Click **Save tunnel**

#### Step 4: Configure the Tunnel

1. After creating the tunnel, chose a `Token` for `Docker` - **COPY THIS TOKEN** (you'll need it in the next step)
2. Click **Next**
3. In the `Connectors`:
   - **Subdomain**: `immich`
   - **Domain**: `yourdomain.com`
   - **Type**: `HTTP`
   - **URL**: `immich-server.immich.svc.cluster.local:2283`
4. Click **Complete setup**

#### Step 5: Deploy Cloudflare Tunnel to Kubernetes

1. Create the namespace:
   ```bash
   kubectl apply -f cloudflare/namespace.yaml
   ```

2. Create the secret with your tunnel token:
   ```bash
   # Copy the template
   cp cloudflare/secret.yaml.template cloudflare/secret.yaml
   
   # Edit the secret file and replace CHANGE_ME_TUNNEL_TOKEN with the token from Step 4
   nano cloudflare/secret.yaml
   ```

3. Apply the secret:
   ```bash
   kubectl apply -f cloudflare/secret.yaml
   ```

4. Deploy the tunnel:
   ```bash
   kubectl apply -f cloudflare/deployment.yaml
   ```

5. Verify the deployment:
   ```bash
   kubectl -n cloudflare-tunnel get pods
   kubectl -n cloudflare-tunnel logs -f deployment/cloudflared
   ```

#### Step 6: Verify the Setup

1. Wait a few minutes for DNS propagation (usually instant for Cloudflare domains)
2. Check DNS resolution:
   ```bash
   dig immich.yourdomain.com
   nslookup immich.yourdomain.com
   ```
3. Visit `https://immich.yourdomain.com/` in your browser
4. You should see your Immich login page

## Contributing

This is a personal homelab project. For issues and improvements, please create GitHub issues.

## License
