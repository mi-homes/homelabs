#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   print_error "This script should not be run as root. Please run as a regular user with sudo privileges."
   exit 1
fi

print_status "Starting Ansible installation..."
sudo apt update
sudo apt install software-properties-common
sudo apt install -y ansible
sudo apt install -y sshpass

print_status "Verifying Ansible installation..."
ansible_version=$(ansible --version | head -n 1)
print_success "Ansible installed successfully: $ansible_version"

print_status "Testing connectivity to K3s cluster nodes..."
if [ -f "./inventory/my-cluster/hosts.ini" ]; then
    ansible -i ./inventory/my-cluster/hosts.ini k3s_cluster -m ping
    print_success "Connectivity test completed!"
else
    print_warning "Inventory file not found. Please run this script from the ansible directory."
fi