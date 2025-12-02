#!/bin/bash
set -eux

mkdir -p "/var/log/baroboys/"
chown bwinter_sc81:bwinter_sc81  "/var/log/baroboys/"
chmod 700  "/var/log/baroboys/"

touch "/var/log/baroboys/vm-shutdown.log"
printf "\n==== %s ====\n" "$(date +%Y%m%d-%H%M)" >> "/var/log/baroboys/vm-shutdown.log"
chown bwinter_sc81:bwinter_sc81  "/var/log/baroboys/vm-shutdown.log"
chmod 644  "/var/log/baroboys/vm-shutdown.log"

cp "/root/baroboys/scripts/systemd/vm-shutdown.service" "/etc/systemd/system/vm-shutdown.service"
chmod 644 "/etc/systemd/system/vm-shutdown.service"

systemctl daemon-reexec
systemctl daemon-reload
