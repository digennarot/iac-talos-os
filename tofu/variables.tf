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


variable "cluster_id" {
  description = "ID del cluster da deployare (a o b o c)"
  type        = string
  validation {
    condition     = contains(["a", "b"], var.cluster_id)
    error_message = "Il valore deve essere 'a' o 'b'."
  }
}

variable "cluster_a_master_nodes" {
  type = map(object({
    node_name      = string
    vm_id          = number
    clone_target   = string
    node_cpu_cores = number
    node_memory    = number
    node_disk      = string
    node_ipconfig  = string
  }))
}

variable "cluster_a_worker_nodes" {
  type = map(object({
    node_name      = string
    vm_id          = number
    clone_target   = string
    node_cpu_cores = number
    node_memory    = number
    node_disk      = string
    node_ipconfig  = string
  }))
}

variable "cluster_b_master_nodes" {
  type = map(object({
    node_name      = string
    vm_id          = number
    clone_target   = string
    node_cpu_cores = number
    node_memory    = number
    node_disk      = string
    node_ipconfig  = string
  }))
}

variable "cluster_b_worker_nodes" {
  type = map(object({
    node_name      = string
    vm_id          = number
    clone_target   = string
    node_cpu_cores = number
    node_memory    = number
    node_disk      = string
    node_ipconfig  = string
  }))
}

variable "cluster_c_master_nodes" {
  type = map(object({
    node_name      = string
    vm_id          = number
    clone_target   = string
    node_cpu_cores = number
    node_memory    = number
    node_disk      = string
    node_ipconfig  = string
  }))
}

variable "cluster_c_worker_nodes" {
  type = map(object({
    node_name      = string
    vm_id          = number
    clone_target   = string
    node_cpu_cores = number
    node_memory    = number
    node_disk      = string
    node_ipconfig  = string
  }))
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
