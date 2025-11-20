#!/usr/bin/env bash
set -euo pipefail

# Install Docker Engine and Compose Plugin (Ubuntu/Debian)
if ! command -v docker >/dev/null 2>&1; then
  sudo apt-get update
  sudo apt-get install -y ca-certificates curl gnupg lsb-release
  sudo install -m 0755 -d /etc/apt/keyrings
  # shellcheck disable=SC1091,SC2046
  curl -fsSL "https://download.docker.com/linux/$(. /etc/os-release; echo "$ID")/gpg" | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  # shellcheck disable=SC1091
  echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/$(. /etc/os-release; echo "$ID") \"$(lsb_release -cs)\" stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
  sudo apt-get update
  sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  sudo usermod -aG docker "$USER" || true
fi

echo "Docker installed. You may need to log out/in for group changes to apply."



