locals {
  current_workspace = terraform.workspace

  selected_master_nodes = (
    var.cluster_id == "a" ? var.cluster_a_master_nodes :
    var.cluster_id == "b" ? var.cluster_b_master_nodes :
    var.cluster_c_master_nodes
  )

  selected_worker_nodes = (
    var.cluster_id == "a" ? var.cluster_a_worker_nodes :
    var.cluster_id == "b" ? var.cluster_b_worker_nodes :
    var.cluster_c_worker_nodes
  )

  target_proxmox_node = (
    var.cluster_id == "a" ? "pve1" :
    var.cluster_id == "b" ? "pve2" :
    "pve3"
  )

}


resource "null_resource" "block_default" {
  count = local.current_workspace == "default" ? 1 : 0

  provisioner "local-exec" {
    command = "echo 'The default workspace is not allowed!' && exit 1"
  }
}
