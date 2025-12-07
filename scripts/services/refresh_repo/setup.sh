#!/bin/bash
set -eux

# Give Admin Server access to logs.
mkdir -p "/var/log/baroboys/"
chown bwinter_sc81:bwinter_sc81  "/var/log/baroboys/"
chmod 700  "/var/log/baroboys/"

touch  "/var/log/baroboys/refresh_users_startup.log"
printf "\n==== %s ====\n" "$(date +%Y/%m/%d-%H:%M:%S)" >> "/var/log/baroboys/refresh_users_startup.log"
chown bwinter_sc81:bwinter_sc81  "/var/log/baroboys/refresh_users_startup.log"
chmod 644  "/var/log/baroboys/refresh_users_startup.log"

# Unit installation
install -m 644 '/root/baroboys/scripts/services/refresh_repo/refresh-repo-setup.service' \
  '/etc/systemd/system/'
install -m 644 '/root/baroboys/scripts/services/refresh_repo/refresh-repo-startup.service' \
  '/etc/systemd/system/'

systemctl daemon-reload
systemctl enable refresh-repo-setup.service
systemctl enable refresh-repo-startup.service
