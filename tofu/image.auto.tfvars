# image.auto.tfvars

image = {
  # schematic in linea (puoi anche usare file("${path.module}/image/schematic.yaml"))
  schematic = <<EOF
customization:
  systemExtensions:
    officialExtensions:
      - siderolabs/intel-ucode
      - siderolabs/qemu-guest-agent
EOF

  version = "v1.9.5"
  # proxmox_datastore deve corrispondere a shared_storage_id o a var.image.proxmox_datastore
  proxmox_datastore = "zfs-shared"

  platform = "nocloud"
  arch     = "amd64"
}

nodes = {
  # mappa host → { host_node, update }
  pve1 = { host_node = "pve1", update = false }
  pve2 = { host_node = "pve2", update = false }
  pve3 = { host_node = "pve3", update = false }
}
