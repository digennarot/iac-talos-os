module "masters" {
  source                   = "./modules/compute"
  role                     = "master"
  proxmox_api_url          = var.proxmox_api_url
  proxmox_api_token_id     = var.proxmox_api_token_id
  proxmox_api_token_secret = var.proxmox_api_token_secret

  nodes             = local.selected_master_nodes
  shared_storage_id = var.shared_storage_id
  target_node       = local.target_node
  clone             = "talos-${var.talos.version}-qemu"
}

module "workers" {
  source                   = "./modules/compute"
  role                     = "worker"
  proxmox_api_url          = var.proxmox_api_url
  proxmox_api_token_id     = var.proxmox_api_token_id
  proxmox_api_token_secret = var.proxmox_api_token_secret

  nodes             = local.selected_worker_nodes
  shared_storage_id = var.shared_storage_id
  target_node       = local.target_node
  clone             = "talos-${var.talos.version}-qemu"
}


/* module "talconfigs" {
  source = "./modules/talconfig"

  clusters = {
    for k, v in var.clusters : k => merge(v, {
      masters = local.master_nodes_with_mac
      workers = local.worker_nodes_with_mac
    })
  }

  talos_version         = var.talos_version
  kubernetes_version    = var.kubernetes_version
  schematic_id          = var.schematic_id
  global_patches        = var.global_patches
  control_plane_patches = var.control_plane_patches
} */