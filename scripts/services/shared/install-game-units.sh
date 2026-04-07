#!/usr/bin/env bash
set -euxo pipefail

# Install and enable game systemd units. Runs as root at Packer build time only.
# Units are baked into the image — not reinstalled at boot.

source "$(dirname "${BASH_SOURCE[0]}")/env-vars.sh"
export BAROBOYS GAME_NAME GAME_DIR LOG_FILE

TEMPLATE_DIR="$BAROBOYS/scripts/templates"

envsubst < "$TEMPLATE_DIR/game-refresh.service" > /tmp/game-refresh.service
envsubst < "$TEMPLATE_DIR/game-startup.service" > /tmp/game-startup.service
envsubst < "$TEMPLATE_DIR/game-shutdown.service" > /tmp/game-shutdown.service

install -m 644 /tmp/game-refresh.service /etc/systemd/system/
install -m 644 /tmp/game-startup.service /etc/systemd/system/
install -m 644 /tmp/game-shutdown.service /etc/systemd/system/

systemctl daemon-reload
systemctl enable game-refresh.service
systemctl enable game-startup.service
systemctl enable game-shutdown.service
