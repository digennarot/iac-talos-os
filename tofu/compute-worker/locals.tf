locals {
  selected              = var.clusters[var.cluster_id]
  selected_worker_nodes = local.selected.workers
  target_proxmox_nodes  = local.selected.target_nodes
  shared_storage        = var.shared_storage_id
  target_node           = var.target_nodes[0]
}
