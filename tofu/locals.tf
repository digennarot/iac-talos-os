// locals.tf
locals {
  current_workspace     = terraform.workspace
  selected_master_nodes = var.cluster_id == "a" ? var.cluster_a_master_nodes : var.cluster_b_master_nodes
  selected_worker_nodes = var.cluster_id == "a" ? var.cluster_a_worker_nodes : var.cluster_b_worker_nodes
}

resource "null_resource" "block_default" {
  count = local.current_workspace == "default" ? 1 : 0

  provisioner "local-exec" {
    command = "echo 'The default workspace is not allowed!' && exit 1"
  }
}
