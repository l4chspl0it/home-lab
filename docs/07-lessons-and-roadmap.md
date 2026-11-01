# Lessons and Roadmap

## Lessons learned

- Check a disk's **partition type** (`dos` or `gpt`) before choosing BIOS or UEFI for an imported Windows VM.
- **Never put large files in `/tmp` on Proxmox.** It lives in RAM.
- **Keep VM disks on the SSD.** A laptop hard disk is only good for ISOs and backups.
- An **isolated bridge with no ports** is the simplest way to keep a VM off every other network.
- **Verify checksums** after every large copy, and keep the original until the copy has proven itself.
- **Test firewall rules from both sides** instead of trusting the rule list.
- The browser console drops keystrokes on long commands. Use SSH, or RDP with a working clipboard.
- A SIEM is only as good as what endpoints log. Audit policy and Sysmon are what make Splunk useful.
- A multi-homed domain controller needs its DNS registration managed.
- Keep a deliberately broken domain in its **own forest** and power it off when it isn't in use.
- Containers (LXC) suit small always-on services. Docker inside one needs Nesting enabled.
- A /27 fills up faster than you expect. Track addresses in NetBox.

## Done

- [x] VLAN-segmented network with a trunk to the hypervisor
- [x] Vulnerable targets (Docker apps, Metasploitable 2)
- [x] Two domain controllers, including an isolated one on `vmbr1`
- [x] Splunk SIEM with Windows and Sysmon logging
- [x] Windows 11 client joined to the domain
- [x] Throwaway BadBlood domain and BloodHound CE
- [x] NetBox and Grafana containers

## Roadmap

- [ ] Verify every firewall rule from both directions and document the results
- [ ] Confirm the Windows client's forwarder and Sysmon are sending to Splunk
- [ ] Write first detections and dashboards in Splunk
- [ ] Record the VLANs, prefixes and VMs in NetBox
- [ ] Build the first Grafana dashboards
- [ ] Add OPNsense as a lab firewall
- [ ] Automate builds with Ansible, Terraform and Python
- [ ] Add a malware analysis segment on its own sealed bridge, with a snapshot before every detonation
- [ ] More Linux hosts and test containers
- [ ] Check whether the host takes more RAM (`dmidecode -t 16`)
- [ ] Test restoring a backup to a new VM ID
