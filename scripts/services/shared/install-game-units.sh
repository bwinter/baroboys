#!/usr/bin/env bash
set -euxo pipefail

# Install and enable game systemd units. Runs as root at Packer build time only.
# Units are baked into the image — not reinstalled at boot.

# shellcheck source=scripts/services/shared/env-vars.sh
source "$(dirname "${BASH_SOURCE[0]}")/env-vars.sh"

: "${BAROBOYS:?BAROBOYS not set — check shared env-vars.sh}"
: "${GAME_DIR:?GAME_DIR not set — check shared env-vars.sh}"
: "${GAME_NAME:?GAME_NAME not set — check shared env-vars.sh}"
: "${LOG_FILE:?LOG_FILE not set — check shared env-vars.sh}"

# env-vars.sh now sets BAROBOYS to the canonical /home/bwinter_sc81/baroboys
# regardless of who runs this script. No need to override.
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
