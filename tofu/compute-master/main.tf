resource "proxmox_vm_qemu" "talos_masters" {
  for_each = local.selected_master_nodes

  name        = each.value.node_name
  target_node = local.target_proxmox_node
  vmid        = each.value.vm_id
  clone       = each.value.clone_target
  onboot      = true
  boot        = "order=scsi1;scsi0"

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
    storage  = "local-zfs"
    format   = "raw"
    iothread = true
  }

  disk {
    slot    = "scsi1"
    type    = "cloudinit"
    storage = "local-zfs"
  }

  network {
    id     = 0
    model  = "virtio"
    bridge = "vmbr0"
  }

  ipconfig0 = each.value.node_ipconfig
  os_type   = "cloud-init"
}
