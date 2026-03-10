source "proxmox-iso" "talos" {
  proxmox_url              = var.proxmox_api_url
  username                 = var.proxmox_api_token_id
  token                    = var.proxmox_api_token_secret
  node                     = var.proxmox_node
  insecure_skip_tls_verify = true

  boot_iso {
    type     = "scsi"
    iso_file = var.base_iso_file
    unmount  = true
  }

  scsi_controller = "virtio-scsi-single"

  network_adapters {
    bridge = "vmbr0"
    model  = "virtio"
  }

  disks {
    type         = "scsi"
    storage_pool = var.storage_pool
    format       = "raw"
    disk_size    = var.disk_size
    io_thread    = true
    cache_mode   = "writethrough"
  }

  vm_name  = "talos-template-builder"
  memory   = var.memory
  vm_id    = var.template_vmid
  cores    = var.cores
  cpu_type = var.cpu_type
  sockets  = var.sockets

  qemu_agent         = true
  ballooning_minimum = 0

  ssh_username = "root"
  ssh_password = "packer"
  ssh_timeout  = "15m"

  cloud_init              = false
  cloud_init_storage_pool = ""

  boot_wait = "45s"

  # Set root password and configure a static IP so Packer can reach the VM
  # Replace 'ens18' with your actual interface name (check with `ip addr` in Proxmox console)
  boot_command = [
    "<enter><wait5s>",
    "passwd<enter><wait1s>packer<enter><wait1s>packer<enter>",
    "ip address add ${var.static_ip} broadcast + dev ${var.interface}<enter><wait1s>",
    "ip route add 0.0.0.0/0 via ${var.gateway} dev ${var.interface}<enter><wait1s>",
  ]

  template_name        = "talos-${var.talos_version}-qemu"
  template_description = "Talos ${var.talos_version} qemu-agent template"
}

build {
  sources = ["source.proxmox-iso.talos"]

  # Upload the schematic to Talos Image Factory
  provisioner "file" {
    destination = "/tmp/schematic.yaml"
    content     = <<EOF
customization:
    extraKernelArgs:
        - ipv6.disable=1
    systemExtensions:
        officialExtensions:
            - siderolabs/qemu-guest-agent
EOF
  }

  # Submit the schematic, fetch the resulting image ID, download the raw image,
  # and write it directly to /dev/sda
  provisioner "shell" {
    inline = [
      "echo 'Requesting build image from Talos Factory'",
      "ID=$(curl -kLX POST --data-binary @/tmp/schematic.yaml https://factory.talos.dev/schematics | grep -o '\"id\":\"[^\"]*' | sed 's/\"id\":\"//')",
      "URL=https://factory.talos.dev/image/$ID/${var.talos_version}/metal-amd64.raw.zst",
      "echo 'Downloading build image from Talos Factory: ' + $URL",
      "curl -kL \"$URL\" -o /tmp/talos.raw.zst",
      "echo 'Writing build image to disk'",
      "pv /tmp/talos.raw.zst | zstd -d | dd of=/dev/sda bs=4M status=progress conv=fsync && sync",
      "echo 'Done'",
    ]
  }
}
