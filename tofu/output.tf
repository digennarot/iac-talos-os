output "master_mac_addrs" {
  value = module.masters.mac_addrs
}

output "worker_mac_addrs" {
  value = module.workers.mac_addrs
}

output "kubeconfig" {
  value     = "$HOME/.kube/config-${local.workspace}"
  sensitive = true
}
