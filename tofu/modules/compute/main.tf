provider "proxmox" {
  alias               = "mod"
  pm_api_url          = var.proxmox_api_url
  pm_api_token_id     = var.proxmox_api_token_id
  pm_api_token_secret = var.proxmox_api_token_secret
  pm_tls_insecure     = true
}

resource "proxmox_vm_qemu" "nodes" {
  for_each    = var.nodes
  name        = each.value.node_name
  vmid        = each.value.vm_id
  target_node = var.target_node

  clone      = var.clone
  full_clone = var.full_clone

  onboot = var.onboot
  boot   = var.boot_order

  agent         = var.agent
  agent_timeout = var.agent_timeout
  cpu_type      = var.cpu_type
  sockets       = var.sockets
  cores         = each.value.node_cpu_cores
  memory        = each.value.node_memory
  scsihw        = var.scsihw

  disk {
    slot     = "scsi0"
    size     = each.value.node_disk
    type     = "disk"
    storage  = var.shared_storage_id
    format   = var.disk_format
    iothread = true
  }

  dynamic "disk" {
    for_each = each.value.additional_node_disk != null ? [each.value.additional_node_disk] : []
    content {
      slot    = "scsi1"
      size    = disk.value
      type    = "disk"
      storage = var.shared_storage_id
      format  = var.disk_format
    }
  }
  network {
    id     = 0
    model  = "virtio"
    bridge = var.bridge
  }

  # ←――――――――――――――――――――――――――――――
  # Pass the complete Cloud-Init network string directly:
  ipconfig0 = each.value.node_ipconfig
  # ――――――――――――――――――――――――――――――→
  
  tags = var.role

}
