locals {
  clusters = var.clusters
  selected = lookup(local.clusters, var.cluster_id, null)

  selected_master_nodes = local.selected.masters
  selected_worker_nodes = local.selected.workers

  target_proxmox_nodes = local.selected.target_nodes
}
