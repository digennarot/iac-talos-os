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

variable "talos_version" {
  type    = string
  default = "1.10.0"
}

variable "kubernetes_version" {
  type    = string
  default = "1.33.0"
}

variable "clusters" {
  description = "Mappa di configurazione per tutti i cluster"
  type = map(object({
    masters = map(object({
      vm_id                = number
      node_name            = string
      node_cpu_cores       = string
      node_memory          = number
      node_ipconfig        = string
      node_disk            = string
      additional_node_disk = optional(string)
      patches              = optional(list(string))
      mac_addr             = optional(string)


    }))
    workers = map(object({
      vm_id                = number
      node_name            = string
      node_cpu_cores       = string
      node_memory          = number
      node_ipconfig        = string
      node_disk            = string
      additional_node_disk = optional(string)
      patches              = optional(list(string))
      mac_addr             = optional(string)


    }))
    target_nodes = list(string)
    vip          = string # ✅ Obbligatorio
    pod_net      = string # ✅ Obbligatorio
    svc_net      = string # ✅ Obbligatorio
  }))
}

variable "minio_access_key" {
  type      = string
  default   = "minioadmin"
  sensitive = true

}

variable "minio_secret_key" {
  type      = string
  default   = "minioadmin"
  sensitive = true
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


variable "global_patches" {
  default = [
    <<-EOT
    machine:
      network:
        nameservers:
          - 1.1.1.1
          - 1.0.0.1
    EOT
  ]
}

variable "control_plane_patches" {
  default = [
    <<-EOT
    cluster:
      controllerManager:
        extraArgs:
          bind-address: 0.0.0.0
    EOT
  ]
}

variable "schematic_name" {
  type    = string
  default = "metal"
}

variable "schematic_id" {
  type    = string
  default = "3c1083e58d189c9e3b7800351a5144d2da0ed30813eeee087d26b8dd8ffcfb98"
}
