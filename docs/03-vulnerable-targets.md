# Vulnerable Targets

Everything here is deliberately insecure. It lives on the Lab VLAN, and the lab firewall prevents it from reaching management or trusted devices. See [Architecture](01-architecture.md).

## Docker targets (VM 100)

An Ubuntu Server VM with Docker. Containers are reached through the VM's address.

```bash
sudo apt install -y docker.io
sudo usermod -aG docker $USER      # log out and back in
```

The three containers are in [`scripts/docker-targets.sh`](../scripts/docker-targets.sh):

| App | Port | Notes |
|---|---|---|
| OWASP Juice Shop | 3000 | Score board at `/#/score-board` |
| DVWA | 8081 | Use the project's published default login, then **Create / Reset Database** |
| OWASP WebGoat | 8080 (WebWolf on 9090) | Register an account; takes about a minute to start |

- `--restart unless-stopped` brings the containers back after a reboot.
- **Pulling images needs internet.** `docker-targets` is in the `lab-targets` group, which has No Internet. Switch that off temporarily to pull or update images, then switch it back on.
- Check them with `docker ps`. A container that was stopped by hand stays stopped after a reboot.
- Docker runs **inside the VM**. It isn't a separate Proxmox container.
- **Port clashes:** if you add other apps to this VM, remap the left-hand port number (`-p 8082:80`).

## Metasploitable 2 (VM 101)

It's distributed as a disk image, so you create an empty VM and import the disk.

1. **Create VM:** no install media, guest type Linux, 1 core, 1 GB RAM, delete the default disk.
2. **Network:** model **Intel E1000** (the old kernel has no VirtIO driver), **VLAN Tag 80**.
3. Download and unzip the image, then import it:
   ```bash
   qm importdisk <vmid> <path>/Metasploitable.vmdk local-lvm
   ```
4. Attach the unused disk as **IDE**. A VirtIO or SCSI bus drops the kernel to an `initramfs` shell.
5. **Options → Boot Order:** tick only that disk.
6. It has no guest agent, so use **Stop** rather than Shutdown.

## Isolation check

Before powering up anything vulnerable, confirm the VM's NIC has the Lab VLAN tag, and that a ping from the VM to the management network fails.
