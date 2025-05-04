talos = {
  factory_url = "https://factory.talos.dev"
  version     = "v1.10.0"
  storage     = "rpool/data" # o qualunque sia il tuo pool ZFS
  disk_size   = "20G"
  platform    = "nocloud"
  arch        = "amd64"

  schematic = <<EOF
customization:
  systemExtensions:
    officialExtensions:
      - siderolabs/qemu-guest-agent
EOF
}
