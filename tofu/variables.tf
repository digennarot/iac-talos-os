variable "proxmox_api_url" {
  description = "Proxmox API URL"
  type        = string
}

variable "proxmox_api_token_id" {
  description = "Proxmox API Token ID"
  type        = string
  sensitive   = true
}

variable "proxmox_api_token_secret" {
  description = "Proxmox API Token Secret"
  type        = string
  sensitive   = true
}

variable "clusters" {
  description = "Map of cluster configurations"
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
      mac_address          = string
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
      mac_address          = string
    }))
    target_nodes = list(string)
    vip          = string
    pod_net      = string
    svc_net      = string
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
  description = "List of physical Proxmox nodes (e.g. pve1, pve2, pve3)"
  type        = list(string)
  default     = ["pve1", "pve2", "pve3"]
}

variable "shared_storage_id" {
  description = "Shared storage ID (ZFS) used for cloning templates and creating volumes"
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
