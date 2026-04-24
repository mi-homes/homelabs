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


## GitOps bases (public Helm values and manifests)

These paths are referenced by Argo CD Applications in `homelabs-private` (private repo). Secret management (Vault, External Secrets Operator) is documented at [https://mi-homes.org/docs/](https://mi-homes.org/docs/); only non-secret wiring lives here.

| Path | Purpose |
|------|---------|
| `apps/pihole/` | Pi-hole manifests including `namespace.yaml` (Git-managed Namespace; use with Argo `CreateNamespace=true` and `prune` as usual) |
| `plex/` | Plex Helm `values.yaml`; `manifests/` for Namespace, config PVC (`plex-config-pvc`; often **local-path** to match existing k3s claims), `ExternalSecret`, and `kustomization.yaml` |

Per-cluster overrides for Plex live in `homelabs-private` at `clusters/home-prod/overlays/plex/values.yaml`. The **`website`** Namespace lives in `homelabs-private` at `clusters/home-prod/overlays/website/namespace.yaml` alongside the overlay `secret.yaml`.

**Namespaces in Git:** Each app keeps a `Namespace` object in Git so Argo CD **prune** stays predictable and the namespace is not only created by `CreateNamespace=true`. Keep `CreateNamespace=true` on Applications so the namespace is still created if needed during sync.

### Kubernetes compatibility (Argo CD target cluster)

The home cluster runs **k3s v1.30.2+k3s2** (Kubernetes **1.30**). Pin and upgrade chart versions in `homelabs-private` Argo `Application` manifests; check each chart’s `kubeVersion` before bumping:

| Chart | Chart version (pinned) | App version | `kubeVersion` in Chart.yaml |
|-------|-------------------------|-------------|------------------------------|
| `plex/plex-media-server` | 1.5.0 | 1.43.0 | *(not set by upstream)* |

Kubernetes 1.30 satisfies the published lower bounds. Vault and External Secrets Operator chart compatibility is covered in the [site docs](https://mi-homes.org/docs/). To re-check after changing versions:

```bash
helm show chart plex/plex-media-server --version <chart-version>
```

## Contributing

This is a personal homelab project. For issues and improvements, please create GitHub issues.

## License

