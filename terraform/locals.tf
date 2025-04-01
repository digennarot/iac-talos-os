locals {
  selected_master_nodes = var.cluster_id == "a" ? var.cluster_a_master_nodes : var.cluster_b_master_nodes
  selected_worker_nodes = var.cluster_id == "a" ? var.cluster_a_worker_nodes : var.cluster_b_worker_nodes
}
