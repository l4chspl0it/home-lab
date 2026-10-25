# Proxmox Setup

## 1. BIOS: make the SSD visible to the installer

Many laptops ship with SATA mode set to **RAID On** (Intel RST). The Proxmox installer has no driver for it, so only some disks appear in the target-disk list.

- Enter the BIOS, find **SATA Operation**, and change it from **RAID On** to **AHCI**.
- Windows may no longer boot from the old drive after this. That doesn't matter if you're wiping it for Proxmox.

## 2. Install

- In the installer, open the **Target Harddisk** dropdown and choose the **SSD**. Check the size and model, because that's the only way to tell the disks apart.
- Set a static management address, the management gateway and DNS, and a hostname such as `pve01.lab.example`.
- The hostname is hard to change later, so choose it now.
- Plug in Ethernet. WiFi can't be used for management.

## 3. VLAN-aware bridge

- **Node → System → Network → `vmbr0` → Edit → tick VLAN aware → OK → Apply Configuration.**
- Give each lab VM NIC a **VLAN Tag** of 80 and leave **Firewall** unticked.
- If VMs on a tagged VLAN lose connectivity after a network change, check for stray interfaces that Proxmox created when the bridge wasn't VLAN aware:
  ```
  ip link show | grep -E "nic0\.|vmbr0v"
  ip link del nic0.80
  ip link del vmbr0v80
  ```

## 4. Run the laptop headless

By default, closing the lid suspends the host. Create `/etc/systemd/logind.conf.d/lid.conf`:

```ini
[Login]
HandleLidSwitch=ignore
HandleLidSwitchExternalPower=ignore
HandleLidSwitchDocked=ignore
```

Then run `systemctl restart systemd-logind`. Keep the laptop plugged in and ventilated.

## 5. Storage

| Storage | Disk | Use |
|---|---|---|
| `local-lvm` | SSD | **All VM disks** |
| `local` | SSD root | ISOs, templates |
| `hdd` | Hard disk (directory, ext4) | Backups and ISOs only |

- **Keep VM disks off the hard disk.** A laptop SMR drive is far too slow for a Windows install.
- To add the disk: **Disks → select it → Wipe Disk**, then **Disks → Directory → Create**.
- On the `hdd` storage, tick **VZDump backup file** and **ISO image** under Content, and untick **Disk image** so the VM wizard stops offering it.
- **`/tmp` on Proxmox is a RAM disk.** Never copy large files there. Use `/var/lib/vz/import` (on the real disk) instead.

## 6. Backups

- **Datacenter → Backup → Add:** storage `hdd`, mode **Snapshot**, compression **ZSTD**, weekly, keep the last 2.
- Include the infrastructure VMs (DCs and SIEM). Targets are disposable, so skip them.
- A restore **overwrites** the VM. Restore to a new VM ID the first time.
- Backups on the same machine protect against a bad change, not against the laptop failing. Copy them to an external drive occasionally.

## 7. Organisation

- **Resource pools:** `AD-Domain` (DCs, client, SIEM) and `Targets`. Switch the tree to **Pool View** to see them.
- **Start at boot** only for VMs you want after a power cut. Give DC1 an earlier start order than DC2.
