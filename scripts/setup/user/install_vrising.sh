#!/bin/bash
set -eux

/usr/games/steamcmd \
  +@sSteamCmdForcePlatformType windows \
  +force_install_dir "$HOME/baroboys/VRising" \
  +login anonymous \
  +app_update 1829350 validate \
  +quit

# Restore canonical server configs
cd "$HOME/baroboys"
git checkout -- \
  VRising/VRisingServer_Data/StreamingAssets/Settings/ServerGameSettings.json \
  VRising/VRisingServer_Data/StreamingAssets/Settings/ServerHostSettings.json \
  VRising/Data/Settings/adminlist.txt \
  VRising/Data/Settings/banlist.txt

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