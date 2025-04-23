
variable "proxmox_api_url" {
  description = "URL API di Proxmox"
  type        = string
}

variable "proxmox_api_token_id" {
  description = "Token ID per l’API Proxmox"
  type        = string
}

variable "proxmox_api_token_secret" {
  description = "Secret del token Proxmox"
  type        = string
}


variable "clusters" {
  description = "Mappa di configurazione per tutti i cluster"
  type = map(object({
    masters = map(object({
      vm_id                = number
      node_name            = string
      clone_target         = string
      node_cpu_cores       = string
      node_memory          = number
      node_ipconfig        = string
      node_disk            = string
      additional_node_disk = optional(string)
    }))
    workers = map(object({
      vm_id                = number
      node_name            = string
      clone_target         = string
      node_cpu_cores       = string
      node_memory          = number
      node_ipconfig        = string
      node_disk            = string
      additional_node_disk = optional(string)
    }))
    target_nodes = list(string)
  }))
}

variable "cluster_id" {
  description = "ID del cluster da deployare (a o b o c)"
  type        = string
  validation {
    condition     = contains(["a", "b"], var.cluster_id)
    error_message = "Il valore deve essere 'a' o 'b'."
  }
}

variable "env" {
  description = "Ambiente di deployment (es: dev, test, prod)"
  type        = string
  default     = "dev"
}

variable "proxmox_nodes" {
  description = "Lista dei nodi fisici Proxmox (es: pve1, pve2, pve3)"
  type        = list(string)
  default     = ["pve1", "pve2", "pve3"]
}
variable "shared_storage_id" {
  description = "ID dello storage condiviso (ZFS) usato per clonare i template e creare i volumi"
  type        = string
}
variable "talos" {
  type = object({
    factory_url = optional(string, "https://factory.talos.dev")
    schematic   = string
    version     = string
    storage     = string
    disk_size   = string # e.g. "1500M" or "20G"
    platform    = optional(string, "nocloud")
    arch        = optional(string, "amd64")
  })
}
variable "template_vmids" {
  description = "One VMID per node for the Talos template"
  type        = map(number)
  default = {
    pve1 = 9700
    pve2 = 9701
    pve3 = 9702
  }
}
variable "image" {
  type = object({
    schematic         = string # YAML/JSON inline o file("${path.module}/schematic.yaml")
    version           = string # es. "v1.7.5"
    update_schematic  = optional(string)
    update_version    = optional(string)
    arch              = optional(string, "amd64")
    platform          = optional(string, "nocloud")
    proxmox_datastore = optional(string, "zfs-shared")
  })
}

variable "nodes" {
  type = map(object({
    host_node = string # es. "pve1"
    update    = bool   # true per forzare re-download
  }))
}
