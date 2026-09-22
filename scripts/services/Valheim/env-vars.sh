#!/usr/bin/env bash
# shellcheck source=scripts/services/shared/env-vars.sh
source "$(dirname "${BASH_SOURCE[0]}")/../shared/env-vars.sh"

# Valheim game-specific configuration.

# Steam
export STEAM_APP_ID=896660 # SETUP: REQUIRED
export STEAM_PLATFORM="linux" # SETUP: OPTIONAL

export SAVE_NAME="BaroboysWorld" # SETUP: OPTIONAL — save/world identity; feeds config template and path
export SAVE_FILE_PREFIX="AutoSave_" # SETUP: OPTIONAL — filename prefix for save compression
export SAVE_FILE_PATH="$HOME/.config/unity3d/IronGate/Valheim/worlds_local" # SETUP: OPTIONAL — directory containing saves

# Checkout
# SETUP: REQUIRED — git checkout uses this; empty value would checkout everything
ADMIN_LIST="tbd"
BAN_LIST="tbd"

ADMIN_LIST="$GAME_DIR/$ADMIN_LIST"
BAN_LIST="$GAME_DIR/$BAN_LIST"

export CHECKOUT_LIST="" # "$ADMIN_LIST $BAN_LIST"

# SETUP: REQUIRED — the command that launches the game server
export LAUNCH_CMD="./valheim_server.x86_64 -name SnowCrashServer -world SnowCrashWorld -password \$GAME_PASSWORD -port 2456"
