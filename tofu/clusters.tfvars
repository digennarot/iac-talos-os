cluster_a_master_nodes = {
  "1m-a" = {
    vm_id          = 100
    node_name      = "1m-a"
    clone_target   = "talos-v1.9.5-cloud-init-template"
    node_cpu_cores = "2"
    node_memory    = 4096
    node_ipconfig  = "ip=192.168.0.100/24,gw=192.168.0.1"
    node_disk      = "20"
  }
}

# (Opzionale) Override dei nodi worker per il cluster B
cluster_a_worker_nodes = {
  "1w-a" = {
    vm_id                = 110
    node_name            = "1w-a"
    clone_target         = "talos-v1.9.5-cloud-init-template"
    node_cpu_cores       = "1"
    node_memory          = 2048
    node_ipconfig        = "ip=192.168.0.101/24,gw=192.168.0.1"
    node_disk            = "16"
    additional_node_disk = "64"
  }
  "2w-a" = {
    vm_id                = 120
    node_name            = "2w-a"
    clone_target         = "talos-v1.9.5-cloud-init-template"
    node_cpu_cores       = "1"
    node_memory          = 2048
    node_ipconfig        = "ip=192.168.0.102/24,gw=192.168.0.1"
    node_disk            = "16"
    additional_node_disk = "64"
  }
}

cluster_b_master_nodes = {
  "1m-b" = {
    vm_id          = 200
    node_name      = "1m-b"
    clone_target   = "talos-v1.9.5-cloud-init-template"
    node_cpu_cores = "2"
    node_memory    = 4096
    node_ipconfig  = "ip=192.168.178.120/24,gw=192.168.178.1"
    node_disk      = "20"
  }
}

# (Opzionale) Override dei nodi worker per il cluster B
cluster_b_worker_nodes = {
  "1w-b" = {
    vm_id                = 210
    node_name            = "1w-b"
    clone_target         = "talos-v1.9.5-cloud-init-template"
    node_cpu_cores       = "1"
    node_memory          = 2048
    node_ipconfig        = "ip=192.168.178.121/24,gw=192.168.178.1"
    node_disk            = "16"
    additional_node_disk = "64"
  }

  "2w-b" = {
    vm_id                = 220
    node_name            = "2w-b"
    clone_target         = "talos-v1.9.5-cloud-init-template"
    node_cpu_cores       = "1"
    node_memory          = 2048
    node_ipconfig        = "ip=192.168.178.122/24,gw=192.168.178.1"
    node_disk            = "16"
    additional_node_disk = "64"
  }
}
cluster_c_master_nodes = {
  "1m-c" = {
    vm_id          = 300
    node_name      = "1m-c"
    clone_target   = "talos-v1.9.5-cloud-init-template"
    node_cpu_cores = "2"
    node_memory    = 4096
    node_ipconfig  = "ip=192.168.178.130/24,gw=192.168.178.1"
    node_disk      = "20"
  }
}


# (Opzionale) Override dei nodi worker per il cluster B
cluster_c_worker_nodes = {
  "1w-c" = {
    vm_id                = 310
    node_name            = "1w-c"
    clone_target         = "talos-v1.9.5-cloud-init-template"
    node_cpu_cores       = "1"
    node_memory          = 2048
    node_ipconfig        = "ip=192.168.178.131/24,gw=192.168.178.1"
    node_disk            = "16"
    additional_node_disk = "64"
  }

  cluster_c_worker_nodes = {
    "1w-c" = {
      vm_id                = 320
      node_name            = "2w-c"
      clone_target         = "talos-v1.9.5-cloud-init-template"
      node_cpu_cores       = "1"
      node_memory          = 2048
      node_ipconfig        = "ip=192.168.178.32/24,gw=192.168.178.1"
      node_disk            = "16"
      additional_node_disk = "64"
    }
  }
}
