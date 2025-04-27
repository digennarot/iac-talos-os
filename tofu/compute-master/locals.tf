# compute-master/locals.tf
locals {
  # prende direttamente la configurazione per il cluster selezionato
  selected = var.clusters[var.cluster_id]

  selected_master_nodes = local.selected.masters
  target_proxmox_nodes  = local.selected.target_nodes
  shared_storage        = var.shared_storage_id
  target_node           = var.target_nodes[0]

}
