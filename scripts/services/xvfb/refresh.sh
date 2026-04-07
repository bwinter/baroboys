#!/usr/bin/env bash
set -euxo pipefail

SCRIPT_DIR="$(dirname "${BASH_SOURCE[0]}")"

# Ensure log file exists (log directory created by infrastructure-refresh)
touch "/var/log/baroboys/xvfb.log"
printf "\n==== %s ====\n" "$(date +%Y/%m/%d-%H:%M:%S)" >> "/var/log/baroboys/xvfb.log"

# Unit installation
sudo install -m 644 "$SCRIPT_DIR/xvfb-refresh.service" "/etc/systemd/system/"
sudo install -m 644 "$SCRIPT_DIR/xvfb-startup.service" "/etc/systemd/system/"

sudo systemctl daemon-reload
sudo systemctl enable xvfb-refresh.service
sudo systemctl enable xvfb-startup.service
