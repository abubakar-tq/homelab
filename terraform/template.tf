resource "proxmox_download_file" "ubuntu_2204_lxc_img" {
  content_type = "vztmpl"
  datastore_id = "local"
  node_name    = "pve"
  file_name    = "ubuntu-22.04-standard_22.04-1_amd64.tar.zst"
  url          = "http://download.proxmox.com/images/system/ubuntu-22.04-standard_22.04-1_amd64.tar.zst"
}

resource "proxmox_virtual_environment_container" "ubuntu_container" {
  for_each = var.nodes

  node_name   = var.virtual_environment_node_name
  vm_id       = each.value.vm_id
  description = each.value.description

  tags = [each.value.role]

  unprivileged = true
  features {
    nesting = true
  }

  cpu {
    cores = each.value.cpu_cores
  }

  memory {
    dedicated = each.value.memory_mb
    swap      = each.value.swap_mb
  }

  initialization {
    hostname =  each.value.node_name

    ip_config {
      ipv4 {
        address = each.value.ip_address
        gateway = var.lan_gateway
      }
    }

    user_account {
      keys = [
        trimspace(tls_private_key.ubuntu_container_key.public_key_openssh)
      ]
      password = random_password.ubuntu_container_password.result
    }
  }

  network_interface {
    name = "veth0"
  }

  disk {
    datastore_id = "local-lvm"
    size         = each.value.disk_gb
  }

  operating_system {
    template_file_id = proxmox_download_file.ubuntu_2204_lxc_img.id
    type = "ubuntu"
  }

  startup {
    order      = "3"
    up_delay   = "60"
    down_delay = "60"
  }
}

resource "random_password" "ubuntu_container_password" {
  length           = 16
  override_special = "_%@"
  special          = true
}

resource "tls_private_key" "ubuntu_container_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

output "ubuntu_container_password" {
  value     = random_password.ubuntu_container_password.result
  sensitive = true
}

output "ubuntu_container_private_key" {
  value     = tls_private_key.ubuntu_container_key.private_key_pem
  sensitive = true
}

output "ubuntu_container_public_key" {
  value = tls_private_key.ubuntu_container_key.public_key_openssh
}

output "ubuntu_container_ip" {
  value = { for key, container in proxmox_virtual_environment_container.ubuntu_container : key => container.ipv4 }
}
