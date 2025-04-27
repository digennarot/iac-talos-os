Talos Packer Build
This repository contains a Packer HCL2 template (talos.pkr.hcl) to build a Talos Linux VM-template on one or more Proxmox nodes, using the Talos Image Factory.

Prerequisites
Packer ≥ 1.8.0

jq (for extracting the schematic ID)

Network-accessible Proxmox host(s), with SSH root access and a valid API token.

An Arch (or other) ISO uploaded to your Proxmox datastore (e.g. local:iso/archlinux-2025.04.01-x86_64.iso).

A Talos Image Factory schematic file, for example schematic.yaml:

yaml
Copia
Modifica
customization:
  systemExtensions:
    officialExtensions:
      - siderolabs/i915-ucode
      - siderolabs/intel-ucode
      - siderolabs/qemu-guest-agent
Files
talos.pkr.hcl
The Packer template defining:

Proxmox-ISO builder

Variables for Proxmox connection, node, storage, VM settings

Inline shell provisioner to download & dd the Talos raw image

vars/local.pkrvars.hcl
Example Packer var-file for Proxmox credentials, target node, storage, and the schematic_id.

Generating the Talos Schematic ID
Before running Packer, POST your YAML schematic to the Talos Image Factory and extract its ID:


export SCHEMATIC_FILE=schematic.yaml

SCHEM_ID=$(
  curl -sS \
    -X POST https://factory.talos.dev/schematics \
    -H "Content-Type: application/yaml" \
    --data-binary @"${SCHEMATIC_FILE}" \
  | jq -r .id
)

echo "Your schematic ID is: $SCHEM_ID"
Copy that value into your vars/local.pkrvars.hcl (or pass it via -var).

Configuration: vars/local.pkrvars.hcl

# vars/local.pkrvars.hcl

proxmox_api_url          = "https://192.168.0.200:8006/api2/json"
proxmox_api_token_id     = "terraform@pam!provider"
proxmox_api_token_secret = "<YOUR_SECRET>"

proxmox_node    = "pve1"
proxmox_storage = "local-zfs"

schematic_id = "<YOUR_SCHEMATIC_ID>"
You can override any of the other variables (vm_id, disk_size, etc.) by adding them here.

Running Packer
Initialize the Packer template:


cd packer
packer init talos.pkr.hcl
Build the template on a single node (defaults to pve1/VMID 9700):


packer build \
  -var-file="vars/local.pkrvars.hcl" \
  talos.pkr.hcl
Repeat for other nodes by overriding proxmox_node and vm_id:


packer build \
  -var-file="vars/local.pkrvars.hcl" \
  -var "proxmox_node=pve2" \
  -var "vm_id=9701" \
  talos.pkr.hcl

packer build \
  -var-file="vars/local.pkrvars.hcl" \
  -var "proxmox_node=pve3" \
  -var "vm_id=9702" \
  talos.pkr.hcl
After each run, you’ll have a template VM named:


talos-<version>-template
on the chosen Proxmox node, ready for Terraform/OpenTofu to clone.

Tips & Troubleshooting
Disk size: ensure your placeholder disk (disk_size) in talos.pkr.hcl is at least as large as the Talos raw image (e.g. "2G" or more).

SSH access: Packer uses the ISO’s SSH user/password (root/packer)—make sure your ISO supports that.

API token: must include the ! separator (e.g. terraform@pam!provider).

Timeouts: if the download or SSH hangs, increase ssh_timeout or adjust the boot_wait/boot_command timing.

