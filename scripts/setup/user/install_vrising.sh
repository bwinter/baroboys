#!/bin/bash
set -eux

# Fetch the RCON password from GCP Secret Manager
SERVER_PASSWORD="$(gcloud secrets versions access latest --secret=server-password)"
export SERVER_PASSWORD

# Paths
HOST_JSON="VRising/VRisingServer_Data/StreamingAssets/Settings/ServerHostSettings.json"
GAME_JSON="VRising/VRisingServer_Data/StreamingAssets/Settings/ServerGameSettings.json"

/usr/games/steamcmd \
  +@sSteamCmdForcePlatformType windows \
  +force_install_dir "$HOME/baroboys/VRising" \
  +login anonymous \
  +app_update 1829350 validate \
  +quit

# Restore canonical server configs
cd "$HOME/baroboys"
git checkout -- \
  "$HOST_JSON" \
  "$GAME_JSON" \
  "VRising/Data/Settings/adminlist.txt" \
  "VRising/Data/Settings/banlist.txt"

envsubst < "$HOST_JSON" > "$HOST_JSON.tmp"
mv "$HOST_JSON.tmp" "$HOST_JSON"

# Ensure log paths are readable
mkdir -p "$VRISING_DIR/logs"
chmod o+rx "$HOME" "$HOME/baroboys" "$VRISING_DIR" "$VRISING_DIR/logs"
touch "$VRISING_DIR/logs/VRisingServer.log"
printf "\n==== %s ====\n" "$(date +%Y%m%d-%H%M)" >> "$VRISING_DIR/logs/VRisingServer.log"
chown bwinter_sc81:bwinter_sc81 "$VRISING_DIR/logs/VRisingServer.log"
chmod 644 "$VRISING_DIR/logs/VRisingServer.log"

touch "/home/bwinter_sc81/baroboys/VRising/logs/VRisingServer.log"
printf "\n==== %s ====\n" "$(date +%Y%m%d-%H%M)" >> "/home/bwinter_sc81/baroboys/VRising/logs/VRisingServer.log"
chown bwinter_sc81:bwinter_sc81  "/home/bwinter_sc81/baroboys/VRising/logs/VRisingServer.log"
chmod 644  "/home/bwinter_sc81/baroboys/VRising/logs/VRisingServer.log"

# Ensure EDITOR is set for future shell sessions
grep -qxF 'export EDITOR=vim' "$HOME/.profile" || echo 'export EDITOR=vim' >> "$HOME/.profile"