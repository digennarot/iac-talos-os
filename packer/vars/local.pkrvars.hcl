proxmox_api_url = "https://192.168.0.200:8006/api2/json"  # Your Proxmox IP Address
proxmox_node = "pve1"

proxmox_api_token_id     = "terraform@pve!provider"               # API Token ID
proxmox_api_token_secret = "2438745d-ef09-46cd-8f39-a6d80d4b625c"

proxmox_storage      = "zfs-shared"
cpu_type             = "host"
talos_version        = "v1.9.5"
base_iso_file        = "local:iso/archlinux-2025.04.01-x86_64.iso"
