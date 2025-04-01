cluster_a_master_nodes = {
  "0a" = {
    vm_id          = 200
    node_name      = "${local.vm_name_prefix}-master-01"
    clone_target   = "talos-v1.9.5-cloud-init-template"
    node_cpu_cores = "2"
    node_memory    = 4096
    node_ipconfig  = "ip=192.168.0.100/24,gw=192.168.0.1"
    node_disk      = "20"
  }
}

# (Opzionale) Override dei nodi worker per il cluster B
cluster_a_worker_nodes = {
  "1a" = {
    vm_id                = 300
    node_name            = "${local.vm_name_prefix}-worker-01"
    clone_target         = "talos-v1.9.5-cloud-init-template"
    node_cpu_cores       = "1"
    node_memory          = 2048
    node_ipconfig        = "ip=192.168.0.101/24,gw=192.168.0.1"
    node_disk            = "16"
    additional_node_disk = "64"
  }
}

cluster_b_master_nodes = {
  "0b" = {
    vm_id          = 210
    node_name      = "${local.vm_name_prefix}-master-01"
    clone_target   = "talos-v1.9.5-cloud-init-template"
    node_cpu_cores = "2"
    node_memory    = 4096
    node_ipconfig  = "ip=192.168.178.100/24,gw=192.168.178.1"
    node_disk      = "20"
  }
}

# (Opzionale) Override dei nodi worker per il cluster B
cluster_b_worker_nodes = {
  "1b" = {
    vm_id                = 310
    node_name            = "${local.vm_name_prefix}-worker-01"
    clone_target         = "talos-v1.9.5-cloud-init-template"
    node_cpu_cores       = "1"
    node_memory          = 2048
    node_ipconfig        = "ip=192.168.178.101/24,gw=192.168.178.1"
    node_disk            = "16"
    additional_node_disk = "64"
  }
}
