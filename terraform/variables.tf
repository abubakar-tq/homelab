variable "virtual_environment_endpoint" {
  type      = string
  sensitive = true
}

variable "virtual_environment_api_token" {
  type      = string
  sensitive = true
}

variable "virtual_environment_node_name" {
   type      = string
   default = "pve"
}

variable "lan_gateway" {
  type    = string
  default = "192.168.1.1"
}

variable "dns_servers" {
  type    = list(string)
  default = ["192.168.1.1", "1.1.1.1"]
}

variable "network_mtu" {
  type    = number
  default = 1492
}

variable "nodes" {
  type = map(object({
    node_name   = string
    vm_id       = number
    role        = string
    description = string
    cpu_cores   = number
    memory_mb   = number
    swap_mb     = number
    disk_gb     = number
    ip_address  = string
  }))

  default = {
    master = {
      node_name   = "k8s-master"
      vm_id       = 100
      role        = "master"
      description = "Kubernetes master node"
      cpu_cores   = 2
      memory_mb   = 2048
      swap_mb     = 1024
      disk_gb     = 10
      ip_address  = "192.168.1.3/24"
    }

    slave1 = {
      node_name   = "k8s-slave-1"
      vm_id       = 101
      role        = "slave"
      description = "Kubernetes worker node 1"
      cpu_cores   = 1
      memory_mb   = 1536
      swap_mb     = 512
      disk_gb     = 8
      ip_address  = "192.168.1.4/24"
    }

    slave2 = {
      node_name   = "k8s-slave-2"
      vm_id       = 102
      role        = "slave"
      description = "Kubernetes worker node 2"
      cpu_cores   = 1
      memory_mb   = 1536
      swap_mb     = 512
      disk_gb     = 8
      ip_address  = "192.168.1.8/24"
    }
  }
}
