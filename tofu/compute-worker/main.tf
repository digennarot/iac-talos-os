resource "proxmox_vm_qemu" "talos_workers" {
  for_each    = local.selected_worker_nodes
  name        = each.value.node_name
  target_node = local.target_node
  vmid        = each.value.vm_id

  clone = var.template_name # <- your tfvar “talos-v1.9.5-cloud-init-template”

  full_clone = true
  onboot     = true
  boot       = "order=scsi1;scsi0"

  agent    = 1
  cpu_type = "host"
  sockets  = 1
  cores    = each.value.node_cpu_cores
  memory   = each.value.node_memory
  scsihw   = "virtio-scsi-single"

  disk {
    slot     = "scsi0"
    size     = each.value.node_disk
    type     = "disk"
    storage  = local.shared_storage
    format   = "raw"
    iothread = true
  }

  disk {
    slot    = "scsi1"
    type    = "cloudinit"
    storage = local.shared_storage
  }

  network {
    id     = 0
    model  = "virtio"
    bridge = "vmbr0"
  }

  ipconfig0 = each.value.node_ipconfig
  os_type   = "cloud-init"

  depends_on = [
    # refer to the remote null_resource via an input var
    var.template_ready
  ]

}
