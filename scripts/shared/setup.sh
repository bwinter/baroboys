#!/usr/bin/env bash
set -euxo pipefail

# shellcheck source=scripts/services/shared/env-vars.sh
source "$(dirname "${BASH_SOURCE[0]}")/env-vars.sh"

# Mark setup start in log (dir already created by admin_server/setup.sh as root)
touch "$LOG_FILE"
printf "\n==== %s ====\n" "$(date +%Y/%m/%d-%H:%M:%S)" >> "$LOG_FILE"

# shellcheck source=scripts/services/$GAME_NAME/env-vars.sh
source "$(dirname "${BASH_SOURCE[0]}")/../$GAME_NAME/env-vars.sh"

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
# Intentional word splitting — CHECKOUT_LIST is space-separated paths.
# shellcheck disable=SC2086
git checkout -- $CHECKOUT_LIST

# shellcheck source=scripts/services/$GAME_NAME/config.sh
source "$(dirname "${BASH_SOURCE[0]}")/../$GAME_NAME/config.sh"

# Systemd unit installation is handled separately by install-game-units.sh
# (runs as root at Packer build time only — units are baked into the image).