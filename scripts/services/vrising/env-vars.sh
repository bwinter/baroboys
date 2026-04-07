#!/usr/bin/env bash
# shellcheck source=scripts/services/shared/env-vars.sh
source "$(dirname "${BASH_SOURCE[0]}")/../shared/env-vars.sh"

# VRising game-specific configuration.

# Steam
export STEAM_APP_ID=1829350 # SETUP: REQUIRED
export STEAM_PLATFORM="windows" # SETUP: OPTIONAL

SAVE_FILE_NAME="AutoSave_*" # SETUP: OPTIONAL
export SAVE_FILE_PATH="$GAME_DIR/Data/Saves/v4/$SAVE_FILE_NAME" # SETUP: OPTIONAL

RCON_PASSWORD="$(gcloud secrets versions access latest --secret=rcon-password)" # SETUP: run `make update-rcon-password` to create this secret
export RCON_PASSWORD
export RCON_PORT=25575
export RCON_SHUTDOWN_DELAY_MINUTES=1

# Checkout
# SETUP: OPTIONAL
ADMIN_LIST="Data/Settings/adminlist.txt"
BAN_LIST="Data/Settings/banlist.txt"

ADMIN_LIST="$GAME_DIR/$ADMIN_LIST"
BAN_LIST="$GAME_DIR/$BAN_LIST"

export CHECKOUT_LIST="$ADMIN_LIST $BAN_LIST"

# Wine
export WINEPREFIX="$HOME/.wine64"
