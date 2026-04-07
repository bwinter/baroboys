#!/usr/bin/env bash
set -euxo pipefail

SCRIPT_DIR="$(dirname "${BASH_SOURCE[0]}")"

# Ensure log directory and file exist with correct permissions.
sudo mkdir -p "/var/log/baroboys/"
sudo chown bwinter_sc81:bwinter_sc81 "/var/log/baroboys/"
sudo chmod 700 "/var/log/baroboys/"

touch "/var/log/baroboys/xvfb.log"
printf "\n==== %s ====\n" "$(date +%Y/%m/%d-%H:%M:%S)" >> "/var/log/baroboys/xvfb.log"

# Unit installation
sudo install -m 644 "$SCRIPT_DIR/xvfb-refresh.service" "/etc/systemd/system/"
sudo install -m 644 "$SCRIPT_DIR/xvfb-startup.service" "/etc/systemd/system/"

sudo systemctl daemon-reload
sudo systemctl enable xvfb-refresh.service
sudo systemctl enable xvfb-startup.service
