# Active Directory

The domain is `lab.example`. DC1 is on the Lab VLAN. DC2 is on an isolated bridge and can only talk to DC1.

## Moving a DC from QEMU/virt-manager into Proxmox

### 1. Inspect the source disk

The disk's partition type decides the Proxmox firmware settings:

```bash
virsh -c qemu:///system domblklist "<dc-vm-name>"
sudo modprobe nbd
sudo qemu-nbd -r -c /dev/nbd0 "<disk path>"
sudo fdisk -l /dev/nbd0
sudo qemu-nbd -d /dev/nbd0
```

| Disklabel type | Firmware in Proxmox |
|---|---|
| `dos` (MBR) | **SeaBIOS**, no EFI disk, no TPM |
| `gpt` with an EFI partition | **OVMF (UEFI)** with an EFI disk |

### 2. Copy and verify

Shut the VM down **from inside Windows**, then:

```bash
sudo cp "<disk path>" ~/dc.qcow2 && sudo chown $USER ~/dc.qcow2
qemu-img check ~/dc.qcow2
sha256sum ~/dc.qcow2
scp ~/dc.qcow2 root@<pve-ip>:/var/lib/vz/import/
ssh root@<pve-ip> sha256sum /var/lib/vz/import/dc.qcow2
```

The two hashes **must match** before you import.

### 3. Create and import

- **Create VM:** no media, machine q35, firmware from the table above, 2 cores, 3 GB RAM, **no disk**.
- **Network:** Intel E1000E, VLAN Tag 80.
- Import and attach:
  ```bash
  qm importdisk <vmid> /var/lib/vz/import/dc.qcow2 local-lvm
  ```
  Attach the unused disk as **SATA 0** and set the boot order to `sata0` only.
- Delete the copy afterwards. Don't boot the original while the Proxmox copy is running.

### 4. Reset the network inside Windows

The NIC hardware changed, so the old static settings are gone. Rename and re-address the adapters:

```powershell
Get-NetAdapter | Select Name, MacAddress, Status
Rename-NetAdapter -Name "Ethernet 2" -NewName "Lab"
New-NetIPAddress -InterfaceAlias "Lab" -IPAddress 10.10.80.2 -PrefixLength 27 -DefaultGateway 10.10.80.1
Set-DnsClientServerAddress -InterfaceAlias "Lab" -ServerAddresses 127.0.0.1
```

Delete ghost adapters in Device Manager (View → Show hidden devices).

## The isolated bridge for DC2

1. **Node → System → Network → Create → Linux Bridge:** name `vmbr1`, **leave every other field blank**, Autostart on, then Apply Configuration. A bridge with no port and no IP can't reach anything.
2. Give **DC1** a second NIC on `vmbr1` and a static address with **no gateway**.
3. DC2's only NIC goes on `vmbr1`, with a static address in the same subnet, **no gateway**, and DNS pointing at DC1.
4. **Test:** from DC2, DC1's internal address must answer. `ping 8.8.8.8` and the Lab gateway must fail.

A bridge that doesn't exist yet stops any VM using it from starting, so create `vmbr1` first.

### Multi-homed DC and DNS

DC1 has two NICs, so it may register both addresses in DNS. Lab clients can then be handed the internal address, which they can't reach. If a domain join fails or `nslookup lab.example` returns an internal address:

1. On DC1, untick **Register this connection's addresses in DNS** on the internal adapter.
2. Delete DC1's internal-address A records in DNS Manager.
3. Run `ipconfig /registerdns` and `Restart-Service netlogon`.

## Windows 11 client

Domain join needs **Windows 11 Pro** (Home can't join).

| Setting | Value |
|---|---|
| Firmware | OVMF (UEFI), EFI disk, **TPM v2.0**, machine q35 |
| CPU type | The default `x86-64-v2-AES`. `host` can trip the Windows 11 CPU check on older processors |
| Disk | SATA, 40 GB on **`local-lvm`** (never the hard disk) |
| Network | Intel E1000E, VLAN Tag 80 |
| Display | **Default** (VirtIO-GPU has no built-in Windows driver) |

Install notes:

- At the first setup screen, press **Shift+F10** and run this, to get past the 64 GB storage check. There is **no colon** after `HKLM` in a command prompt:
  ```
  reg add HKLM\SYSTEM\Setup\LabConfig /v BypassStorageCheck /t REG_DWORD /d 1 /f
  ```
- For a local account, press **Shift+F10** at the network screen and run `OOBE\BYPASSNRO`. On newer builds use `start ms-cxh:localonly`.
- After install, set the DVD to **Do not use any media**.

Join the domain:

```powershell
Set-DnsClientServerAddress -InterfaceAlias "Ethernet" -ServerAddresses 10.10.80.2
nslookup lab.example
```

Then **Win+R → `sysdm.cpl` → Computer Name → Change → Domain**, and sign in as `user@lab.example`.

If you want several clients, build one VM, run `sysprep /generalize /oobe /shutdown`, convert it to a template and make linked clones.
