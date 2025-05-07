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

  # 2) Build the exact map we pass into the compute module,
  #    merging in the mac_address that you declared in clusters.auto.tfvars
  selected_master_nodes = {
    for name, node in local.selected.masters :
    name => merge(node, {
      mac_address = node.mac_address
    })
  }

  selected_worker_nodes = {
    for name, node in local.selected.workers :
    name => merge(node, {
      mac_address = node.mac_address
    })
  }

  # 3) Pick the first Proxmox host from the list
  target_node = local.selected.target_nodes[0]
}
