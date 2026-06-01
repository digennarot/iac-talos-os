variable "proxmox_api_url" {
  description = "URL API di Proxmox"
  type        = string
}

variable "proxmox_api_token_id" {
  description = "Token ID per l’API Proxmox"
  type        = string
  sensitive   = true
}

variable "proxmox_api_token_secret" {
  description = "Secret del token Proxmox"
  type        = string
  sensitive   = true


}



variable "clusters" {
  description = "Mappa di configurazione per tutti i cluster"
  type = map(object({
    masters = map(object({
      vm_id                = number
      node_name            = string
      node_cpu_cores       = string
      node_memory          = number
      node_disk            = string
      additional_node_disk = optional(string)
      patches              = optional(list(string))
       mac_address          = string


    }))
    workers = map(object({
      vm_id                = number
      node_name            = string
      node_cpu_cores       = string
      node_memory          = number
      node_disk            = string
      additional_node_disk = optional(string)
      patches              = optional(list(string))
       mac_address          = string


    }))
    target_nodes = list(string)
    vip          = string # ✅ Obbligatorio
    pod_net      = string # ✅ Obbligatorio
    svc_net      = string # ✅ Obbligatorio
  }))
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
