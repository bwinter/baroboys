#!/usr/bin/env bash
# shellcheck source=scripts/services/shared/env-vars.sh
source "$(dirname "${BASH_SOURCE[0]}")/../shared/env-vars.sh"

# Valheim game-specific configuration.

# Steam
export STEAM_APP_ID=896660 # SETUP: REQUIRED
export STEAM_APP_PLATFORM="linux" # SETUP: OPTIONAL

export SAVE_NAME="SnowCrashWorld" # SETUP: OPTIONAL — save/world identity; feeds config template and path
export SAVE_FILE_PREFIX="SnowCrashWorld" # SETUP: OPTIONAL — filename prefix for save compression
export SAVE_FILE_PATH="$GAME_DIR/worlds_local" # SETUP: OPTIONAL — directory containing saves

GAME_PASSWORD="$(gcloud secrets versions access latest --secret=server-password)"
export GAME_PASSWORD

# WORKSHOP_MODS_PATH="$GAME_DIR/WorkshopMods" # SETUP: OPTIONAL

# Saves and mods live in user-land
# Link game clone path to local paths
# mkdir -p "$HOME/.config/unity3d/IronGate/Valheim/"
# ln -sf "$SAVE_FILE_PATH" "$HOME/.config/unity3d/IronGate/Valheim/"
# ln -sf "$WORKSHOP_MODS_PATH" "$HOME/.config/unity3d/IronGate/Valheim/"

# Checkout
# SETUP: REQUIRED — git checkout uses this; empty value would checkout everything
#ADMIN_LIST="adminlist.txt"
#BAN_LIST="bannedlist.txt"
#PERMISSION_LIST="permittedlist.txt"
#
#ADMIN_LIST="$GAME_DIR/$ADMIN_LIST"
#BAN_LIST="$GAME_DIR/$BAN_LIST"
#PERMISSION_LIST="$GAME_DIR/$PERMISSION_LIST"
#
#export CHECKOUT_LIST="$ADMIN_LIST $BAN_LIST $PERMISSION_LIST"

# SETUP: REQUIRED — the command that launches the game server
export LAUNCH_CMD="./valheim_server.x86_64 -name SnowCrashServer -world $SAVE_NAME -password $GAME_PASSWORD -port 2456"
