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

## Contributing

This is a personal homelab project. For issues and improvements, please create GitHub issues.

## License
