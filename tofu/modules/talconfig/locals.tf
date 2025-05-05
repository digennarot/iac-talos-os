locals {
  workspace        = terraform.workspace
  selected_cluster = var.clusters[local.workspace]

  # Estrai i MAC address dai moduli
  master_nodes_with_mac = zipmap(
    keys(selected_cluster.masters),
    [for idx, node in values(selected_cluster.masters) : merge(node, {
      mac_addr = element(module.masters.mac_addrs, idx)
    })]
  )

  worker_nodes_with_mac = zipmap(
    keys(selected_cluster.workers),
    [for idx, node in values(selected_cluster.workers) : merge(node, {
      mac_addr = element(module.workers.mac_addrs, idx)
    })]
  )

  cluster_config = {
    masters = local.master_nodes_with_mac
    workers = local.worker_nodes_with_mac
    vip     = local.selected_cluster.vip
    pod_net = local.selected_cluster.pod_net
    svc_net = local.selected_cluster.svc_net
  }
}


