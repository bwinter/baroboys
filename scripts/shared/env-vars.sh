#!/usr/bin/env bash
export BAROBOYS="$HOME/baroboys"

GAME_NAME="$(cat /etc/baroboys/active-game)"
export GAME_NAME
export GAME_DIR="$BAROBOYS/$GAME_NAME"

GAME_PASSWORD="$(gcloud secrets versions access latest --secret=server-password)"
export GAME_PASSWORD

export LOG_PATH="/var/log/baroboys"
export LOG_FILE="${LOG_PATH}/game.log"
