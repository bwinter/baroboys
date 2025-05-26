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
systemctl daemon-reexec
systemctl daemon-reload
# Disabling, I want the boot.service to make this happen by running this script.
# systemctl enable vrising.service
if [ "${ACTIVE_GAME:-}" = "vrising" ]; then
  echo "🎮 Starting V Rising server via systemd..."
  systemctl start vrising.service
fi
systemctl status vrising.service
