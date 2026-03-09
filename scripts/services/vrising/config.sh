#!/usr/bin/env bash
# VRising game-specific configuration.
# Source this from any VRising script that needs these values.
# To rename the world: update WORLD_NAME here, rename the on-disk save directory to match,
# then push. The game creates a fresh world if the directory is missing — a mismatched
# rename will silently wipe the save.

GAME_NAME="vrising"
GAME_DIR="$HOME/baroboys/VRising"
STEAM_APP_ID=1829350
STEAM_PLATFORM="windows"
WORLD_NAME="TestWorld-1"
RCON_PORT=25575
SAVE_DIR="$GAME_DIR/Data/Saves/v4/$WORLD_NAME"
LOG_FILE="/var/log/baroboys/${GAME_NAME}.log"
WINEPREFIX="$HOME/.wine64"