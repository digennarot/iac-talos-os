output "talconfig_paths" {
  value = [
    for k in keys(var.clusters) :
    "${path.root}/generated_configs/talconfig-cluster-${k}.yaml"
  ]
}