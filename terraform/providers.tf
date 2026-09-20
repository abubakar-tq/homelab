terraform {
  required_version = ">= 1.5.0"

  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.113.1"
    }
    tls = {
        source  = "hashicorp/tls"
        version = "~> 4.4.1"
    }
    random = {
        source  = "hashicorp/random"
        version = "~> 3.9.1"
    }
  }
}

provider "proxmox" {
  endpoint = var.virtual_environment_endpoint
  api_token = var.virtual_environment_api_token
  insecure = true
}
