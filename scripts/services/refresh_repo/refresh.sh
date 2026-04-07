#!/usr/bin/env bash
set -euxo pipefail

# Ensure log file exists (log directory created by infrastructure-refresh)
touch "/var/log/baroboys/refresh_repo.log"
printf "\n==== %s ====\n" "$(date +%Y/%m/%d-%H:%M:%S)" >> "/var/log/baroboys/refresh_repo.log"

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
