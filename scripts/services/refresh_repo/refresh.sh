#!/usr/bin/env bash
set -euxo pipefail

# Ensure log directory and file exist with correct permissions.
mkdir -p "/var/log/baroboys/"
chown bwinter_sc81:bwinter_sc81  "/var/log/baroboys/"
chmod 700  "/var/log/baroboys/"

touch  "/var/log/baroboys/refresh_repo.log"
printf "\n==== %s ====\n" "$(date +%Y/%m/%d-%H:%M:%S)" >> "/var/log/baroboys/refresh_repo.log"
chown bwinter_sc81:bwinter_sc81  "/var/log/baroboys/refresh_repo.log"
chmod 644  "/var/log/baroboys/refresh_repo.log"

# Sudoers — self-heal from repo (canonical source: scripts/services/shared/sudoers-bwinter)
install -m 440 -o root -g root \
  '/root/baroboys/scripts/services/shared/sudoers-bwinter' \
  '/etc/sudoers.d/bwinter'

# Unit installation
install -m 644 '/root/baroboys/scripts/services/refresh_repo/refresh-repo-refresh.service' \
  '/etc/systemd/system/'
install -m 644 '/root/baroboys/scripts/services/refresh_repo/refresh-repo-startup.service' \
  '/etc/systemd/system/'

systemctl daemon-reload
systemctl enable refresh-repo-refresh.service
systemctl enable refresh-repo-startup.service
