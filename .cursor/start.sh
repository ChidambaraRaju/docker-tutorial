#!/usr/bin/env bash
set -euo pipefail

DOCKER="sudo docker"

sudo mkdir -p /etc/docker
if [[ ! -f /etc/docker/daemon.json ]]; then
  sudo tee /etc/docker/daemon.json > /dev/null <<'EOF'
{
  "iptables": false,
  "storage-driver": "vfs"
}
EOF
fi

if $DOCKER info >/dev/null 2>&1; then
  exit 0
fi

sudo service docker stop >/dev/null 2>&1 || true
sudo pkill -f dockerd >/dev/null 2>&1 || true
sudo rm -f /var/run/docker*.pid

if command -v systemctl >/dev/null 2>&1 && systemctl is-system-running >/dev/null 2>&1; then
  sudo systemctl start docker
else
  sudo dockerd >/tmp/dockerd.log 2>&1 &
fi

for _ in $(seq 1 30); do
  if $DOCKER info >/dev/null 2>&1; then
    exit 0
  fi
  sleep 1
done

echo "Docker daemon failed to start within 30 seconds" >&2
tail -50 /tmp/dockerd.log 2>/dev/null || true
exit 1
