#!/usr/bin/env bash
# Start the intentionally vulnerable web targets. Run on the Docker VM, which sits on the isolated Lab VLAN.
set -euo pipefail

docker run -d --name juice-shop --restart unless-stopped -p 3000:3000 bkimminich/juice-shop
docker run -d --name dvwa       --restart unless-stopped -p 8081:80   vulnerables/web-dvwa
docker run -d --name webgoat    --restart unless-stopped -p 8080:8080 -p 9090:9090 webgoat/webgoat

docker ps
