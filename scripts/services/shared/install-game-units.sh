#!/usr/bin/env bash
set -euxo pipefail

# Install and enable game systemd units. Runs as root during image creation and
# from game-unit-refresh.service on every boot.

# shellcheck source=scripts/services/shared/env-vars.sh
source "$(dirname "${BASH_SOURCE[0]}")/env-vars.sh"

: "${BAROBOYS:?BAROBOYS not set — check shared env-vars.sh}"
: "${GAME_DIR:?GAME_DIR not set — check shared env-vars.sh}"
: "${GAME_NAME:?GAME_NAME not set — check shared env-vars.sh}"
: "${LOG_FILE:?LOG_FILE not set — check shared env-vars.sh}"
: "${GAME_STARTUP_LOG_FILE:?GAME_STARTUP_LOG_FILE not set — check shared env-vars.sh}"
: "${GAME_REFRESH_LOG_FILE:?GAME_REFRESH_LOG_FILE not set — check shared env-vars.sh}"
: "${GAME_SHUTDOWN_LOG_FILE:?GAME_SHUTDOWN_LOG_FILE not set — check shared env-vars.sh}"

# env-vars.sh now sets BAROBOYS to the canonical /home/bwinter_sc81/baroboys
# regardless of who runs this script. No need to override.
export BAROBOYS GAME_NAME GAME_DIR LOG_FILE \
  GAME_STARTUP_LOG_FILE GAME_REFRESH_LOG_FILE GAME_SHUTDOWN_LOG_FILE

TEMPLATE_DIR="$BAROBOYS/scripts/templates"

envsubst < "$TEMPLATE_DIR/game-refresh.service" > /tmp/game-refresh.service
envsubst < "$TEMPLATE_DIR/game-startup.service" > /tmp/game-startup.service
envsubst < "$TEMPLATE_DIR/game-shutdown.service" > /tmp/game-shutdown.service

install -m 644 "$BAROBOYS/scripts/services/shared/game-unit-refresh.service" \
  /etc/systemd/system/game-unit-refresh.service
install -m 644 /tmp/game-refresh.service /etc/systemd/system/
install -m 644 /tmp/game-startup.service /etc/systemd/system/
install -m 644 /tmp/game-shutdown.service /etc/systemd/system/

systemctl daemon-reload
systemctl enable game-unit-refresh.service
systemctl enable game-refresh.service
systemctl enable game-startup.service
systemctl enable game-shutdown.service
