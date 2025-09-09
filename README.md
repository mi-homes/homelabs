# Kubernetes Homelabs

Personal homelab infrastructure and applications management using Kubernetes, Proxmox, and various self-hosted services.

## Overview

This repository contains the infrastructure as code, application deployments, and configuration management for my personal homelab environment.

- **Infrastructure**: Proxmox VE with k3s Kubernetes clusters
- **Storage**: Synology NAS with NFS, Ceph distributed storage
- **Networking**: pfSense, Pi-hole, Tailscale/WireGuard VPN
- **Applications**: Plex, Immich, Google Photos Sync, Home Assistant, monitoring stack, etc.
- **AI/ML**: Host LLM with GPU support, distributed computing

## Quick Start

1. Clone the repository
2. Review setup requirements in `docs/`
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

- `./install_ansible.sh`
- Follow the guide to deploy the k3s cluster
- `scp -i ~/src/.ssh/pvm-ubuntu-cloud ubuntu@192.168.68.201:~/.kube/config ~/.kube/config`
- Then may need to install kubectl commands on the dev machine
- `echo 'alias k="kubectl"' >> ~/.bashrc`
- `source ~/.bashrc`
- The k3s cluster is then ready to use

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

Immich is a self-hosted photo and video backup solution. This directory contains the Kubernetes configuration files for deploying Immich.

### Prerequisites

- Kubernetes cluster with NFS CSI driver support
- Helm 3.x
- NFS server accessible from the cluster
- Domain name for ingress (optional)

### Configuration

#### 1. Configure Secrets

Before deploying, you need to create the secrets file with your actual values:

```bash
# Copy the template
cp immich/secrets.yaml.template immich/secrets.yaml

# Edit the secrets file with your actual values
nano immich/secrets.yaml
```

Replace the following placeholder values in `secrets.yaml`:

- `CHANGE_ME_DB_PASSWORD`: Strong password for PostgreSQL database
- `CHANGE_ME_JWT_SECRET`: Secure random key for JWT authentication (generate with `openssl rand -base64 32`)

#### 2. Update Configuration Files

Update the following files with your actual values:

- `immich/values.yaml`: Replace `CHANGE_ME_DOMAIN_NAME` with your domain name (e.g., `immich.example.com`)
- `immich/pvc.yaml`: Replace `CHANGE_ME_NFS_SERVER_IP` with your NFS server IP

### Installation Steps

1. Create Immich namespace:
   ```bash
   kubectl create namespace immich
   ```

2. Apply secrets:
   ```bash
   kubectl apply -f immich/secrets.yaml
   ```

3. Apply NFS PVCs:
   ```bash
   kubectl apply -f immich/pvc.yaml
   ```

4. Deploy PostgreSQL:
   ```bash
   kubectl apply -f immich/postgres.yaml
   ```

5. Deploy Immich using Helm:
   ```bash
   helm repo add immich https://immich-app.github.io/immich-helm
   helm repo update
   helm upgrade --install immich immich/immich -f immich/values.yaml -n immich
   ```

6. Apply the strategic merge patch for additional volumes:
   ```bash
   kubectl patch deployment immich-server -n immich --patch-file immich/patch.yaml
   ```

### Upgrading

To upgrade Immich:

```bash
# Update Helm repository
helm repo update

# Upgrade the release
helm upgrade immich immich/immich -f immich/values.yaml -n immich
```

### Removal Steps

1. Uninstall Helm release:
   ```bash
   helm uninstall immich -n immich
   ```

2. Remove PVCs:
   ```bash
   kubectl delete pvc --all -n immich
   ```

3. Delete released PVs if needed

4. (Optional) Remove namespace:
   ```bash
   kubectl delete namespace immich
   ```

## Contributing

This is a personal homelab project. For issues and improvements, please create GitHub issues.

## License
