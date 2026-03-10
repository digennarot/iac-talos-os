locals {
  workspace       = terraform.workspace
  default_cluster = keys(var.clusters)[0]
  selected = lookup(
    var.clusters,
    local.workspace,
    var.clusters[local.default_cluster]
  )

  selected_master_nodes = local.selected.masters
  selected_worker_nodes = local.selected.workers

  target_node = local.selected.target_nodes[0]
}
