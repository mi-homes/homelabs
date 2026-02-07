locals {
  template_vm_id = 9999
}

resource "proxmox_virtual_environment_vm" "cloudinit-k3s-master" {
  count     = 3
  name      = "k3s-master-0${count.index + 1}"
  node_name = "proxmox-pve-mipc"
  
  clone {
    vm_id = local.template_vm_id
    full  = true
  }
  
  cpu {
    cores   = 1
    sockets = 1
  }
  
  memory {
    dedicated = 4096
  }
  
  agent {
    enabled = false
  }

  network_device {
    bridge = "vmbr0"
    model  = "virtio"
  }

  initialization {
    hostname = "k3s-master-0${count.index + 1}"
    user_account {
      username = "ansibleuser"
      keys     = [file("~/.ssh/pvm-ubuntu-cloud.pub")]
    }
    
    ip_config {
      ipv4 {
        address = "192.168.68.20${count.index + 1}/24"
        gateway = "192.168.68.1"
      }
    }
  }

  tags = ["k3s", "master"]
}

resource "proxmox_virtual_environment_vm" "cloudinit-k3s-worker" {
  count     = 2
  name      = "k3s-worker-0${count.index + 1}"
  node_name = "proxmox-pve-mipc"
  
  clone {
    vm_id = local.template_vm_id
    full  = true
  }
  
  cpu {
    cores   = 1
    sockets = 1
  }
  
  memory {
    dedicated = 4096
  }
  
  agent {
    enabled = false
  }

  network_device {
    bridge = "vmbr0"
    model  = "virtio"
  }

  initialization {
    hostname = "k3s-worker-0${count.index + 1}"
    user_account {
      username = "ansibleuser"
      keys     = [file("~/.ssh/pvm-ubuntu-cloud.pub")]
    }
    
    ip_config {
      ipv4 {
        address = "192.168.68.21${count.index + 1}/24"
        gateway = "192.168.68.1"
      }
    }
  }

  tags = ["k3s", "worker"]
}