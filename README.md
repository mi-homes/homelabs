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

## Plex and NFS CSI Setup

### Configuration

#### Environment Variables

Copy the example configuration file and update it with your values:

```bash
cp .env.example .env
```

Edit `.env` with your actual values:

- `SYNOLOGY_NAS_IP`: Your Synology NAS IP address
- `SYNOLOGY_NAS_SHARE`: NFS share path on your NAS
- `PLEX_CLAIM_TOKEN`: Get from https://www.plex.tv/claim/ (valid for 4 minutes)
- `PLEX_LOADBALANCER_IP`: Your desired LoadBalancer IP
- `PLEX_SERVER_NAME`: Your Plex server name

#### Plex Installation Steps

1. Install NFS CSI Driver:
   ```bash
   cd kubernetes/nfs-csi
   ./install.sh
   ```

2. Create Plex namespace:
   ```bash
   kubectl create namespace plex
   ```

3. Apply Plex PVCs:
   ```bash
   kubectl apply -f plex/pvc.yaml
   ```

4. Deploy Plex:
   ```bash
   kubectl apply -f plex/deployment.yaml
   ```

## Contributing

This is a personal homelab project. For issues and improvements, please create GitHub issues.

## License
