# Attack Practice: BadBlood Domain and BloodHound

A deliberately misconfigured domain, plus BloodHound CE to map attack paths through it. Everything here is for learning on systems you own.

## Design

| Piece | Where | Notes |
|---|---|---|
| `badblood-dc` (VM 105) | Lab VLAN, `10.10.80.30`, 4 GB RAM | Domain controller in its **own forest**, separate from `lab.example` |
| `bloodhound` (LXC 106) | Lab VLAN, `10.10.80.16`, 3 GB RAM | BloodHound CE running in Docker |

- **Separate forest.** The practice domain shares no trust, DNS or accounts with `lab.example`. Give it its own example name, such as `practice.example`.
- **Throwaway.** Take a snapshot straight after the DC is promoted. Roll back to it instead of repairing the domain.
- **Power it on only while you use it.** It isn't backed up, because it can be rebuilt.
- **DNS.** Machines that use the practice domain must point at `badblood-dc`, and lab machines at DC1. Don't mix them.

## 1. Build the practice domain

1. Create a Windows Server VM on the Lab VLAN (see [Active Directory](04-active-directory.md) for the firmware, disk and NIC settings).
2. Promote it to a new forest with its own name.
3. Take a snapshot called `clean-domain`.

## 2. Seed it with BadBlood

[BadBlood](https://github.com/davidprowe/BadBlood) fills a domain with users, groups, OUs, computers and risky permissions, so there is something to find.

1. Get it onto the DC: download it there (Lab → External is allowed) or copy it in with RDP's shared drive.
2. In an elevated PowerShell as a domain admin:
   ```powershell
   .\Invoke-BadBlood.ps1
   ```
3. Confirm the prompt. Creation takes a while.
4. Take a second snapshot called `seeded`.

## 3. BloodHound CE

The container needs **Nesting** switched on (see [Lab tools](09-lab-tools.md)). Then, following the project's quick start:

```bash
sudo apt install -y docker.io docker-compose-v2
# Download the project's docker-compose.yml, then:
docker compose up -d
docker compose logs | grep -i "initial password"
```

- The web UI is on port **8080** by default: `http://10.10.80.16:8080`.
- Sign in as `admin` with the generated password, then set your own.
- The graph database and Postgres run in the same compose file.

## 4. Collect and import data

1. Run the SharpHound collector on a machine in the practice domain.
2. Copy the resulting `.zip` out and upload it in BloodHound (**Administration → File Ingest**).
3. Explore **Pathfinding** and the built-in queries, such as paths to Domain Admins and Kerberoastable users.

## Reset

Revert `badblood-dc` to the `clean-domain` or `seeded` snapshot, then collect again.
