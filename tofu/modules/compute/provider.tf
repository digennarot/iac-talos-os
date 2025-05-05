terraform {
  required_providers {
    proxmox = {
      source = "telmate/proxmox"
      # Set version to match what you installed (3.0.1-rc8)
      version = "3.0.1-rc8"
    }
  }
}

provider "proxmox" {
  # Note: This "source" line is optional in the provider block itself as
  # long as you defined it in required_providers, but you can add it if you want.
  # source = "telmate/proxmox"

  pm_api_url          = var.proxmox_api_url
  pm_api_token_id     = var.proxmox_api_token_id
  pm_api_token_secret = var.proxmox_api_token_secret
  pm_tls_insecure     = true
}
