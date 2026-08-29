#!/usr/bin/env bash
set -euo pipefail

DOCKER="sudo docker"

# Configure Docker-in-Docker for Cloud Agent VMs.
sudo mkdir -p /etc/docker
sudo tee /etc/docker/daemon.json > /dev/null <<'EOF'
{
  "iptables": false,
  "storage-driver": "vfs"
}
EOF

# Ensure the ubuntu user can run Docker commands in interactive shells.
if ! groups ubuntu | grep -q docker; then
  sudo usermod -aG docker ubuntu
fi

grep -q 'docker()' ~/.bashrc || cat >> ~/.bashrc <<'EOF'

# Cloud Agent: docker group membership may not apply to the current shell.
docker() { sudo -g docker docker "$@"; }
EOF

# Start Docker and wait until the daemon is ready.
.cursor/start.sh

# Warm the base image used by the first tutorial project.
$DOCKER pull python:3.8-slim

# Smoke test: build and run the first tutorial app.
$DOCKER build -t docker-tutorial-first-app /workspace/projects/01_first_app
$DOCKER run --rm docker-tutorial-first-app | grep -q "This will run on docker"
