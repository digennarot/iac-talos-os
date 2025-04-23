packer {
  required_plugins {
    proxmox-iso = {
      version = ">= 1.2.2"
      source  = "github.com/hashicorp/proxmox"
    }
  }
}

variable "proxmox_url"       { type = string }
variable "proxmox_token_id"  { type = string }
variable "proxmox_token_secret" { type = string }
variable "proxmox_node"      { type = string, default = "pve1" }
variable "template_vmid"     { type = number, default = 9700 }
variable "talos_version"     { type = string, default = "v1.9.5" }
variable "image_factory_url" { type = string, default = "https://factory.talos.dev" }
variable "schematic_file"    { type = string, default = "${path.module}/schematic.yaml" }

source "proxmox-iso" "talos" {
  proxmox_url              = var.proxmox_url
  username                 = var.proxmox_token_id
  token                    = var.proxmox_token_secret
  node                     = var.proxmox_node
  insecure_skip_tls_verify = true

  boot_iso {
    type     = "scsi"
    iso_file = "local:iso/archlinux-2025.03.01-x86_64.iso"
    unmount  = true
  }

  vm_id    = var.template_vmid
  memory   = 2048
  cores    = 2
  cpu_type = "host"
  sockets  = 1

  disk {
    size         = "1500M"
    format       = "raw"
    storage_pool = "zfs-shared"
    cache_mode   = "writethrough"
    io_thread    = true
    type         = "scsi"
  }

  network_adapters {
    bridge = "vmbr0"
    model  = "virtio"
  }

  ssh_username = "root"
  ssh_password = "packer"
  ssh_timeout  = "10m"

  template_name        = "talos-${var.talos_version}-cloud-init-template"
  template_description = "Talos ${var.talos_version} via Image Factory"
  boot_wait            = "25s"
  boot_command = [
    "<enter><wait1m>"
  ]
}

build {
  sources = ["source.proxmox-iso.talos"]

  provisioner "shell-local" {
    inline = [
      # 1) POST the schematic to get the ID:
      "SCHEMATIC=$(curl -s -X POST \"${var.image_factory_url}/schematics\" \\
        --data-binary @${var.schematic_file} | jq -r .id)",

      # 2) pull & dd the Talos raw image straight into the new VM disk:
      "curl -sL \"${var.image_factory_url}/image/${SCHEMATIC}/${var.talos_version}/nocloud-amd64.raw.gz\" \\
         | gunzip -c | ssh root@${var.proxmox_node} \\
            \"dd of=/dev/sda bs=4M conv=fsync && sync\"",

      # 3) convert the VM into a template
      "ssh root@${var.proxmox_node} qm template ${var.template_vmid}"
    ]
  }
}
