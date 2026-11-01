# Architecture

All addressing below is **example addressing**.

## Networks

| Network | VLAN | Subnet | Purpose |
|---|---|---|---|
| Management | 10 | 10.10.10.0/24 | Hypervisor and admin interfaces |
| Trusted | 20 | 10.10.20.0/24 | Daily devices |
| IoT | 30 | 10.10.30.0/26 | Smart devices |
| Guest | 70 | 10.10.70.0/29 | Visitors |
| Lab | 80 | 10.10.80.0/27 | Targets, DC1, SIEM, Windows client |
| DMZ | 90 | 10.10.90.0/30 | Static addresses only |
| `vmbr1` (Proxmox only) | none | 10.10.100.0/24 | Isolated DC-to-DC network |

## UniFi hardware and cameras

| Device | Role |
|---|---|
| UDR7 | Gateway: inter-VLAN routing, zone firewall, DHCP and DNS |
| UniFi switch | Access ports and the trunk to the Proxmox host |
| UX7 | Wi-Fi and mesh node, connected to the UDR7 by **wired mesh backhaul** |

The switch port that feeds the UX7 is a trunk: **native VLAN Management, tagged VLANs Allow All**, so the UX7 can serve the Trusted, IoT and Guest SSIDs. The wired cameras plug into a LAN port on the UX7. **They are not on their own VLAN.** Carrying a separate VLAN across the mesh link to the UX7 proved too difficult, so the UX7 and the cameras sit on the **Management VLAN**, the same network as the Proxmox host. They are outside the lab, but worth knowing about when you review what can reach the hypervisor.

## Trunk to the hypervisor

The switch port facing the host is a **trunk**:

- **Native (untagged) VLAN:** Management, so the host keeps its management address.
- **Tagged VLANs:** Lab only.
- On the host, `vmbr0` is **VLAN aware**, and each lab VM NIC carries a VLAN tag of 80.

## Firewall policy (zone-based)

| Source → Destination | Action | Why |
|---|---|---|
| Trusted → Lab | Allow | I reach targets from my workstation |
| Lab → Trusted | Block (return traffic only) | A compromised target can't start connections to my devices |
| Lab → Management | Block (tested from `siem`) | Lab hosts must never reach the hypervisor |
| Lab infra → External | Allow | `siem`, DCs, Windows client and tool containers need updates and downloads |
| Lab targets → External | Block | A compromised target can't call out (no reverse shells, beaconing or exfiltration) |
| `vmbr1` → anywhere | None | The bridge has no uplink |

**How the target block is done:** in UniFi's Policy Engine → Objects, a client group named `lab-targets` holds `metasploitable2`, `docker-targets` and `badblood-dc`, with **Secure → Internet → No Internet** switched on. The Trusted → Lab and Lab → Trusted rules are unchanged, so you can still reach the targets from your workstation. Give group members DHCP reservations so they stay matched.

**Test it, don't assume it:**

- From a Lab VM, a ping or SSH to a Trusted device must fail.
- From the Trusted workstation, SSH to a Lab VM must work.
- From a Lab VM, the hypervisor's management address must be unreachable.
- From a `lab-targets` host, `ping 1.1.1.1` must fail. From `siem`, it must work.

## VM inventory

| VM | ID | Network | Address | Notes |
|---|---|---|---|---|
| `pve01` (host) | n/a | Management | 10.10.10.20/24 | Static; web UI on 8006 |
| `docker-targets` | 100 | Lab | 10.10.80.25 | DHCP reservation |
| `metasploitable2` | 101 | Lab | DHCP | IDE disk, E1000 NIC |
| `win-dc` (DC1) | 102 | Lab + `vmbr1` | 10.10.80.2 / 10.10.100.10 | Static; BIOS/MBR, SATA |
| `internal-dc` (DC2) | 103 | `vmbr1` only | 10.10.100.11 | No gateway; DNS = DC1 |
| `siem` | 104 | Lab | 10.10.80.7 | Splunk web on 8000 |
| `win11-client1` | 200 | Lab | 10.10.80.3 | UEFI + TPM 2.0; domain joined |
| `badblood-dc` | 105 | Lab | 10.10.80.30 | Own forest, throwaway; 4 GB |
| `bloodhound` (LXC) | 106 | Lab | 10.10.80.16 | BloodHound CE in Docker; 3 GB |
| `netbox` (LXC) | 107 | Lab | 10.10.80.10 | Ubuntu 24.04 container; 2 GB |
| `grafana` (LXC) | 108 | Lab | 10.10.80.8 | Ubuntu 24.04 container, always on; 1 GB |

Containers (LXC) share the host kernel, so they are lighter than VMs. Docker inside an LXC needs **Nesting** switched on (see [Lab tools](09-lab-tools.md)).

**Addressing note:** the Lab `/27` has 29 host addresses after the gateway, and 9 are in use (the eight Lab hosts above that have fixed addresses, plus Metasploitable). `10.10.80.30` is the last usable address. Plan a larger Lab subnet before adding more hosts.

## Workstation

Kali Linux runs in virt-manager on the workstation (Trusted VLAN) and reaches the Lab through the zone firewall, so it follows the same Trusted → Lab rule as everything else.

## RAM budget

The host has about 15.5 GB usable, and Proxmox itself takes about 1.3 GB. The lab runs in groups:

| Group | VMs | RAM |
|---|---|---|
| Targets | docker-targets 4 GB, metasploitable2 1 GB | about 5 GB |
| AD + SIEM | DC1 3 GB, DC2 1.5 GB, Windows client 3 GB, siem 4 GB | about 11.5 GB |
| Attack practice | badblood-dc 4 GB, bloodhound 3 GB | about 7 GB |
| Tools | netbox 2 GB (on demand), grafana 1 GB (always on) | about 3 GB |

Grafana (1 GB) stays on, so subtract it from every budget above. Don't run the Targets and AD + SIEM groups together, and don't run Attack practice alongside the full AD + SIEM group. Start and stop each group from **Bulk Actions** in the Proxmox UI, and use start order and delays (DC1 first) for the AD group.
