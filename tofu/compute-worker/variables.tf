variable "proxmox_node" {
  description = "Nome del nodo Proxmox su cui creare la VM"
  type        = string
}

variable "proxmox_api_url" {
  description = "URL dell'API di Proxmox (es. https://proxmox.local:8006/api2/json)"
  type        = string
}

variable "proxmox_api_token_id" {
  description = "ID del token API (es. terraform@pve!mytoken)"
  type        = string
}

variable "proxmox_api_token_secret" {
  description = "Segreto associato al token API"
  type        = string
  sensitive   = true
}

variable "clusters" {
  description = "Mappa clusters dal root"
  type        = map(any)
}

variable "cluster_id" {
  description = "ID del cluster da deployare"
  type        = string
}

variable "shared_storage_id" {
  description = "Storage condiviso (ZFS) per i template e dischi"
  type        = string
}
variable "nodes" {
  description = "Mappa dei nodi da creare (master o worker)"
  type = map(object({
    vm_id                = number
    node_name            = string
    clone_target         = string
    node_cpu_cores       = string
    node_memory          = number
    node_ipconfig        = string
    node_disk            = string
    additional_node_disk = optional(string)
  }))
}
