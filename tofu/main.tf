
module "masters" {
  source                   = "./modules/compute"
  proxmox_api_url          = var.proxmox_api_url
  proxmox_api_token_id     = var.proxmox_api_token_id
  proxmox_api_token_secret = var.proxmox_api_token_secret

  nodes             = local.selected_master_nodes
  shared_storage_id = var.shared_storage_id
  template_vmids    = var.template_vmids
  target_node       = local.target_node
  clone             = "talos-${var.talos.version}-qemu"
}

module "workers" {
  source                   = "./modules/compute"
  proxmox_api_url          = var.proxmox_api_url
  proxmox_api_token_id     = var.proxmox_api_token_id
  proxmox_api_token_secret = var.proxmox_api_token_secret

  nodes             = local.selected_worker_nodes
  shared_storage_id = var.shared_storage_id
  template_vmids    = var.template_vmids
  target_node       = local.target_node
  clone             = "talos-${var.talos.version}-qemu"
}