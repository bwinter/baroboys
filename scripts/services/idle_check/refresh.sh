#!/usr/bin/env bash
set -euxo pipefail

# Ensure log directory and file exist with correct permissions.
sudo mkdir -p "/var/log/baroboys/"
sudo chown bwinter_sc81:bwinter_sc81 "/var/log/baroboys/"
sudo chmod 700 "/var/log/baroboys/"

touch "/var/log/baroboys/idle_check.log"
printf "\n==== %s ====\n" "$(date +%Y/%m/%d-%H:%M:%S)" >> "/var/log/baroboys/idle_check.log"

sudo install -m 644 "/home/bwinter_sc81/baroboys/scripts/services/idle_check/idle-check-refresh.service" \
  "/etc/systemd/system/"
sudo install -m 644 "/home/bwinter_sc81/baroboys/scripts/services/idle_check/idle-check.service" \
  "/etc/systemd/system/"
sudo install -m 644 "/home/bwinter_sc81/baroboys/scripts/services/idle_check/idle-check.timer" \
  "/etc/systemd/system/"

sudo systemctl daemon-reload
sudo systemctl enable idle-check-refresh.service
sudo systemctl enable idle-check.service
sudo systemctl enable idle-check.timer
