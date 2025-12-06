#!/bin/bash
set -eux

apt update && sudo apt install -y sysstat gzip

source "/root/baroboys/scripts/dependencies/mcrcon/install.sh"

# Run all game setup as the unprivileged user
/usr/bin/sudo -u bwinter_sc81 -- "/home/bwinter_sc81/baroboys/scripts/services/vrising/install.sh"

install -m 644 "/root/baroboys/scripts/systemd/vrising.service" "/etc/systemd/system/"

systemctl daemon-reexec
systemctl daemon-reload

# Give Admin Server access to logs.

mkdir -p "/var/log/baroboys/"
chown bwinter_sc81:bwinter_sc81  "/var/log/baroboys/"
chmod 700  "/var/log/baroboys/"

touch "/var/log/baroboys/vrising.log"
printf "\n==== %s ====\n" "$(date +%Y%m%d-%H%M)" >> "/var/log/baroboys/vrising.log"
chown bwinter_sc81:bwinter_sc81  "/var/log/baroboys/vrising.log"
chmod 644  "/var/log/baroboys/vrising.log"

echo "🎮 Ensuring V Rising server is running via systemd..."

if systemctl is-active --quiet vrising.service; then
  echo "✅ vrising.service is already running, skipping restart."
else
  echo "🔁 vrising.service not active — restarting..."

  echo "🧪 Checking if VRisingServer.exe is still running before restart:"
  pgrep -a -f VRisingServer.exe || echo "🔍 No existing VRisingServer.exe found."

  echo "🔁 Restarting vrising.service..."
  if ! systemctl restart vrising.service; then
    echo "❌ Failed to restart vrising.service" >&2

    echo "📋 Recent journal output:"
    journalctl -xeu vrising.service --no-pager -n 20 || true

    echo "📋 Current service status:"
    systemctl status --no-pager --full vrising.service || true

    exit 1
  fi

  # Confirm it actually became active
  if ! systemctl is-active --quiet vrising.service; then
    echo "❌ vrising.service is not active after restart" >&2
    systemctl status --no-pager --full vrising.service || true
    exit 3
  fi
fi

# Last-ditch check
if systemctl is-failed --quiet vrising.service; then
  echo "❌ vrising.service is in a failed state" >&2
  systemctl status --no-pager --full vrising.service || true
  exit 2
fi

echo "✅ vrising.service is now active."

