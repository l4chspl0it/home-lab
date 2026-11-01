# Troubleshooting

| Problem | Cause | Fix |
|---|---|---|
| Installer only lists one disk | BIOS SATA mode set to RAID On | Switch to **AHCI** |
| Root login fails right after install | Password typed blind, or wrong keyboard layout | Reset with `passwd root` from the console |
| Metasploitable drops to `initramfs` | Old kernel can't see a VirtIO/SCSI disk | Attach the disk as **IDE**, NIC **E1000** |
| A VM lands on the wrong network | NIC has no VLAN tag | Set the **VLAN Tag** |
| Can't reach a Lab VM from the workstation | The allow rule was edited into a block | Rebuild Trusted → Lab as **Allow** (with return traffic) |
| Imported Windows disk won't boot | Wrong firmware or bus for the source disk | Match the disk label: `dos` = SeaBIOS, `gpt` = OVMF; attach as **SATA** |
| VM boots to network (iPXE) | The disk isn't in the boot order | **Options → Boot Order:** tick the disk |
| `scp` of a big image fails midway | `/tmp` on Proxmox is a RAM disk | Copy to `/var/lib/vz/import` |
| A VM won't start: bridge does not exist | The NIC points at a bridge not created yet | Create the bridge, then start the VM |
| Lab VMs lose all network | Stray `nic0.<vlan>` and `vmbr0v<vlan>` interfaces | `ip link del` both; keep `vmbr0` VLAN aware; untick NIC Firewall |
| Windows 11 install takes hours | VM disk is on the hard disk | Move it to the SSD (**Disk Action → Move Storage**) |
| Windows 11 console laggy or black | VirtIO-GPU display with no driver | Set **Display: Default** |
| `reg add` says "Invalid key name" | Used `HKLM:\` (PowerShell syntax) in a command prompt | Use `HKLM\SYSTEM\...` |
| Windows 11 setup says the PC can't run it | CPU, TPM or storage check | Use the default CPU type, TPM v2.0, and the `LabConfig` bypass keys |
| `apt install ./splunk.deb` fails | wget saved the package under its full name | Install the real file name, for example `./splunk-*.deb` |
| Stray `~` after pasted commands | Bracketed paste in the SSH terminal | `bind 'set enable-bracketed-paste off'`, or type with Tab |
| Add-on install asks for a login | It needs the splunk.com account | Download the add-ons and use **Install app from file** |
| Forwarder shows nothing in Splunk | Wrong receiver, port, file name or index | Check `outputs.conf`, port 9997 and that `inputs.conf` isn't `.txt` |
| Domain join times out | DNS returns an unreachable internal address | Stop DC1 registering its internal NIC in DNS (see [Active Directory](04-active-directory.md)) |
| RDP window tiny in a black area | Remote desktop at a low fixed resolution | Turn on dynamic resolution, or set the profile resolution |
| Docker won't start inside an LXC | Container features are off | **Container → Options → Features:** tick **Nesting** (and **keyctl** if it still fails), then restart the container |
| Two Lab hosts get the same address | A DHCP lease collides with a static address | Add a DHCP reservation, then `ipconfig /release` and `/renew` on the client |
| BloodHound login fails on first start | Password not noted from the first run | Find the initial password in the container logs, or reset it with a fresh compose volume |
| `docker pull` fails on `docker-targets` | The `lab-targets` group blocks internet access | Temporarily switch off **Secure → No Internet** on the group, pull, then switch it back on |
