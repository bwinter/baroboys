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
  rm -rf /tmp/mcrcon

  # Clone and build
  git clone https://github.com/Tiiffi/mcrcon.git /tmp/mcrcon
  cd /tmp/mcrcon
  make

  # Install if not already identical
  if ! cmp -s ./mcrcon "$MCRCON_BIN"; then
    sudo mv ./mcrcon "$MCRCON_BIN"
    sudo chmod +x "$MCRCON_BIN"
  fi

  echo "✅ mcrcon installed to $MCRCON_BIN"
else
  echo "✅ mcrcon already installed"
fi

# Run all game setup as the unprivileged user
sudo -u bwinter_sc81 -- "/home/bwinter_sc81/baroboys/scripts/setup/user/install_vrising.sh"

# Register and start the systemd service
install -m 644 "/root/baroboys/scripts/systemd/vrising.service" "/etc/systemd/system/"
install -m 644 "/root/baroboys/scripts/systemd/vrising-idle-check.service" "/etc/systemd/system/"
install -m 644 "/root/baroboys/scripts/systemd/vrising-idle-check.timer" "/etc/systemd/system/"

systemctl daemon-reexec
systemctl daemon-reload
systemctl enable vrising-idle-check.timer
systemctl start vrising-idle-check.timer
systemctl start vrising-idle-check.service

mkdir -p "/home/bwinter_sc81/baroboys/VRising/logs/"
chown bwinter_sc81:bwinter_sc81  "/home/bwinter_sc81/baroboys/VRising/logs/"
chmod 700  "/home/bwinter_sc81/baroboys/VRising/logs/"

touch "/home/bwinter_sc81/baroboys/VRising/logs/vrising_idle_check.log"
chown bwinter_sc81:bwinter_sc81  "/home/bwinter_sc81/baroboys/VRising/logs/vrising_idle_check.log"
chmod 644  "/home/bwinter_sc81/baroboys/VRising/logs/vrising_idle_check.log"

if [ "${ACTIVE_GAME:-}" = "vrising" ]; then
  echo "🎮 Starting V Rising server via systemd..."
  systemctl start vrising.service
fi
systemctl status vrising.service
