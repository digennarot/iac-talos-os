# clusters.auto.tfvars

shared_storage_id = "nfs-shared"

clusters = {
  a = {
    masters = {
      "clA-cp01" = {
        vm_id          = 100
        node_name      = "clA-cp01"
        node_cpu_cores = "2"
        node_memory    = 4096
        node_disk      = "20"
        node_ipconfig  = "ip=192.168.0.110/24,gw=192.168.0.1"
        mac_address    = "02:00:0A:00:00:01"
      }
      "clA-cp02" = {
        vm_id          = 101
        node_name      = "clA-cp02"
        node_cpu_cores = "2"
        node_memory    = 4096
        node_disk      = "20"
        node_ipconfig  = "ip=192.168.0.111/24,gw=192.168.0.1"
        mac_address    = "02:00:0A:00:00:02"
      }
      "clA-cp03" = {
        vm_id          = 102
        node_name      = "clA-cp03"
        node_cpu_cores = "2"
        node_memory    = 4096
        node_disk      = "20"
        node_ipconfig  = "ip=192.168.0.112/24,gw=192.168.0.1"
        mac_address    = "02:00:0A:00:00:03"
      }
    }
    workers = {
      "clA-wk01" = {
        vm_id                = 110
        node_name            = "clA-wk01"
        node_cpu_cores       = "1"
        node_memory          = 2048
        node_disk            = "30"
        node_ipconfig        = "ip=192.168.0.113/24,gw=192.168.0.1"
        mac_address          = "02:00:0A:00:10:01"
      }
      "clA-wk02" = {
        vm_id                = 120
        node_name            = "clA-wk02"
        node_cpu_cores       = "1"
        node_memory          = 2048
        node_disk            = "30"
        node_ipconfig        = "ip=192.168.0.114/24,gw=192.168.0.1"
        mac_address          = "02:00:0A:00:10:02"
      }
      "clA-wk03" = {
        vm_id                = 130
        node_name            = "clA-wk03"
        node_cpu_cores       = "1"
        node_memory          = 2048
        node_disk            = "30"
        node_ipconfig        = "ip=192.168.0.115/24,gw=192.168.0.1"
        mac_address          = "02:00:0A:00:10:03"
      }
    }
    target_nodes = ["pve1"]
    vip          = "192.168.0.199"
    pod_net      = "10.14.0.0/16"
    svc_net      = "10.15.0.0/16"
  }

  b = {
    masters = {
      "clB-cp01" = {
        vm_id          = 200
        node_name      = "clB-cp01"
        node_cpu_cores = "2"
        node_memory    = 4096
        node_disk      = "20"
        node_ipconfig  = "ip=192.168.0.120/24,gw=192.168.0.1"
        mac_address    = "02:00:0A:01:00:01"
      }
      "clB-cp02" = {
        vm_id          = 201
        node_name      = "clB-cp02"
        node_cpu_cores = "2"
        node_memory    = 4096
        node_disk      = "20"
        node_ipconfig  = "ip=192.168.0.121/24,gw=192.168.0.1"
        mac_address    = "02:00:0A:01:00:02"
      }
      "clB-cp03" = {
        vm_id          = 202
        node_name      = "clB-cp03"
        node_cpu_cores = "2"
        node_memory    = 4096
        node_disk      = "20"
        node_ipconfig  = "ip=192.168.0.122/24,gw=192.168.0.1"
        mac_address    = "02:00:0A:01:00:03"
      }
    }
    workers = {
      "clB-wk01" = {
        vm_id                = 210
        node_name            = "clB-wk01"
        node_cpu_cores       = "1"
        node_memory          = 2048
        node_disk            = "30"
        node_ipconfig        = "ip=192.168.0.123/24,gw=192.168.0.1"
        mac_address          = "02:00:0A:01:10:01"
      }
      "clB-wk02" = {
        vm_id                = 220
        node_name            = "clB-wk02"
        node_cpu_cores       = "1"
        node_memory          = 2048
        node_disk            = "30"
        node_ipconfig        = "ip=192.168.0.124/24,gw=192.168.0.1"
        mac_address          = "02:00:0A:01:10:02"
      }
      "clB-wk03" = {
        vm_id                = 230
        node_name            = "clB-wk03"
        node_cpu_cores       = "1"
        node_memory          = 2048
        node_disk            = "30"
        node_ipconfig        = "ip=192.168.0.125/24,gw=192.168.0.1"
        mac_address          = "02:00:0A:01:10:03"
      }
    }
    target_nodes = ["pve2"]
    vip          = "192.168.0.199"
    pod_net      = "10.16.0.0/16"
    svc_net      = "10.17.0.0/16"
  }

  c = {
    masters = {
      "clC-cp01" = {
        vm_id          = 300
        node_name      = "clC-cp01"
        node_cpu_cores = "2"
        node_memory    = 4096
        node_disk      = "20"
        node_ipconfig  = "ip=192.168.0.130/24,gw=192.168.0.1"
        mac_address    = "02:00:0A:02:00:01"
      }
      "clC-cp02" = {
        vm_id          = 301
        node_name      = "clC-cp02"
        node_cpu_cores = "2"
        node_memory    = 4096
        node_disk      = "20"
        node_ipconfig  = "ip=192.168.0.131/24,gw=192.168.0.1"
        mac_address    = "02:00:0A:02:00:02"
      }
      "clC-cp03" = {
        vm_id          = 302
        node_name      = "clC-cp03"
        node_cpu_cores = "2"
        node_memory    = 4096
        node_disk      = "20"
        node_ipconfig  = "ip=192.168.0.132/24,gw=192.168.0.1"
        mac_address    = "02:00:0A:02:00:03"
      }
    }
    workers = {
      "clC-wk01" = {
        vm_id                = 310
        node_name            = "clC-wk01"
        node_cpu_cores       = "1"
        node_memory          = 2048
        node_disk            = "30"
        node_ipconfig        = "ip=192.168.0.133/24,gw=192.168.0.1"
        mac_address          = "02:00:0A:02:10:01"
      }
      "clC-wk02" = {
        vm_id                = 320
        node_name            = "clC-wk02"
        node_cpu_cores       = "1"
        node_memory          = 2048
        node_disk            = "30"
        node_ipconfig        = "ip=192.168.0.134/24,gw=192.168.0.1"
        mac_address          = "02:00:0A:02:10:02"
      }
      "clC-wk03" = {
        vm_id                = 330
        node_name            = "clC-wk03"
        node_cpu_cores       = "1"
        node_memory          = 2048
        node_disk            = "30"
        node_ipconfig        = "ip=192.168.0.135/24,gw=192.168.0.1"
        mac_address          = "02:00:0A:02:10:03"
      }
    }
    target_nodes = ["pve3"]
    vip          = "192.168.0.199"
    pod_net      = "10.18.0.0/16"
    svc_net      = "10.19.0.0/16"
  }
}
