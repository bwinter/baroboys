#!/bin/bash
set -eux

mkdir -p "/var/log/baroboys/"
chown bwinter_sc81:bwinter_sc81  "/var/log/baroboys/"
chmod 700  "/var/log/baroboys/"

touch  "/var/log/baroboys/vm-startup.log"
printf "\n==== %s ====\n" "$(date +%Y%m%d-%H%M)" >> "/var/log/baroboys/vm-startup.log"
chown bwinter_sc81:bwinter_sc81  "/var/log/baroboys/vm-startup.log"
chmod 644  "/var/log/baroboys/vm-startup.log"

# Refreshes & Enables & Starts Admin Server (Startup Admin Server immediately.)
cp "/root/baroboys/scripts/systemd/vm-startup.service" "/etc/systemd/system/vm-startup.service"
chmod 644 "/etc/systemd/system/vm-startup.service"

systemctl daemon-reexec
systemctl daemon-reload
systemctl enable vm-startup.service
