# clusters.auto.tfvars

shared_storage_id = "nfs-shared"

clusters = {
  a = {
    masters = {
      "cla-cp01" = {
        vm_id          = 100
        node_name      = "cla-cp01"
        node_cpu_cores = "2"
        node_memory    = 4096
        node_disk      = "20"
        node_ipconfig  = "ip=192.168.0.110/24,gw=192.168.0.1"
        mac_address    = "02:00:0A:00:00:01"
      }
      # "cla-cp02" = {
      #   vm_id          = 101
      #   node_name      = "cla-cp02"
      #   node_cpu_cores = "2"
      #   node_memory    = 4096
      #   node_disk      = "20"
      #   node_ipconfig  = "ip=192.168.0.111/24,gw=192.168.0.1"
      #   mac_address    = "02:00:0A:00:00:02"
      # }
      # "cla-cp03" = {
      #   vm_id          = 102
      #   node_name      = "cla-cp03"
      #   node_cpu_cores = "2"
      #   node_memory    = 4096
      #   node_disk      = "20"
      #   node_ipconfig  = "ip=192.168.0.112/24,gw=192.168.0.1"
      #   mac_address    = "02:00:0A:00:00:03"
      # }
    }
    workers = {
      "cla-wk01" = {
        vm_id                = 110
        node_name            = "cla-wk01"
        node_cpu_cores       = "1"
        node_memory          = 2048
        node_disk            = "30"
        node_ipconfig        = "ip=192.168.0.113/24,gw=192.168.0.1"
        mac_address          = "02:00:0A:00:10:01"
      }
      "cla-wk02" = {
        vm_id                = 120
        node_name            = "cla-wk02"
        node_cpu_cores       = "1"
        node_memory          = 2048
        node_disk            = "30"
        node_ipconfig        = "ip=192.168.0.114/24,gw=192.168.0.1"
        mac_address          = "02:00:0A:00:10:02"
      }
      # "cla-wk03" = {
      #   vm_id                = 130
      #   node_name            = "cla-wk03"
      #   node_cpu_cores       = "1"
      #   node_memory          = 2048
      #   node_disk            = "30"
      #   node_ipconfig        = "ip=192.168.0.115/24,gw=192.168.0.1"
      #   mac_address          = "02:00:0A:00:10:03"
      # }
    }
    target_nodes = ["pve1"]
    vip          = "192.168.0.230"
    pod_net      = "10.14.0.0/16"
    svc_net      = "10.15.0.0/16"
  }

  b = {
    masters = {
      "clb-cp01" = {
        vm_id          = 200
        node_name      = "clb-cp01"
        node_cpu_cores = "2"
        node_memory    = 4096
        node_disk      = "20"
        node_ipconfig  = "ip=192.168.0.120/24,gw=192.168.0.1"
        mac_address    = "02:00:0A:01:00:01"
      }
      "clb-cp02" = {
        vm_id          = 201
        node_name      = "clb-cp02"
        node_cpu_cores = "2"
        node_memory    = 4096
        node_disk      = "20"
        node_ipconfig  = "ip=192.168.0.121/24,gw=192.168.0.1"
        mac_address    = "02:00:0A:01:00:02"
      }
      "clb-cp03" = {
        vm_id          = 202
        node_name      = "clb-cp03"
        node_cpu_cores = "2"
        node_memory    = 4096
        node_disk      = "20"
        node_ipconfig  = "ip=192.168.0.122/24,gw=192.168.0.1"
        mac_address    = "02:00:0A:01:00:03"
      }
    }
    workers = {
      "clb-wk01" = {
        vm_id                = 210
        node_name            = "clb-wk01"
        node_cpu_cores       = "1"
        node_memory          = 2048
        node_disk            = "30"
        node_ipconfig        = "ip=192.168.0.123/24,gw=192.168.0.1"
        mac_address          = "02:00:0A:01:10:01"
      }
      "clb-wk02" = {
        vm_id                = 220
        node_name            = "clb-wk02"
        node_cpu_cores       = "1"
        node_memory          = 2048
        node_disk            = "30"
        node_ipconfig        = "ip=192.168.0.124/24,gw=192.168.0.1"
        mac_address          = "02:00:0A:01:10:02"
      }
      # "clb-wk03" = {
      #   vm_id                = 230
      #   node_name            = "clb-wk03"
      #   node_cpu_cores       = "1"
      #   node_memory          = 2048
      #   node_disk            = "30"
      #   node_ipconfig        = "ip=192.168.0.125/24,gw=192.168.0.1"
      #   mac_address          = "02:00:0A:01:10:03"
      # }
    }
    target_nodes = ["pve2"]
    vip          = "192.168.0.231"
    pod_net      = "10.16.0.0/16"
    svc_net      = "10.17.0.0/16"
  }

  # c = {
  #   masters = {
  #     "clc-cp01" = {
  #       vm_id          = 300
  #       node_name      = "clc-cp01"
  #       node_cpu_cores = "2"
  #       node_memory    = 4096
  #       node_disk      = "20"
  #       node_ipconfig  = "ip=192.168.0.130/24,gw=192.168.0.1"
  #       mac_address    = "02:00:0A:02:00:01"
  #     }
  #     "clc-cp02" = {
  #       vm_id          = 301
  #       node_name      = "clc-cp02"
  #       node_cpu_cores = "2"
  #       node_memory    = 4096
  #       node_disk      = "20"
  #       node_ipconfig  = "ip=192.168.0.131/24,gw=192.168.0.1"
  #       mac_address    = "02:00:0A:02:00:02"
  #     }
  #     "clc-cp03" = {
  #       vm_id          = 302
  #       node_name      = "clc-cp03"
  #       node_cpu_cores = "2"
  #       node_memory    = 4096
  #       node_disk      = "20"
  #       node_ipconfig  = "ip=192.168.0.132/24,gw=192.168.0.1"
  #       mac_address    = "02:00:0A:02:00:03"
  #     }
  #   }
  #   workers = {
  #     "clc-wk01" = {
  #       vm_id                = 310
  #       node_name            = "clc-wk01"
  #       node_cpu_cores       = "1"
  #       node_memory          = 2048
  #       node_disk            = "30"
  #       node_ipconfig        = "ip=192.168.0.133/24,gw=192.168.0.1"
  #       mac_address          = "02:00:0A:02:10:01"
  #     }
  #     "clc-wk02" = {
  #       vm_id                = 320
  #       node_name            = "clc-wk02"
  #       node_cpu_cores       = "1"
  #       node_memory          = 2048
  #       node_disk            = "30"
  #       node_ipconfig        = "ip=192.168.0.134/24,gw=192.168.0.1"
  #       mac_address          = "02:00:0A:02:10:02"
  #     }
  #     "clc-wk03" = {
  #       vm_id                = 330
  #       node_name            = "clc-wk03"
  #       node_cpu_cores       = "1"
  #       node_memory          = 2048
  #       node_disk            = "30"
  #       node_ipconfig        = "ip=192.168.0.135/24,gw=192.168.0.1"
  #       mac_address          = "02:00:0A:02:10:03"
  #     }
  #   }
  #   target_nodes = ["pve3"]
  #   vip          = "192.168.0.232"
  #   pod_net      = "10.18.0.0/16"
  #   svc_net      = "10.19.0.0/16"
  # }
}
