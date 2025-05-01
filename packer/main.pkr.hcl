source "proxmox-iso" "talos" {
  proxmox_url              = var.proxmox_api_url
  username                 = var.proxmox_api_token_id
  token                    = var.proxmox_api_token_secret
  node                     = var.proxmox_node
  insecure_skip_tls_verify = true

  boot_iso {
    type     = "scsi"
    iso_file = var.base_iso_file
    unmount  = true
  }

  scsi_controller = "virtio-scsi-single"

  network_adapters {
    bridge = "vmbr0"
    model  = "virtio"
  }

  disks {
    type         = "scsi"
    storage_pool = var.storage_pool
    format       = "raw"
    disk_size    = var.disk_size
    io_thread    = true
    cache_mode   = "writethrough"
  }

  memory   = var.memory
  vm_id    = var.template_vmid
  cores    = var.cores
  cpu_type = var.cpu_type
  sockets  = var.sockets

  # 1) abilitiamo il QEMU guest agent
  qemu_agent = true

  # 2) credenziali SSH e timeout prolungato
  ssh_username = "root"
  ssh_password = "packer"
  ssh_timeout  = "15m"

  # 3) non usiamo più cloud-init perché Talos non lo supporta come cloud image
  cloud_init              = false
  cloud_init_storage_pool = ""

  # 4) aspettiamo un po’ di più prima di inviare i tasti
  boot_wait = "20s"

  # 5) boot_command: settaggio password + rete statica  
  boot_command = [
    "<enter><wait50s>",

    # impostiamo password root=packer
    "passwd<enter><wait1s>packer<enter><wait1s>packer<enter>",

    # configuriamo IP statico e gateway
    # ATTENZIONE: sostituisci 'ens18' con la tua interfaccia (usa `ip addr` in console Proxmox)
    "ip address add ${var.static_ip} broadcast + dev ens18<enter><wait1s>",
    "ip route add 0.0.0.0/0 via ${var.gateway} dev ens18<enter><wait1s>",
  ]

  template_name        = "talos-${var.talos_version}-qemu"
  template_description = "Talos ${var.talos_version} qemu-agent template"
}

build {
  sources = ["source.proxmox-iso.talos"]

  # 1) Generiamo on-the-fly lo schematic di Image Factory
  provisioner "file" {
    destination = "/tmp/schematic.yaml"
    content     = <<EOF
extraKernelArgs:
  - ipv6.disable=1
customization:
  systemExtensions:
    officialExtensions:
      - siderolabs/qemu-guest-agent
EOF
  }

  # 2) Carichiamo lo schematic, prendiamo l’ID, scarichiamo il raw.xz e lo riversiamo su /dev/sda
  provisioner "shell" {
    inline = [
      "echo '[1/4] Creazione schematic su Image Factory…'",
      "SCHEMATIC_ID=$(curl -sSL -X POST --data-binary @/tmp/schematic.yaml https://factory.talos.dev/v1.10/schematics | grep -o '\"id\":\"[^\"]*' | sed 's/\"id\":\"//')",
      "echo \"[2/4] Schematic ID = $SCHEMATIC_ID\"",
      "echo '[3/4] Download e scrittura Talos raw image…'",
      "curl -sL https://factory.talos.dev/image/$SCHEMATIC_ID/${var.talos_version}/metal-amd64.raw.xz | xz -d -c | dd of=/dev/sda bs=4M conv=fsync status=progress",
      "echo '[4/4] Sync e arresto VM…'"
    ]
  }
}