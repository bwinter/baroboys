#!/usr/bin/env bash
set -euxo pipefail

# Shared OS-level infrastructure — runs as root on every boot.
# Ensures directories and permissions are correct. No repo dependency —
# these are pure infrastructure, not code-derived config.

# Log directory — owned by bwinter_sc81, all services write here
mkdir -p "/var/log/baroboys/"
chown bwinter_sc81:bwinter_sc81 "/var/log/baroboys/"
chmod 700 "/var/log/baroboys/"

# Application directory — Flask, static assets, status.json
mkdir -p /opt/baroboys
chown -R bwinter_sc81:bwinter_sc81 /opt/baroboys

# Self-heal own unit file
install -m 644 '/root/baroboys/scripts/services/infrastructure/infrastructure-refresh.service' \
  '/etc/systemd/system/'
systemctl daemon-reload
systemctl enable infrastructure-refresh.service
