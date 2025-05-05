resource "local_file" "talconfig" {
  for_each = var.clusters

  filename = "${path.root}/generated_configs/talconfig-cluster-${each.key}.yaml"
  content = templatefile("${path.module}/templates/talconfig.tftpl", {
    cluster_name          = "cluster-${each.key}"
    talos_version         = var.talos_version
    kubernetes_version    = var.kubernetes_version
    vip                   = each.value.vip
    endpoint              = "https://${each.value.vip}:6443"
    cluster_pod_nets      = [each.value.pod_net]
    cluster_svc_nets      = [each.value.svc_net]
    additional_sans       = [each.value.vip, "127.0.0.1"]
    masters               = local.master_nodes_with_mac
    workers               = local.worker_nodes_with_mac
    global_patches        = var.global_patches
    control_plane_patches = var.control_plane_patches
    schematic_id          = var.schematic_id
  })
}


