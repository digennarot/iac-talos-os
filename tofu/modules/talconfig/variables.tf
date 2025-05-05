variable "clusters" {
  type = map(object({
    masters = map(object({
      node_name            = string
      node_ipconfig        = string
      node_disk            = string
      additional_node_disk = optional(string)
      patches              = optional(list(string))
    }))
    workers = map(object({
      node_name            = string
      node_ipconfig        = string
      node_disk            = string
      additional_node_disk = optional(string)
      patches              = optional(list(string))
    }))
    target_nodes = list(string)
    vip          = string # ✅ Obbligatorio
    pod_net      = string # ✅ Obbligatorio
    svc_net      = string # ✅ Obbligatorio
  }))
}

variable "talos_version" {
  type = string
}

variable "kubernetes_version" {
  type = string
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

variable "shared_storage_id" {
  type = string
}

variable "schematic_name" {
  type    = string
  default = "metal"
}


variable "schematic_id" {
  type    = string
  default = "3c1083e58d189c9e3b7800351a5144d2da0ed30813eeee087d26b8dd8ffcfb98"
}


variable "masters" {
  type = list(object({
    node_name            = string
    node_ipconfig        = string
    node_disk            = string
    additional_node_disk = optional(string)
    patches              = optional(list(string))
    mac_addr             = optional(string)
  }))
}

variable "workers" {
  type = list(object({
    node_name            = string
    node_ipconfig        = string
    node_disk            = string
    additional_node_disk = optional(string)
    patches              = optional(list(string))
    mac_addr             = optional(string)
  }))
}