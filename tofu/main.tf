# --------------------------------------------------
# 1) POST your schematic → get schematic_id
# --------------------------------------------------
data "http" "schematic" {
  url          = "${var.talos.factory_url}/schematics"
  method       = "POST"
  request_body = var.talos.schematic
}

locals {
  # unique schematic identifier
  schematic_id = jsondecode(data.http.schematic.response_body).id
  # name of the resulting VM template on each node
  template_name = "talos-${var.talos.version}-template"
}

# --------------------------------------------------
# 2) On each Proxmox node: create & template the VM
# --------------------------------------------------
resource "null_resource" "talos_template" {
  for_each = toset(var.proxmox_nodes)

  triggers = {
    node      = each.key
    schematic = local.schematic_id
    version   = var.talos.version
  }

  provisioner "local-exec" {
    command = <<-EOT
ssh root@${each.key} bash -eux <<-EOF
  # 1) Destroy any prior template
  if qm status ${var.template_vmids[each.key]} &>/dev/null; then
    qm destroy ${var.template_vmids[each.key]} --purge
  fi

  # 2) Create a VM skeleton with no main disk
  qm create ${var.template_vmids[each.key]} \
    --name ${local.template_name} \
    --memory 2048 \
    --cores 2 \
    --net0 virtio,bridge=vmbr0 \
    --ide2 ${var.talos.storage}:cloudinit \
    --ciuser talos --cipassword talos \
    --agent 1

  # 3) Download the Talos raw image once
  curl -sL "${var.talos.factory_url}/image/${local.schematic_id}/${var.talos.version}/${var.talos.platform}-${var.talos.arch}.raw.gz" \
    -o /tmp/talos-${each.key}.raw.gz

  gunzip -f /tmp/talos-${each.key}.raw.gz

  # 4) Import into a new ZFS volume of the correct size
  qm importdisk ${var.template_vmids[each.key]} /tmp/talos-${each.key}.raw ${var.talos.storage} --format raw

  # 5) Attach that imported disk as scsi0
  qm set ${var.template_vmids[each.key]} \
    --scsi0 ${var.talos.storage}:vm-${var.template_vmids[each.key]}-disk-0

  # 6) Finally turn it into a template
  qm template ${var.template_vmids[each.key]}

  # cleanup
  rm -f /tmp/talos-${each.key}.raw
EOF
    EOT
  }
}

# --------------------------------------------------
# 3) Clone that template in your modules
# --------------------------------------------------
module "compute_master" {
  source                   = "./compute-master"
  clusters                 = var.clusters
  cluster_id               = var.cluster_id
  nodes                    = local.selected_master_nodes
  shared_storage_id        = var.shared_storage_id
  proxmox_api_url          = var.proxmox_api_url
  proxmox_api_token_id     = var.proxmox_api_token_id
  proxmox_api_token_secret = var.proxmox_api_token_secret
  talos_template           = local.template_name
  template_ready           = null_resource.talos_template
}

module "compute_worker" {
  source                   = "./compute-worker"
  clusters                 = var.clusters
  cluster_id               = var.cluster_id
  nodes                    = local.selected_worker_nodes
  shared_storage_id        = var.shared_storage_id
  proxmox_api_url          = var.proxmox_api_url
  proxmox_api_token_id     = var.proxmox_api_token_id
  proxmox_api_token_secret = var.proxmox_api_token_secret
  talos_template           = local.template_name
  template_ready           = null_resource.talos_template
}
