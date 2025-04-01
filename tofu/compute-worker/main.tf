resource "proxmox_vm_qemu" "talos" {
  for_each = var.nodes

  name        = each.value.node_name
  target_node = var.proxmox_node
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

  # Disco principale
  disk {
    slot     = "scsi0"
    size     = each.value.node_disk
    type     = "disk"
    storage  = "local-zfs"
    format   = "raw"
    iothread = true
  }

  # Disco cloud-init
  disk {
    slot    = "scsi1"
    type    = "cloudinit"
    storage = "local-zfs"
  }

  # Disco addizionale (opzionale)
  dynamic "disk" {
    for_each = contains(keys(each.value), "additional_node_disk") ? [each.value.additional_node_disk] : []
    content {
      slot     = "scsi2"
      size     = disk.value
      type     = "disk"
      storage  = "local-zfs"
      format   = "raw"
      iothread = true
    }
  }

  network {
    id     = 0
    model  = "virtio"
    bridge = "vmbr0"
  }

  ipconfig0 = each.value.node_ipconfig
  os_type   = "cloud-init"
}
