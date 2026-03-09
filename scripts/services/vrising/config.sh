#!/usr/bin/env bash
# VRising game-specific configuration.
# Source this from any VRising script that needs these values.
# To rename the world: update WORLD_NAME here, rename the on-disk save directory to match,
# then push. The game creates a fresh world if the directory is missing — a mismatched
# rename will silently wipe the save.

GAME_NAME="vrising"
WORLD_NAME="TestWorld-1"
RCON_PORT=25575