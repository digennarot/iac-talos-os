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
  default     = "local-zfs"
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
  default     = "local:iso/archlinux-2025.03.01-x86_64.iso"
}

# === URL immagine Talos ===
locals {
  # URL ufficiale immagine raw Talos (scaricata e scritta su disco via dd)
  image = "https://factory.talos.dev/image/59611c02daecc0d88fe235aea81c87ae8dbf2f184a598ff8b4e18157e612798c/${var.talos_version}/metal-amd64.raw.zst"
}