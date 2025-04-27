packer {
  required_plugins {
    proxmox-iso = {
      source  = "github.com/hashicorp/proxmox"
      version = ">= 1.2.2"
    }
  }
}

#──────────────────────────────────────────────────────────────────────────────
# Proxmox-ISO builders (one per node)
#──────────────────────────────────────────────────────────────────────────────
source "proxmox-iso" "talos" {
  for_each                 = toset(var.proxmox_nodes)
  proxmox_url              = var.proxmox_api_url
  username                 = var.proxmox_api_token_id
  token                    = var.proxmox_api_token_secret
  node                     = each.value
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
    disk_size    = var.disk_size # must be >= raw image size
    io_thread    = true
    cache_mode   = "writethrough"
  }

  memory   = 2048
  vm_id    = var.template_vmids[each.value]
  cores    = var.cores
  cpu_type = var.cpu_type
  sockets  = 1

  # Cloud-init disk (required by plugin, ignored by Talos)
  cloudinit {
    storage_pool = var.cloudinit_storage_pool
  }

  ssh_username = "root"
  ssh_password = "packer"
  ssh_timeout  = "15m"

  template_name        = "talos-${var.talos_version}-template"
  template_description = "Talos ${var.talos_version} (image factory)"
  boot_wait            = "45s"

  boot_command = [
    "<enter><wait45s>", # wait at ISO boot prompt
    "passwd<enter><wait>packer<enter><wait>packer<enter>"
  ]
}

#──────────────────────────────────────────────────────────────────────────────
# Build block: replace the placeholder disk with Talos raw image
#──────────────────────────────────────────────────────────────────────────────

build {
  sources = [
    for s in source.proxmox-iso.talos : s.id
  ]

  provisioner "shell" {
    inline = [
      "echo '[1/3] Downloading Talos image from factory…'",
      "curl -sSL '${local.image_url}' | zstd -d -c | dd of=/dev/sda bs=4M conv=fsync status=progress",
      "echo '[2/3] Syncing…'; sync",
      "echo '[3/3] Syncing…'; sync"
    ]
  }
}
