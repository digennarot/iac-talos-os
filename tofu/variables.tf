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
  description = "ID del cluster da deployare (a o b)"
  type        = string
  default     = "a"
  validation {
    condition     = contains(["a", "b"], var.cluster_id)
    error_message = "Il valore deve essere 'a' o 'b'."
  }
}

variable "cluster_a_master_nodes" {
  type = map(any)
  default = {
    "0" = {
      vm_id          = 200
      node_name      = "talos-a-master-00"
      clone_target   = "talos-v1.9.5-cloud-init-template"
      node_cpu_cores = "2"
      node_memory    = 2048
      node_ipconfig  = "ip=192.168.0.170/24,gw=192.168.0.1"
      node_disk      = "12"
    }
  }
}

variable "cluster_a_worker_nodes" {
  type = map(any)
  default = {
    "1" = {
      vm_id                = 300
      node_name            = "talos-a-worker-00"
      clone_target         = "talos-v1.9.5-cloud-init-template"
      node_cpu_cores       = "1"
      node_memory          = 1024
      node_ipconfig        = "ip=192.168.0.180/24,gw=192.168.0.1"
      node_disk            = "12"
      additional_node_disk = "32"
    }
  }
}

variable "cluster_b_master_nodes" {
  type = map(any)
  default = {
    "0" = {
      vm_id          = 210
      node_name      = "talos-b-master-00"
      clone_target   = "talos-v1.9.5-cloud-init-template"
      node_cpu_cores = "2"
      node_memory    = 2048
      node_ipconfig  = "ip=192.168.1.170/24,gw=192.168.1.1"
      node_disk      = "12"
    }
  }
}

variable "cluster_b_worker_nodes" {
  type = map(any)
  default = {
    "1" = {
      vm_id                = 310
      node_name            = "talos-b-worker-00"
      clone_target         = "talos-v1.9.5-cloud-init-template"
      node_cpu_cores       = "1"
      node_memory          = 1024
      node_ipconfig        = "ip=192.168.1.180/24,gw=192.168.1.1"
      node_disk            = "12"
      additional_node_disk = "32"
    }
  }
}
