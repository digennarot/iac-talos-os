variable "proxmox_api_url" {
  description = "URL API di Proxmox"
  type        = string
}

variable "proxmox_api_token_id" {
  description = "Proxmox API Token ID"
  type        = string
}

variable "proxmox_api_token_secret" {
  description = "Proxmox API Token Secret"
  type        = string
  sensitive   = true
}

variable "nodes" {
  description = "Mappa dei nodi da creare (master o worker)"
  type = map(object({
    vm_id                = number
    node_name            = string
    node_cpu_cores       = string
    node_memory          = number
    node_ipconfig        = string
    node_disk            = string
    additional_node_disk = optional(string)
  }))
}

variable "shared_storage_id" {
  description = "ID dello storage condiviso (ZFS)"
  type        = string
}

variable "template_vmids" {
  description = "Mappa Proxmox node → VMID per il Talos template"
  type        = map(number)
}

variable "target_node" {
  description = "Proxmox node su cui clonare (es. pve1)"
  type        = string
}

variable "clone" {
  description = "Nome del template o VMID da clonare"
  type        = string
}

# Opzionali con default per togliere hardcoding
variable "full_clone" {
  description = "Esegue full clone del template"
  type        = bool
  default     = true
}

variable "onboot" {
  description = "Avvia VM al boot"
  type        = bool
  default     = true
}

variable "boot_order" {
  description = "Stringa ordine di boot"
  type        = string
  default     = "order=scsi1;scsi0"
}

variable "agent" {
  description = "Abilita QEMU guest agent"
  type        = number
  default     = 1
}

variable "agent_timeout" {
  description = "Timeout del guest agent"
  type        = number
  default     = 90
}

variable "cpu_type" {
  description = "Tipo CPU da esporre"
  type        = string
  default     = "host"
}

variable "sockets" {
  description = "Numero di socket CPU"
  type        = number
  default     = 1
}

variable "scsihw" {
  description = "Controller SCSI da usare"
  type        = string
  default     = "virtio-scsi-single"
}

variable "disk_format" {
  description = "Formato del disco principale"
  type        = string
  default     = "raw"
}

variable "cloudinit_slot" {
  description = "Slot per il disco cloud-init"
  type        = string
  default     = "scsi1"
}

variable "bridge" {
  description = "Bridge di rete da usare"
  type        = string
  default     = "vmbr0"
}
