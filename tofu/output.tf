output "master_mac_addrs" {
  value = module.compute_master.master_mac_addrs
}

output "worker_mac_addrs" {
  value = module.compute_worker.worker_mac_addrs
}

