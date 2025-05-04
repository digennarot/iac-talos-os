packer {
  required_plugins {
    proxmox-iso = {
      source  = "github.com/hashicorp/proxmox"
      version = ">= 1.2.2"
    }
  }
}

variable "proxmox_api_url" {
  description = "URL dell API Proxmox"
  type        = string
  default     = "pve"
}

variable "proxmox_api_token_id" {
  description = "ID del token API (es. terraform@pve!mytoken)"
  type        = string
  default     = "terraform@pve!mytoken"
}

variable "proxmox_api_token_secret" {
  description = "Segreto del token API Proxmox"
  type        = string
  sensitive   = true
  default     = "none"
}

variable "proxmox_node" {
  description = "Nome del nodo Proxmox su cui verrà creata la VM"
  type        = string
  default     = "pve1"
}

variable "proxmox_storage" {
  type    = string
  default = null
}

variable "template_vmid" {
  description = "VMID per il template Talos"
  type        = number
  default     = 9700
}

variable "schematic_id" {
  description = "ID dello schematic Talos Image Factory"
  type        = string
  default     = "376567988ad370138ad8b2698212367b8edcb69b5fd68c80be1f2ec7d603b4ba"
}

variable "talos_version" {
  description = "Versione di Talos da usare (per nomi template e URL)"
  type        = string
  default     = "v1.10.0"
}

variable "base_iso_file" {
  description = "ISO placeholder da montare (es: ArchLinux ISO)"
  type        = string
  default     = "local:iso/archlinux-2025.04.01-x86_64.iso"
}

variable "storage_pool" {
  description = "Pool di storage per il disco principale"
  type        = string
  default     = "nfs-shared"
}

variable "cloudinit_storage_pool" {
  description = "Pool di storage per il disco Cloud-Init"
  type        = string
  default     = "nfs-shared"
}

variable "disk_size" {
  description = "Dimensione del disco placeholder (>= raw image Talos)"
  type        = string
  default     = "8G"
}

variable "memory" {
  description = "Quantità di memoria RAM per la VM"
  type        = number
  default     = 2048
}

variable "cores" {
  description = "Numero di core CPU"
  type        = number
  default     = 2
}

variable "sockets" {
  description = "Numero di socket CPU"
  type        = number
  default     = 1
}

variable "cpu_type" {
  description = "Tipo di CPU virtuale (host, kvm64, qemu64)"
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

