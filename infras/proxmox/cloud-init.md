Download the image from https://cloud-images.ubuntu.com/ (tested on https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img)

Create and configure a new VM via CLI on the host
```bash
qm create 5000 --memory 4096 --core 1 --name ubuntu-cloud --net0 virtio,bridge=vmbr0
cd /var/lib/vz/template/iso/ # or to the location where the image was downloaded
qm importdisk 5000 <IMAGE NAME> <YOUR STORAGE HERE>
qm set 5000 --scsihw virtio-scsi-pci --scsi0 <YOUR STORAGE HERE>:5000/vm-5000-disk-0.raw
qm set 5000 --ide2 <YOUR STORAGE HERE>:cloudinit
qm set 5000 --boot c --bootdisk scsi0
qm set 5000 --serial0 socket --vga serial0
qm disk resize 5000 scsi0 32G
```

Go to the UI, and set `User`, `Password`, `SSH public key`, `IP Config` = DHCP

Convert the VM to template

Deploy new VMs by cloning the template (full clone) or using Terraform
