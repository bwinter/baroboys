#!/bin/bash
set -eux

# Start xvfb
install -m 644 "/root/baroboys/scripts/systemd/xvfb.service" "/etc/systemd/system/"
systemctl daemon-reexec
systemctl daemon-reload
systemctl enable xvfb.service
systemctl start xvfb.service
systemctl status xvfb.service

# Target binary
MCRCON_BIN="/usr/local/bin/mcrcon"

# Only install if missing or outdated
if ! command -v mcrcon >/dev/null || ! "$MCRCON_BIN" -v 2>&1 | grep -qi 'mcrcon'; then
  echo "🔧 Installing mcrcon..."

  # Clean any prior partial install
  rm -rf "/tmp/mcrcon"

  # Clone and build
  git clone "https://github.com/Tiiffi/mcrcon.git" "/tmp/mcrcon"
  cd "/tmp/mcrcon"
  make

  # Install if not already identical
  if ! cmp -s ./mcrcon "$MCRCON_BIN"; then
    /usr/bin/sudo mv ./mcrcon "$MCRCON_BIN"
    /usr/bin/sudo chmod +x "$MCRCON_BIN"
  fi

  echo "✅ mcrcon installed to $MCRCON_BIN"
else
  echo "✅ mcrcon already installed"
fi

# Run all game setup as the unprivileged user
/usr/bin/sudo -u bwinter_sc81 -- "/home/bwinter_sc81/baroboys/scripts/setup/user/install_vrising.sh"

install -m 644 "/root/baroboys/scripts/systemd/vrising.service" "/etc/systemd/system/"

# TODO: Disabled till mcrcon is working.
# install -m 644 "/root/baroboys/scripts/systemd/vrising-idle-check.service" "/etc/systemd/system/"
# install -m 644 "/root/baroboys/scripts/systemd/vrising-idle-check.timer" "/etc/systemd/system/"

systemctl daemon-reexec
systemctl daemon-reload
# systemctl enable vrising-idle-check.timer
# systemctl start vrising-idle-check.timer

# Give Admin Server access to logs.

mkdir -p "/home/bwinter_sc81/baroboys/VRising/logs/"
chown bwinter_sc81:bwinter_sc81  "/home/bwinter_sc81/baroboys/VRising/logs/"
chmod 700  "/home/bwinter_sc81/baroboys/VRising/logs/"

# touch "/home/bwinter_sc81/baroboys/VRising/logs/vrising_idle_check.log"
# printf "\n==== %s ====\n" "$(date +%Y%m%d-%H%M)" >> "/home/bwinter_sc81/baroboys/VRising/logs/vrising_idle_check.log"
# chown bwinter_sc81:bwinter_sc81  "/home/bwinter_sc81/baroboys/VRising/logs/vrising_idle_check.log"
# chmod 644  "/home/bwinter_sc81/baroboys/VRising/logs/vrising_idle_check.log"

touch "/home/bwinter_sc81/baroboys/VRising/logs/vrising.log"
printf "\n==== %s ====\n" "$(date +%Y%m%d-%H%M)" >> "/home/bwinter_sc81/baroboys/VRising/logs/vrising.log"
chown bwinter_sc81:bwinter_sc81  "/home/bwinter_sc81/baroboys/VRising/logs/vrising.log"
chmod 644  "/home/bwinter_sc81/baroboys/VRising/logs/vrising.log"

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

