variable "proxmox_api_url" {
  type = string
}

variable "proxmox_api_token_id" {
  type = string
}

variable "proxmox_api_token_secret" {
  type = string
}

variable "proxmox_node" {
  type = string
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
