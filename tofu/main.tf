
module "compute_master" {
  source                   = "./compute-master"
  proxmox_api_url          = var.proxmox_api_url
  proxmox_api_token_id     = var.proxmox_api_token_id
  proxmox_api_token_secret = var.proxmox_api_token_secret
  proxmox_node             = var.proxmox_node
  nodes                    = local.selected_master_nodes
  clusters                 = var.clusters
  cluster_id               = var.cluster_id
  shared_storage_id        = var.shared_storage_id
}

module "compute_worker" {
  source                   = "./compute-worker"
  proxmox_api_url          = var.proxmox_api_url
  proxmox_api_token_id     = var.proxmox_api_token_id
  proxmox_api_token_secret = var.proxmox_api_token_secret
  proxmox_node             = var.proxmox_node
  nodes                    = local.selected_worker_nodes
  clusters                 = var.clusters
  cluster_id               = var.cluster_id
  shared_storage_id        = var.shared_storage_id
}
