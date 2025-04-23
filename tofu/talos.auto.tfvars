talos = {
  factory_url = "https://factory.talos.dev"
  version     = "v1.9.5"
  storage     = "zfs-shared" # instead of "local-zfs"
  disk_size   = "20G"
  platform    = "nocloud"
  arch        = "amd64"

  schematic = <<EOF
customization:
  systemExtensions:
    officialExtensions:
      - siderolabs/i915-ucode
      - siderolabs/intel-ucode
      - siderolabs/qemu-guest-agent
EOF
}
