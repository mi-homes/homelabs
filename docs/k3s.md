# k3s Installation Guide

## Overview

k3s is a lightweight Kubernetes distribution designed for resource-constrained environments. This guide documents the installation and configuration process.

## Installation

### Install k3s

Run the official installation script:

```bash
sudo curl -sfL https://get.k3s.io | sh -
```

This will:
- Download and install k3s to `/usr/local/bin/k3s`
- Create systemd service at `/etc/systemd/system/k3s.service`
- Enable and start the k3s service
- Create symlinks for `kubectl`, `crictl`, and `ctr` in `/usr/local/bin/`

### Verify Installation

Check k3s version:

```bash
k3s --version
```

Verify the service is running:

```bash
sudo systemctl status k3s
```

Or check running processes:

```bash
ps aux | grep k3s | grep -v grep
```

## Configure kubectl Access

After installation, `kubectl` may fail with permission errors because it tries to read `/etc/rancher/k3s/k3s.yaml` which is owned by root (permissions: `600`). Additionally, since `kubectl` is a symlink to `k3s`, it defaults to checking `/etc/rancher/k3s/k3s.yaml` before `~/.kube/config`.

### Solution

1. Copy the kubeconfig to your home directory:

```bash
sudo mkdir -p ~/.kube
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
sudo chown $USER:$USER ~/.kube/config
chmod 600 ~/.kube/config
```

2. Set the `KUBECONFIG` environment variable:

Add to `~/.bashrc` (or your shell configuration file):

```bash
export KUBECONFIG=~/.kube/config
```

Then reload your shell configuration:

```bash
source ~/.bashrc
```

#### Another option: Configure k3s at Installation (Future Reference)

If reinstalling, you can configure k3s to write the config with different permissions:

```bash
sudo curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--write-kubeconfig-mode 644" sh -
```

Or to make it readable by a specific group:

```bash
sudo curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--write-kubeconfig-group <group-name>" sh -
```

### Verify kubectl Access

Test kubectl connectivity:

```bash
kubectl get nodes
```

## Additional Commands

### Check Cluster Status

```bash
kubectl get nodes
kubectl get pods --all-namespaces
kubectl cluster-info
```

### Service Management

```bash
sudo systemctl start k3s
sudo systemctl stop k3s
sudo systemctl restart k3s
sudo systemctl status k3s
```

### Uninstall k3s

If you need to remove k3s:

```bash
sudo /usr/local/bin/k3s-uninstall.sh
```

## Troubleshooting

### Permission Denied Errors

If you see errors like:
```
error: error loading config file "/etc/rancher/k3s/k3s.yaml": open /etc/rancher/k3s/k3s.yaml: permission denied
```

Ensure you've:
1. Copied the config file to `~/.kube/config` with proper ownership
2. Set `KUBECONFIG=~/.kube/config` in your shell configuration

### kubectl Still Using Wrong Config

If `kubectl` still tries to use `/etc/rancher/k3s/k3s.yaml`, explicitly set the config:

```bash
export KUBECONFIG=~/.kube/config
kubectl get nodes
```

Or use the `--kubeconfig` flag:

```bash
kubectl --kubeconfig ~/.kube/config get nodes
```

## Notes

- k3s uses containerd as the container runtime
- The kubeconfig file contains cluster certificates and connection information
- k3s runs as a systemd service and starts automatically on boot
- All k3s data is stored in `/var/lib/rancher/k3s/`
