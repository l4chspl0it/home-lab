# Lab Tools: NetBox and Grafana

Two small services that run as **LXC containers** (Ubuntu 24.04) on Proxmox, on the Lab VLAN.

| Container | Address | Purpose | Power |
|---|---|---|---|
| `netbox` (CT 107, 2 GB) | `10.10.80.10` | Inventory of VLANs, prefixes, IPs and devices | On demand |
| `grafana` (CT 108, 1 GB) | `10.10.80.8` | Dashboards | Always on |

## Why containers

An LXC container shares the host kernel, so it uses a fraction of the RAM a VM needs. That matters on a 16 GB host. The trade-off is weaker isolation, which is acceptable for infrastructure tools but not for anything hostile.

## Create a container

1. **Datacenter → local → CT Templates:** download the Ubuntu 24.04 template.
2. **Create CT:** set a hostname, root password or SSH key, the template, disk on `local-lvm`, a small CPU and RAM allocation, and a bridge `vmbr0` with **VLAN Tag 80**.
3. Give it a static address or a DHCP reservation in the Lab range.
4. If it will run Docker: **Options → Features → Nesting** (and **keyctl** if Docker still fails), then restart.

## NetBox

- Run it with the project's `netbox-docker` compose setup.
- Record the VLAN plan, each prefix, the Proxmox host, every VM and container, and which IPs are used. With the Lab `/27` nearly full, this is where you check what's free.
- NetBox is also a good target for later automation with Ansible or Python through its API.

## Grafana

- Install it from Grafana's package repository or run the official container image.
- The web UI is on port **3000** by default.
- Planned data sources: Proxmox host and VM metrics (Proxmox can send them to an external metric server under **Datacenter → Metric Server**), and Splunk data once the first detections exist.
- Keep it on the Lab VLAN, and don't expose it to the internet.

## Backups

Neither container holds anything you can't rebuild, apart from NetBox data. Include `netbox` in the weekly backup job if you rely on it.
