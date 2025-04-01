packer {
  required_plugins {
    proxmox = {
      version = ">= 1.2.2"
      source  = "github.com/hashicorp/proxmox"
    }
  }
}

source "proxmox-iso" "talos" {
  proxmox_url              = var.proxmox_api_url
  username                 = var.proxmox_api_token_id
  token                    = var.proxmox_api_token_secret
  node                     = var.proxmox_node
  insecure_skip_tls_verify = true

  boot_iso {
    type     = "scsi"
    iso_file = var.base_iso_file # Esempio: local:iso/archlinux-2025.03.01-x86_64.iso
    unmount  = true
  }

  scsi_controller = "virtio-scsi-single"

  network_adapters {
    bridge = "vmbr0"
    model  = "virtio"
  }

  disks {
    type         = "scsi"
    storage_pool = var.proxmox_storage
    format       = "raw"
    disk_size    = "1500M"
    io_thread    = true
    cache_mode   = "writethrough"
  }

  memory   = 2048
  vm_id    = 9700
  cores    = var.cores
  cpu_type = var.cpu_type
  sockets  = 1

  ssh_username = "root"
  ssh_password = "packer"
  ssh_timeout  = "15m"

  template_name        = "talos-${var.talos_version}-cloud-init-template"
  template_description = "Talos ${var.talos_version}, preparato via ArchLinux ISO"
  boot_wait            = "25s"
  boot_command = [
    "<enter><wait1m>",
    "passwd<enter><wait>packer<enter><wait>packer<enter>"
  ]

}

# === Blocco build Packer ===
build {
  sources = ["source.proxmox-iso.talos"]

  provisioner "shell" {
    inline = [
      "echo '[0/4] Installazione dipendenze (xz, curl)...'",
      "which xz || pacman -Sy --noconfirm xz",
      "which zstd || pacman -Sy --noconfirm zstd",
      "which curl || pacman -Sy --noconfirm curl",

      "echo '[1/4] Scarico e scrivo immagine Talos direttamente...'",
      "curl -sL ${local.image} | zstd -d -c | dd of=/dev/sda bs=4M conv=fsync status=progress",
      "sync"
    ]
  }
}