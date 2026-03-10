variable "proxmox_api_url" {
  description = "Proxmox API URL"
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

variable "role" {
  description = "Node role: 'master' or 'worker'"
  type        = string
}

variable "nodes" {
  description = "Map of nodes to create"
  type = map(object({
    vm_id                = number
    node_name            = string
    node_cpu_cores       = string
    node_memory          = number
    node_ipconfig        = string
    node_disk            = string
    additional_node_disk = optional(string)
    mac_address          = string
  }))
}

variable "shared_storage_id" {
  description = "Shared storage ID (ZFS)"
  type        = string
}

variable "target_node" {
  description = "Proxmox node to clone onto (e.g. pve1)"
  type        = string
}

variable "clone" {
  description = "Template name or VMID to clone"
  type        = string
}

variable "full_clone" {
  description = "Perform a full clone of the template"
  type        = bool
  default     = true
}

variable "onboot" {
  description = "Start VM on host boot"
  type        = bool
  default     = true
}

variable "boot_order" {
  description = "Boot order string"
  type        = string
  default     = "order=scsi0"
}

variable "agent" {
  description = "Enable QEMU guest agent"
  type        = number
  default     = 1
}

variable "agent_timeout" {
  description = "Guest agent timeout"
  type        = number
  default     = 90
}

variable "cpu_type" {
  description = "CPU type to expose to the guest"
  type        = string
  default     = "host"
}

variable "sockets" {
  description = "Number of CPU sockets"
  type        = number
  default     = 1
}

variable "scsihw" {
  description = "SCSI controller type"
  type        = string
  default     = "virtio-scsi-single"
}

variable "disk_format" {
  description = "Primary disk format"
  type        = string
  default     = "raw"
}

variable "bridge" {
  description = "Network bridge to use"
  type        = string
  default     = "vmbr0"
}
