# locals.tf

locals {
  # 1) Figure out which cluster we’re targeting
  workspace       = terraform.workspace
  default_cluster = keys(var.clusters)[0]
  selected        = lookup(
    var.clusters,
    local.workspace,
    var.clusters[local.default_cluster]
  )

  # 2) Build the exact map we pass into the compute module
  selected_master_nodes = local.selected.masters
  selected_worker_nodes = local.selected.workers

  # 3) Pick the first Proxmox host from the list
  target_node = local.selected.target_nodes[0]
}
