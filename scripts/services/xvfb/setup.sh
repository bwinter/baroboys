#!/bin/bash
set -eux

# Give Admin Server access to logs.
mkdir -p "/var/log/baroboys/"
chown bwinter_sc81:bwinter_sc81  "/var/log/baroboys/"
chmod 700  "/var/log/baroboys/"

touch "/var/log/baroboys/xvfb_startup.log"
printf "\n==== %s ====\n" "$(date +%Y/%m/%d-%H:%M:%S)" >> "/var/log/baroboys/xvfb_startup.log"
chown bwinter_sc81:bwinter_sc81  "/var/log/baroboys/xvfb_startup.log"
chmod 644  "/var/log/baroboys/xvfb_startup.log"

# Start xvfb-startup
install -m 644 "/root/baroboys/scripts/services/xvfb/xvfb-setup.service" \
  "/etc/systemd/system/"
install -m 644 "/root/baroboys/scripts/services/xvfb/xvfb-startup.service" \
  "/etc/systemd/system/"

# Unit installation
systemctl daemon-reload
systemctl enable xvfb-setup.service
systemctl enable xvfb-startup.service
