#!/usr/bin/env bash
set -euo pipefail

# Configure UFW firewall rules for the infra
if ! command -v ufw >/dev/null 2>&1; then
  echo "UFW not installed; installing..."
  sudo apt-get update && sudo apt-get install -y ufw
fi

sudo ufw default deny incoming
sudo ufw default allow outgoing

# SSH
sudo ufw allow 22/tcp

# Load balancer
sudo ufw allow 8080/tcp
sudo ufw allow 8404/tcp

# Web servers direct (optional for debugging)
sudo ufw allow 8081/tcp
sudo ufw allow 8082/tcp

# App server API (optional for debugging)
sudo ufw allow 3000/tcp

# Netdata monitoring
sudo ufw allow 19999/tcp

echo "y" | sudo ufw enable || true
sudo ufw status verbose



