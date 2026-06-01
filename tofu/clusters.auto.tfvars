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
        mac_address    = "02:00:0A:00:00:01"
      }
      "cla-cp02" = {
        vm_id          = 101
        node_name      = "cla-cp02"
        node_cpu_cores = "2"
        node_memory    = 4096
        node_disk      = "20"
        mac_address    = "02:00:0A:00:00:02"
      }
      "cla-cp03" = {
        vm_id          = 102
        node_name      = "cla-cp03"
        node_cpu_cores = "2"
        node_memory    = 4096
        node_disk      = "20"
        mac_address    = "02:00:0A:00:00:03"
      }
    }
    workers = {
      "cla-wk01" = {
        vm_id                = 110
        node_name            = "cla-wk01"
        node_cpu_cores       = "1"
        node_memory          = 2048
        node_disk            = "30"
        mac_address          = "02:00:0A:00:10:01"
      }
      "cla-wk02" = {
        vm_id                = 120
        node_name            = "cla-wk02"
        node_cpu_cores       = "1"
        node_memory          = 2048
        node_disk            = "30"
        mac_address          = "02:00:0A:00:10:02"
      }
      # "cla-wk03" = {
      #   vm_id                = 130
      #   node_name            = "cla-wk03"
      #   node_cpu_cores       = "1"
      #   node_memory          = 2048
      #   node_disk            = "30"
      #   mac_address          = "02:00:0A:00:10:03"
      # }
    }
    target_nodes = ["pve1"]
    vip          = "192.168.1.230"
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
        mac_address    = "02:00:0A:01:00:01"
      }
      "clb-cp02" = {
        vm_id          = 201
        node_name      = "clb-cp02"
        node_cpu_cores = "2"
        node_memory    = 4096
        node_disk      = "20"
        mac_address    = "02:00:0A:01:00:02"
      }
      "clb-cp03" = {
        vm_id          = 202
        node_name      = "clb-cp03"
        node_cpu_cores = "2"
        node_memory    = 4096
        node_disk      = "20"
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
        mac_address          = "02:00:0A:01:10:01"
      }
      "clb-wk02" = {
        vm_id                = 220
        node_name            = "clb-wk02"
        node_cpu_cores       = "1"
        node_memory          = 2048
        node_disk            = "30"
        mac_address          = "02:00:0A:01:10:02"
      }
      # "clb-wk03" = {
      #   vm_id                = 230
      #   node_name            = "clb-wk03"
      #   node_cpu_cores       = "1"
      #   node_memory          = 2048
      #   node_disk            = "30"
      #   mac_address          = "02:00:0A:01:10:03"
      # }
    }
    target_nodes = ["pve2"]
    vip          = "192.168.1.231"
    pod_net      = "10.16.0.0/16"
    svc_net      = "10.17.0.0/16"
  }

}
