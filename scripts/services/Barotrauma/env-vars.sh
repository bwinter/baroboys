#!/usr/bin/env bash
# shellcheck source=scripts/services/shared/env-vars.sh
source "$(dirname "${BASH_SOURCE[0]}")/../shared/env-vars.sh"

# Barotrauma game-specific configuration.

# Steam
export STEAM_APP_ID=1026340 # SETUP: REQUIRED
export STEAM_PLATFORM="linux" # SETUP: OPTIONAL — "linux" for native; "windows" for Wine games
export PROCESS_NAME="DedicatedServer" # SETUP: REQUIRED — process name for pgrep/pkill
export GAME_ENGINE_LOG="$LOG_FILE" # SETUP: REQUIRED — where the game writes real output

export SAVE_NAME="Arkham Aquatics" # SETUP: OPTIONAL — active campaign name
export SAVE_FILE_PREFIX="Arkham Aquatics" # SETUP: OPTIONAL — filename prefix for saves
export SAVE_FILE_PATH="$GAME_DIR/Multiplayer" # SETUP: OPTIONAL — directory containing saves

WORKSHOP_MODS_PATH="$GAME_DIR/WorkshopMods" # SETUP: OPTIONAL

# Saves and mods live in user-land
# Link game clone path to local paths
mkdir -p "$HOME/.local/share/Daedalic Entertainment GmbH/Barotrauma/"
ln -sf "$SAVE_FILE_PATH" "$HOME/.local/share/Daedalic Entertainment GmbH/Barotrauma"
ln -sf "$WORKSHOP_MODS_PATH" "$HOME/.local/share/Daedalic Entertainment GmbH/Barotrauma"

# Checkout
# SETUP: REQUIRED — git checkout uses this; empty value would checkout everything
CLIENT_PERMISSIONS_XML="Data/clientpermissions.xml"
PERMISSION_PRESETS_XML="Data/permissionpresets_player.xml"

CLIENT_PERMISSIONS_XML="$GAME_DIR/$CLIENT_PERMISSIONS_XML"
PERMISSION_PRESETS_XML="$GAME_DIR/$PERMISSION_PRESETS_XML"

export CHECKOUT_LIST="$CLIENT_PERMISSIONS_XML $PERMISSION_PRESETS_XML"

# SETUP: REQUIRED — the command that launches the game server
export LAUNCH_CMD="./DedicatedServer"