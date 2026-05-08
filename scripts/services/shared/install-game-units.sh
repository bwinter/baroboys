#!/usr/bin/env bash
set -euxo pipefail

# Install and enable game systemd units. Runs as root at Packer build time only.
# Units are baked into the image — not reinstalled at boot.

# shellcheck source=scripts/services/shared/env-vars.sh
# shellcheck disable=SC1091
source "$(dirname "${BASH_SOURCE[0]}")/env-vars.sh"

# env-vars.sh sets BAROBOYS=$HOME/baroboys, which resolves to /root/baroboys when
# this script runs as root. But the game-* units declare User=bwinter_sc81 — and
# /root has mode 700, so bwinter_sc81 can't traverse it. Override BAROBOYS to
# point at bwinter_sc81's copy of the repo (the dual-clone done by refresh_repo)
# before envsubst captures the path into the templates.
TARGET_USER="bwinter_sc81"
export BAROBOYS="/home/$TARGET_USER/baroboys"
export GAME_DIR="$BAROBOYS/$GAME_NAME"
export GAME_NAME LOG_FILE

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
