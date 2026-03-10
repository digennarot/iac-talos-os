packer {
  required_plugins {
    proxmox-iso = {
      source  = "github.com/hashicorp/proxmox"
      version = ">= 1.2.2"
    }
  }
}

variable "proxmox_api_url" {
  description = "Proxmox API URL (e.g. https://pve1:8006/api2/json)"
  type        = string
  default     = "pve"
}

variable "proxmox_api_token_id" {
  description = "Proxmox API Token ID (e.g. terraform@pve!mytoken)"
  type        = string
  default     = "terraform@pve!mytoken"
}

variable "proxmox_api_token_secret" {
  description = "Proxmox API Token Secret"
  type        = string
  sensitive   = true
  default     = "none"
}

variable "proxmox_node" {
  description = "Proxmox node on which the VM will be created"
  type        = string
  default     = "pve1"
}

variable "proxmox_storage" {
  type    = string
  default = null
}

variable "template_vmid" {
  description = "VMID for the Talos template"
  type        = number
  default     = 9700
}

variable "schematic_id" {
  description = "Talos Image Factory schematic ID"
  type        = string
  default     = "376567988ad370138ad8b2698212367b8edcb69b5fd68c80be1f2ec7d603b4ba"
}

variable "talos_version" {
  description = "Talos version to use (for template names and URLs)"
  type        = string
  default     = "v1.10.0"
}

variable "base_iso_file" {
  description = "Placeholder ISO to mount (e.g. an ArchLinux ISO)"
  type        = string
  default     = "local:iso/archlinux-2025.06.01-x86_64.iso"
}

variable "storage_pool" {
  description = "Storage pool for the primary disk"
  type        = string
  default     = "nfs-shared"
}

variable "cloudinit_storage_pool" {
  description = "Storage pool for the Cloud-Init disk"
  type        = string
  default     = "nfs-shared"
}

variable "disk_size" {
  description = "Placeholder disk size (must be >= Talos raw image size)"
  type        = string
  default     = "8G"
}

variable "memory" {
  description = "RAM for the build VM (MB)"
  type        = number
  default     = 2048
}

variable "cores" {
  description = "Number of CPU cores"
  type        = number
  default     = 2
}

variable "sockets" {
  description = "Number of CPU sockets"
  type        = number
  default     = 1
}

variable "cpu_type" {
  description = "Virtual CPU type (host, kvm64, qemu64)"
  type        = string
  default     = "host"
}

variable "static_ip" {
  type    = string
  default = "host"
}

variable "gateway" {
  type    = string
  default = "host"
}

variable "interface" {
  type    = string
  default = "eth0"
}
