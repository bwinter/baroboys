#!/usr/bin/env bash
set -euxo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Idempotently install the save-backup units. The refresh service runs after
# refresh-repo-startup so a boot can self-heal unit changes from Git.
sudo install -m 644 "$SCRIPT_DIR/save-backup.service" \
  /etc/systemd/system/save-backup.service
sudo install -m 644 "$SCRIPT_DIR/save-backup.timer" \
  /etc/systemd/system/save-backup.timer
sudo install -m 644 "$SCRIPT_DIR/save-backup-refresh.service" \
  /etc/systemd/system/save-backup-refresh.service

sudo systemctl daemon-reload
sudo systemctl enable save-backup-refresh.service
sudo systemctl enable save-backup.timer
