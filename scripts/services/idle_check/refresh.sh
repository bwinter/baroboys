#!/usr/bin/env bash
set -euxo pipefail

# Ensure log directory and file exist with correct permissions.
mkdir -p "/var/log/baroboys/"
chown bwinter_sc81:bwinter_sc81  "/var/log/baroboys/"
chmod 700  "/var/log/baroboys/"

touch "/var/log/baroboys/idle_check.log"
printf "\n==== %s ====\n" "$(date +%Y/%m/%d-%H:%M:%S)" >> "/var/log/baroboys/idle_check.log"
chown bwinter_sc81:bwinter_sc81  "/var/log/baroboys/idle_check.log"
chmod 644  "/var/log/baroboys/idle_check.log"

install -m 644 "/root/baroboys/scripts/services/idle_check/idle-check-refresh.service" \
  "/etc/systemd/system/"
install -m 644 "/root/baroboys/scripts/services/idle_check/idle-check.service" \
  "/etc/systemd/system/"
install -m 644 "/root/baroboys/scripts/services/idle_check/idle-check.timer" \
  "/etc/systemd/system/"

systemctl daemon-reload
systemctl enable idle-check-refresh.service
systemctl enable idle-check.service
systemctl enable idle-check.timer