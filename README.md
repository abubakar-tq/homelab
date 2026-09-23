# Homelab

Infrastructure-as-code homelab: a 3-node k3s cluster running on Proxmox LXC
containers, provisioned with Terraform and configured with Ansible.

Everything here is code-driven — the cluster can be destroyed and rebuilt from
this repository, with no manual steps in a web UI.

## Hardware

| | |
|---|---|
| Machine | Mechrevo R14P (repurposed laptop, lid closed, wired, 24/7) |
| CPU | AMD Ryzen 5 7430U — 6 cores / 12 threads |
| Memory | 8GB DDR4-3200 — the binding constraint on every decision here |
| Storage | 256GB NVMe SSD |
| Hypervisor | Proxmox VE 9 |

## Architecture

```
                    Internet
                        │
              ┌─────────┴─────────┐
              │   Home router     │  192.168.1.1
              └─────────┬─────────┘
                        │  LAN  192.168.1.0/24
        ┌───────────────┴───────────────────────────┐
        │  Proxmox VE host          192.168.1.50    │
        │  (also a Tailscale subnet router,         │
        │   advertising 192.168.1.0/24)             │
        │                                           │
        │   ┌─────────────┐  ┌─────────────┐  ┌─────────────┐
        │   │ k8s-master  │  │ k8s-slave-1 │  │ k8s-slave-2 │
        │   │ .3          │  │ .4          │  │ .8          │
        │   │ k3s server  │  │ k3s agent   │  │ k3s agent   │
        │   │ 2 CPU/1GB   │  │ 1 CPU/768M  │  │ 1 CPU/768M  │
        │   └─────────────┘  └─────────────┘  └─────────────┘
        │        unprivileged LXC containers, nesting enabled
        └───────────────────────────────────────────┘
                        │
            Traefik ingress (k3s built-in)
            binds :80/:443 on all three nodes
```

Remote access is via **Tailscale**. The Proxmox host acts as a subnet router, so
every container is reachable from any device on the tailnet without exposing
anything to the internet or forwarding a port.

## Stack

| Layer | Choice | Notes |
|---|---|---|
| Hypervisor | Proxmox VE 9 | LXC over full VMs, for density on limited RAM |
| Provisioning | Terraform (`bpg/proxmox`) | Containers, sizing, networking, DNS |
| Configuration | Ansible | k3s install, cluster join |
| Orchestration | k3s | Lightweight Kubernetes, 1 server + 2 agents |
| Ingress | Traefik | Ships with k3s; host-based routing |
| Remote access | Tailscale | Mesh VPN + subnet router; no port forwarding |

Planned: GitOps with Flux, CI/CD with Jenkins (Trivy image scanning, ghcr.io),
observability with Prometheus / Alertmanager / Grafana / Loki, public exposure
via Cloudflare Tunnel + Access, and secrets management with SOPS + age.

## Repository layout

```
terraform/        Proxmox LXC provisioning (containers, sizing, network, DNS)
ansible/          k3s installation and cluster join
k3s-manifests/    Workload definitions, one directory per application
```

## How it is built

```bash
# 1. Provision the containers
cd terraform
cp terraform.tfvars.example terraform.tfvars   # add your Proxmox API token
terraform init
terraform plan -out=tfplan
terraform apply tfplan

# 2. Install and join k3s
cd ../ansible
ansible-playbook -i inventory/hosts.ini playbooks/playbook.yml

# 3. Deploy a workload
kubectl apply -f k3s-manifests/uptime-kuma/
```

Terraform generates the cluster's SSH keypair and root password itself
(`tls_private_key` / `random_password`), so a rebuild produces fresh
credentials with nothing hardcoded.

## Design trade-offs

Conscious decisions given a single 8GB machine:

- **No high availability.** One physical node means no control-plane HA and no
  hardware-failure isolation — the three "nodes" are LXC containers sharing a
  kernel. This demonstrates Kubernetes scheduling behaviour, not hardware
  resilience. A second machine with Keepalived/HAProxy would be the next step.
- **LXC over full VMs.** Roughly 400-600MB per node instead of 1GB+, which is
  what makes three nodes fit at all.
- **Unprivileged containers.** Kept unprivileged for isolation, which requires
  the `KubeletInUserNamespace` feature gate since the kubelet cannot reach
  `/dev/kmsg` inside a user namespace.
- **Node-local storage.** `local-path` volumes pin a pod to the node they were
  created on. Shared storage would need NFS or Longhorn.
- **Memory limits, not CPU limits.** Memory is uncompressible and one runaway
  process can take down the host; CPU limits only add throttling.

## Status

Built and running:

- [x] Proxmox host, hardened SSH, Tailscale remote access
- [x] 3-node k3s cluster provisioned by Terraform, configured by Ansible
- [x] Remote `kubectl` access from the workstation
- [x] First workload (Uptime Kuma) with persistent storage and Traefik ingress

Next:

- [ ] GitOps with Flux
- [ ] Observability stack
- [ ] CI/CD with Jenkins, image scanning, and a container registry
- [ ] Public exposure via Cloudflare Tunnel
- [ ] Scheduled backups, with a tested restore
