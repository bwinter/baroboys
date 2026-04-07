#!/usr/bin/env bash
set -euxo pipefail

# Ensure log directory and file exist with correct permissions.
sudo mkdir -p "/var/log/baroboys/"
sudo chown bwinter_sc81:bwinter_sc81 "/var/log/baroboys/"
sudo chmod 700 "/var/log/baroboys/"

touch "/var/log/baroboys/xvfb.log"
printf "\n==== %s ====\n" "$(date +%Y/%m/%d-%H:%M:%S)" >> "/var/log/baroboys/xvfb.log"

# Unit installation
sudo install -m 644 "/home/bwinter_sc81/baroboys/scripts/services/xvfb/xvfb-refresh.service" \
  "/etc/systemd/system/"
sudo install -m 644 "/home/bwinter_sc81/baroboys/scripts/services/xvfb/xvfb-startup.service" \
  "/etc/systemd/system/"

sudo systemctl daemon-reload
sudo systemctl enable xvfb-refresh.service
sudo systemctl enable xvfb-startup.service
