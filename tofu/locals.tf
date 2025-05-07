locals {
  # 1) every invocation knows its workspace name
  workspace = terraform.workspace

  # 2) grab the first cluster key (e.g. “a”)
  default_cluster = keys(var.clusters)[0]

  # 3) if workspace == one of “a”,“b”,“c”, use it;
  #    otherwise fall back to the first key in var.clusters
  selected = lookup(
    var.clusters,
    local.workspace,
    var.clusters[local.default_cluster]
  )

  selected_master_nodes = local.selected.masters
  selected_worker_nodes = local.selected.workers

  # pick the first Proxmox node in the target list
  target_node = local.selected.target_nodes[0]

  /*   # Aggiungi mac_addr ai nodi
  master_nodes_with_mac = zipmap(
    keys(local.selected_cluster.masters),
    [for idx, node in values(local.selected_cluster.masters) : merge(node, {
      mac_addr = element(module.masters.mac_addrs, idx)
    })]
  )

  worker_nodes_with_mac = zipmap(
    keys(local.selected_cluster.workers),
    [for idx, node in values(local.selected_cluster.workers) : merge(node, {
      mac_addr = element(module.workers.mac_addrs, idx)
    })]
  )
 */
}
