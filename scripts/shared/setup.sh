#!/usr/bin/env bash
set -euxo pipefail

# shellcheck source=scripts/services/shared/env-vars.sh
source "$(dirname "${BASH_SOURCE[0]}")/env-vars.sh"

# Give Admin Server access to logs.
mkdir -p "$LOG_PATH"
chown bwinter_sc81:bwinter_sc81  "$LOG_PATH"
chmod 700  "$LOG_PATH"

touch "$LOG_FILE"
printf "\n==== %s ====\n" "$(date +%Y/%m/%d-%H:%M:%S)" >> "$LOG_FILE"
chown bwinter_sc81:bwinter_sc81  "$LOG_FILE"
chmod 644  "$LOG_FILE"

# shellcheck source=scripts/services/$GAME_NAME/env-vars.sh
source "$(dirname "${BASH_SOURCE[0]}")/../$GAME_NAME/env-vars.sh"

# Warm SteamCMD before the real install call.
# Without this, SteamCMD intermittently fails to start the installer correctly — likely a
# first-run initialization issue (depot cache, config, or update manifest setup). Running a
# bare login+quit first does a clean pave of whatever internal state SteamCMD needs, and
# the subsequent app_update call reliably succeeds. Root cause is unclear; workaround was
# found via community reports of similar intermittent SteamCMD failures.
# Warm login before the real app_update. This works around intermittent SteamCMD failures
# that occur when the depot cache or config hasn't been initialised yet. Root cause is
# unknown; removing this call makes builds flaky. Do not simplify.
/usr/games/steamcmd \
  +login anonymous \
  +quit

/usr/games/steamcmd \
  +@sSteamCmdForcePlatformType "$STEAM_PLATFORM" \
  +force_install_dir "$GAME_DIR" \
  +login anonymous \
  +app_update "$STEAM_APP_ID" validate \
  +quit

# Restore canonical server configs
cd "$GAME_DIR"
git checkout -- "$CHECKOUT_LIST"

# shellcheck source=scripts/services/$GAME_NAME/config.sh
source "$(dirname "${BASH_SOURCE[0]}")/../$GAME_NAME/config.sh"

SERVICE_SETUP_TEMPLATE="$BAROBOYS/scripts/services/templates/game-setup.service"
SERVICE_STARTUP_TEMPLATE="$BAROBOYS/scripts/services/templates/game-startup.service"
SERVICE_SHUTDOWN_TEMPLATE="$BAROBOYS/scripts/services/templates/game-shutdown.service"

SERVICE_SETUP_TMP="/tmp/game-setup.service"
SERVICE_STARTUP_TMP="/tmp/game-startup.service"
SERVICE_SHUTDOWN_TMP="/tmp/game-shutdown.service"

# Requires $BAROBOYS & $GAME_NAME
envsubst < "$SERVICE_SETUP_TEMPLATE" > "$SERVICE_SETUP_TMP"
envsubst < "$SERVICE_STARTUP_TEMPLATE" > "$SERVICE_STARTUP_TMP"
envsubst < "$SERVICE_SHUTDOWN_TEMPLATE" > "$SERVICE_SHUTDOWN_TMP"

# Install Services
sudo install -m 644 "/tmp/game-setup.service" \
  "/etc/systemd/system/"
sudo install -m 644 "/tmp/game-startup.service" \
  "/etc/systemd/system/"
sudo install -m 644 "/tmp/game-shutdown.service" \
  "/etc/systemd/system/"

# Enable Services
sudo systemctl daemon-reload
sudo systemctl enable game-setup.service
sudo systemctl enable game-startup.service
sudo systemctl enable game-shutdown.service