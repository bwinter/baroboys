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

# Ensure EDITOR is set for future shell sessions
grep -qxF 'export EDITOR=vim' "$HOME/.profile" || echo 'export EDITOR=vim' >> "$HOME/.profile"