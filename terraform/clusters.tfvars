# (Opzionale) Override dei nodi master per il cluster B
cluster_b_master_nodes = {
  "0" = {
    vm_id          = 211
    node_name      = "talos-b-master-01"
    clone_target   = "talos-v1.9.5-cloud-init-template"
    node_cpu_cores = "2"
    node_memory    = 4096
    node_ipconfig  = "ip=192.168.1.171/24,gw=192.168.1.1"
    node_disk      = "20"
  }
}

# (Opzionale) Override dei nodi worker per il cluster B
cluster_b_worker_nodes = {
  "1" = {
    vm_id                = 311
    node_name            = "talos-b-worker-01"
    clone_target         = "talos-v1.9.5-cloud-init-template"
    node_cpu_cores       = "1"
    node_memory          = 2048
    node_ipconfig        = "ip=192.168.1.181/24,gw=192.168.1.1"
    node_disk            = "16"
    additional_node_disk = "64"
  }
}
