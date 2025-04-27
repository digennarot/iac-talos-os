# === Proxmox API ===
variable "proxmox_api_url" {
  description = "URL dell'API Proxmox (es: https://proxmox.local:8006/api2/json)"
  type        = string
}

variable "proxmox_api_token_id" {
  description = "ID del token API Proxmox (es: terraform@pve!token)"
  type        = string
}

variable "proxmox_api_token_secret" {
  description = "Segreto del token API Proxmox"
  type        = string
  sensitive   = true
}

# === Configurazione Proxmox ===
variable "proxmox_node" {
  description = "Nome del nodo Proxmox su cui verrà creata la VM"
  type        = string
}

variable "proxmox_storage" {
  description = "Storage pool Proxmox su cui verrà scritto il disco Talos (es: local-zfs, local-lvm)"
  type        = string
}

variable "cloudinit_storage_pool" {
  description = "Storage pool per il disco Cloud-Init (opzionale, non usato da Talos ma richiesto dal plugin Proxmox)"
  type        = string
  default     = "zfs-shared"
}

# === Risorse della VM ===
variable "cpu_type" {
  description = "Tipo di CPU virtuale da usare nella VM (es: host, kvm64, qemu64)"
  type        = string
  default     = "kvm64"
}

variable "cores" {
  description = "Numero di core CPU assegnati alla VM"
  type        = number
  default     = 2
}

# === Talos + ISO base ===
variable "talos_version" {
  description = "Versione di Talos da usare (usata per scaricare l'immagine raw)"
  type        = string
  default     = "v1.9.5"
}

variable "base_iso_file" {
  description = "ISO da montare come placeholder (es: ArchLinux rescue ISO)"
  type        = string
  default     = "local:iso/archlinux-2025.04.01-x86_64.iso"
}

variable "schematic_id" {
  type        = string
  description = "Talos Factory schematic ID"
}

variable "vm_id" {
  type    = number
  default = 9700
}

variable "proxmox_nodes" {
  type        = list(string)
  description = "List of Proxmox nodes to build on"
  default     = ["pve1", "pve2", "pve3"]
}

variable "template_vmids" {
  type        = map(number)
  description = "VMID to use for the Talos template on each node"
  default = {
    pve1 = 9700
    pve2 = 9701
    pve3 = 9702
  }
}

# === URL immagine Talos ===

# Compute the raw‐image URL dynamically
locals {
  image_url = "https://factory.talos.dev/image/${var.schematic_id}/${var.talos_version}/metal-amd64.raw.zst"
}
