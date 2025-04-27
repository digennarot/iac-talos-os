# clusters.tfvars

# clusters.tfvars
cluster_id        = "a"
shared_storage_id = "zfs-shared"

clusters = {
  a = {
    masters = {
      "clA-cp01" = {
        vm_id          = 100
        node_name      = "clA-cp01"
        node_cpu_cores = "2"
        node_memory    = 4096
        node_ipconfig  = "ip=192.168.0.100/24,gw=192.168.0.1"
        node_disk      = "20"
      }
      "clA-cp02" = {
        vm_id          = 101
        node_name      = "clA-cp02"
        clone_target   = "talos-v1.9.5-cloud-init-template"
        node_cpu_cores = "2"
        node_memory    = 4096
        node_ipconfig  = "ip=192.168.0.110/24,gw=192.168.0.1"
        node_disk      = "20"
      }
      "clA-cp03" = {
        vm_id          = 102
        node_name      = "clA-cp03"
        node_cpu_cores = "2"
        node_memory    = 4096
        node_ipconfig  = "ip=192.168.0.120/24,gw=192.168.0.1"
        node_disk      = "20"
      }
    }
    workers = {
      "clA-wk01" = {
        vm_id                = 110
        node_name            = "clA-wk01"
        clone_target         = "talos-v1.9.5-cloud-init-template"
        node_cpu_cores       = "1"
        node_memory          = 2048
        node_ipconfig        = "ip=192.168.0.101/24,gw=192.168.0.1"
        node_disk            = "16"
        additional_node_disk = "64"
      }
      "clA-wk02" = {
        vm_id                = 120
        node_name            = "clA-wk02"
        node_cpu_cores       = "1"
        node_memory          = 2048
        node_ipconfig        = "ip=192.168.0.102/24,gw=192.168.0.1"
        node_disk            = "16"
        additional_node_disk = "64"
      }
      "clA-wk03" = {
        vm_id                = 130
        node_name            = "clA-wk03"
        node_cpu_cores       = "1"
        node_memory          = 2048
        node_ipconfig        = "ip=192.168.0.103/24,gw=192.168.0.1"
        node_disk            = "16"
        additional_node_disk = "64"
      }
    }
    target_nodes = ["pve1"]
  }

  b = {
    masters = {
      "clB-cp01" = {
        vm_id          = 200
        node_name      = "clB-cp01"
        node_cpu_cores = "2"
        node_memory    = 4096
        node_ipconfig  = "ip=192.168.178.120/24,gw=192.168.178.1"
        node_disk      = "20"
      }
      "clB-cp02" = {
        vm_id          = 201
        node_name      = "clB-cp02"
        node_cpu_cores = "2"
        node_memory    = 4096
        node_ipconfig  = "ip=192.168.178.121/24,gw=192.168.178.1"
        node_disk      = "20"
      }
      "clB-cp03" = {
        vm_id          = 202
        node_name      = "clB-cp03"
        node_cpu_cores = "2"
        node_memory    = 4096
        node_ipconfig  = "ip=192.168.178.122/24,gw=192.168.178.1"
        node_disk      = "20"
      }
    }
    workers = {
      "clB-wk01" = {
        vm_id                = 210
        node_name            = "clB-wk01"
        node_cpu_cores       = "1"
        node_memory          = 2048
        node_ipconfig        = "ip=192.168.178.123/24,gw=192.168.178.1"
        node_disk            = "16"
        additional_node_disk = "64"
      }
      "clB-wk02" = {
        vm_id                = 220
        node_name            = "clB-wk02"
        node_cpu_cores       = "1"
        node_memory          = 2048
        node_ipconfig        = "ip=192.168.178.124/24,gw=192.168.178.1"
        node_disk            = "16"
        additional_node_disk = "64"
      }
      "clB-wk03" = {
        vm_id                = 230
        node_name            = "clB-wk03"
        node_cpu_cores       = "1"
        node_memory          = 2048
        node_ipconfig        = "ip=192.168.178.125/24,gw=192.168.178.1"
        node_disk            = "16"
        additional_node_disk = "64"
      }
    }
    target_nodes = ["pve2"]
  }

  c = {
    masters = {
      "clC-cp01" = {
        vm_id          = 300
        node_name      = "clC-cp01"
        node_cpu_cores = "2"
        node_memory    = 4096
        node_ipconfig  = "ip=192.168.178.130/24,gw=192.168.178.1"
        node_disk      = "20"
      }
      "clC-cp02" = {
        vm_id          = 301
        node_name      = "clC-cp02"
        node_cpu_cores = "2"
        node_memory    = 4096
        node_ipconfig  = "ip=192.168.178.131/24,gw=192.168.178.1"
        node_disk      = "20"
      }
      "clC-cp03" = {
        vm_id          = 302
        node_name      = "clC-cp03"
        node_cpu_cores = "2"
        node_memory    = 4096
        node_ipconfig  = "ip=192.168.178.132/24,gw=192.168.178.1"
        node_disk      = "20"
      }
    }
    workers = {
      "clC-wk01" = {
        vm_id                = 310
        node_name            = "clC-wk01"
        node_cpu_cores       = "1"
        node_memory          = 2048
        node_ipconfig        = "ip=192.168.178.133/24,gw=192.168.178.1"
        node_disk            = "16"
        additional_node_disk = "64"
      }
      "clC-wk02" = {
        vm_id                = 320
        node_name            = "clC-wk02"
        node_cpu_cores       = "1"
        node_memory          = 2048
        node_ipconfig        = "ip=192.168.178.134/24,gw=192.168.178.1"
        node_disk            = "16"
        additional_node_disk = "64"
      }
      "clC-wk03" = {
        vm_id                = 330
        node_name            = "clC-wk03"
        node_cpu_cores       = "1"
        node_memory          = 2048
        node_ipconfig        = "ip=192.168.178.135/24,gw=192.168.178.1"
        node_disk            = "16"
        additional_node_disk = "64"
      }
    }
    target_nodes = ["pve3"]
  }
}
