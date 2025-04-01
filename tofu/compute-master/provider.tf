# Initial Provider Configuration for Proxmox
terraform {
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "3.0.1-rc7"
    }
  }
}

provider "proxmox" {
  pm_api_url          = var.proxmox_api_url          # es: "https://proxmox.local:8006/api2/json"
  pm_api_token_id     = var.proxmox_api_token_id     # es: "terraform@pve!token"
  pm_api_token_secret = var.proxmox_api_token_secret # secret del token
  pm_tls_insecure     = true                         # ignora certificati self-signed (dev)
}
