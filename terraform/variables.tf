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

variable "nodes" {
  type = map(object({
    node_name   = string
    vm_id       = number
    role        = string
    description = string
  }))

  default = {
    master = {
      node_name   = "k8s-master"
      vm_id       = 100
      role        = "master"
      description = "Kubernetes master node"
    }

    slave1 = {
      node_name   = "k8s-slave-1"
      vm_id       = 101
      role        = "slave"
      description = "Kubernetes worker node 1"
    }

    slave2 = {
      node_name   = "k8s-slave-2"
      vm_id       = 102
      role        = "slave"
      description = "Kubernetes worker node 2"
    }
  }
}
