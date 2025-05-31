#!/bin/bash
set -eux

# Fetch the RCON password from GCP Secret Manager
RCON_PASSWORD="$(gcloud secrets versions access latest --secret=server-password)"

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

jq --arg pass "$RCON_PASSWORD" '.Password = $pass' -i "$HOST_JSON"
jq --arg pass "$RCON_PASSWORD" '.Rcon.Password = $pass' -i "$HOST_JSON"

mkdir -p "/home/bwinter_sc81/baroboys/VRising/logs"
chmod o+rx "/home/bwinter_sc81"
chmod o+rx "/home/bwinter_sc81/baroboys"
chmod o+rx "/home/bwinter_sc81/baroboys/VRising"
chmod o+rx "/home/bwinter_sc81/baroboys/VRising/logs"

touch "/home/bwinter_sc81/baroboys/VRising/logs/VRisingServer.log"
chown bwinter_sc81:bwinter_sc81  "/home/bwinter_sc81/baroboys/VRising/logs/VRisingServer.log"
chmod 644  "/home/bwinter_sc81/baroboys/VRising/logs/VRisingServer.log"

# Ensure EDITOR is set for future shell sessions
grep -qxF 'export EDITOR=vim' "$HOME/.profile" || echo 'export EDITOR=vim' >> "$HOME/.profile"