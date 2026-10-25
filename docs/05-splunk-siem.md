# Splunk SIEM

Splunk Enterprise on its own Ubuntu VM, collecting Windows event logs and Sysmon from the domain controller and the Windows client.

## 1. The VM

| Setting | Value |
|---|---|
| VM | `siem`, ID 104 |
| CPU / RAM | 2 cores, 4 GB |
| Disk | 50 GB on `local-lvm` (the SSD, since Splunk indexes constantly) |
| Network | VirtIO, VLAN Tag 80, Firewall unticked |

Install Ubuntu Server with OpenSSH, then:

```bash
sudo apt update && sudo apt full-upgrade -y
sudo apt install -y qemu-guest-agent
df -h /        # if root is smaller than the disk: sudo lvextend -r -l +100%FREE /dev/ubuntu-vg/ubuntu-lv
```

Give it a DHCP reservation so forwarders always find it.

## 2. Install Splunk Enterprise

1. Sign in at splunk.com and choose **Splunk Enterprise → Linux → `.deb`**. Copy the wget command it gives you.
2. On the VM, download and install the **exact file name** wget saved:
   ```bash
   wget -O splunk.deb '<url from the download page>'
   sudo apt install -y ./splunk.deb
   ```
3. First start (creates the admin account; the **60-day trial begins now**):
   ```bash
   sudo -u splunk /opt/splunk/bin/splunk start --accept-license
   ```
4. Start at boot:
   ```bash
   sudo -u splunk /opt/splunk/bin/splunk stop
   sudo /opt/splunk/bin/splunk enable boot-start -user splunk -systemd-managed 1
   sudo systemctl start Splunkd
   ```
5. The web UI is on port **8000**. After the trial you can move to the Free licence.

## 3. Configure Splunk

- **Receiving:** Settings → Forwarding and receiving → Configure receiving → port **9997**.
- **Indexes:** create `wineventlog` and `sysmon`, each capped (for example 10 GB) so the disk can't fill up.
- **Add-ons:** download the *Splunk Add-on for Microsoft Windows* and the *Splunk Add-on for Sysmon* from Splunkbase, then **Apps → Manage Apps → Install app from file**. The in-app installer needs your splunk.com login, which the server's admin account is not. Restart Splunk afterwards (Settings → Server controls).

## 4. Forwarder on the domain controller

1. Download the **Universal Forwarder (Windows 64-bit `.msi`)** and run it.
   - Receiving indexer: the SIEM's address, port **9997**.
   - **Leave the deployment server blank.**
   - Run as **Local System**, which can read the Security log.
2. Copy [`configs/splunk/inputs.conf`](../configs/splunk/inputs.conf) to `C:\Program Files\SplunkUniversalForwarder\etc\system\local\`. Check that the file isn't saved as `inputs.conf.txt`.
3. Restart the service:
   ```powershell
   Restart-Service SplunkForwarder
   ```
4. Verify in Splunk: `index=* | stats count by host, index`.

To copy files into a Lab VM from a workstation on a different VLAN, use RDP's shared-drive option, because the firewall blocks connections *from* the lab.

## 5. Sysmon and audit policy

Windows doesn't log most useful events by default. Run these on each machine:

- [`scripts/install-sysmon.ps1`](../scripts/install-sysmon.ps1) installs Sysmon with a community configuration.
- [`scripts/enable-audit-policy.ps1`](../scripts/enable-audit-policy.ps1) turns on logon, Kerberos, account-management and process-creation auditing, plus command-line logging.

Check the result with `auditpol /get /category:*`.

## 6. Starter searches

| Goal | Search |
|---|---|
| Which hosts are reporting | `index=* \| stats count by host, index` |
| Process creation (Sysmon) | `index=sysmon EventCode=1 \| table _time host Image CommandLine` |
| Process creation (Security log) | `index=wineventlog EventCode=4688 \| table _time host New_Process_Name Process_Command_Line` |
| Failed logons | `index=wineventlog EventCode=4625 \| stats count by host, Account_Name` |
| Kerberos tickets using RC4 | `index=wineventlog EventCode=4769 Ticket_Encryption_Type=0x17 \| stats count by Account_Name, Service_Name` |

Field names depend on the add-on, so click an event and check what was extracted if a table comes back empty.

## Limits

- The isolated DC (DC2) can't reach the SIEM and sends no logs.
- The Free licence is capped at 500 MB/day, which a lab like this stays far below.
