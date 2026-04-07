#!/usr/bin/env bash
set -euxo pipefail

SCRIPT_DIR="$(dirname "${BASH_SOURCE[0]}")"

# Ensure log file exists (log directory created by infrastructure-refresh)
touch "/var/log/baroboys/idle_check.log"
printf "\n==== %s ====\n" "$(date +%Y/%m/%d-%H:%M:%S)" >> "/var/log/baroboys/idle_check.log"

sudo install -m 644 "$SCRIPT_DIR/idle-check-refresh.service" "/etc/systemd/system/"
sudo install -m 644 "$SCRIPT_DIR/idle-check.service" "/etc/systemd/system/"
sudo install -m 644 "$SCRIPT_DIR/idle-check.timer" "/etc/systemd/system/"

sudo systemctl daemon-reload
sudo systemctl enable idle-check-refresh.service
sudo systemctl enable idle-check.service
sudo systemctl enable idle-check.timer
